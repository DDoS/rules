module ruleslang.semantic.codegraph;

import ruleslang.syntax.source;
import ruleslang.semantic.tree;
import ruleslang.util;

private class GraphNode {
    private GraphInnerNode parent;

    @property protected abstract immutable(FlowNode) code();
    protected abstract string asString(size_t indentCount = 0);
}

private class GraphLeafNode : GraphNode {
    private immutable FlowNode statement;
    private bool reached = false;

    private this(immutable FlowNode statement) {
        this.statement = statement;
    }

    @property protected override immutable(FlowNode) code() {
        return statement;
    }

    protected override string asString(size_t indentCount = 0) {
        return statement.toString();
    }
}

private class GraphInnerNode : GraphNode {
    private GraphNode[] children;
    private immutable BlockNode block;

    private this(immutable BlockNode block) {
        this.block = block;
    }

    @property protected override immutable(BlockNode) code() {
        return block;
    }

    protected override string asString(size_t indentCount = 0) {
        string s = "";
        if (auto conditionalBlock = cast(immutable ConditionalBlockNode) block) {
            s ~= "if " ~ conditionalBlock.condition.toString() ~ ":";
        } else {
            s ~= "do:";
        }
        s ~= "\n";
        string indent = "";
        foreach (i; 0 .. indentCount + 1) {
            indent ~= "    ";
        }
        foreach (child; children) {
            s ~= indent ~ child.asString(indentCount + 1) ~ "\n";
        }
        return s;
    }
}

public void checkReturns(immutable BlockNode block) {
    // First create the code graph
    auto root = block.createGraph();
    // Then expand all code paths so we can trace from the root the end of the block
    root.expandCodePaths();

    import std.stdio; writeln('\n', root.asString());

    root.checkPathsReturn();

    root.checkAllReachable();
}

private GraphInnerNode createGraph(immutable BlockNode block) {
    // Create the node for the root block
    auto root = new GraphInnerNode(block);
    foreach (i, statement; block.statements) {
        // For each statement, create the child node
        GraphNode child;
        if (auto nestedBlock = cast(immutable BlockNode) statement) {
            // For nested blocks we use recursion
            child = createGraph(nestedBlock);
        } else {
            // Any other block is just a leaf
            child = new GraphLeafNode(statement);
        }
        // Set the root as the parent of the child
        child.parent = root;
        // Assign the child to the parent
        root.children ~= child;
    }
    return root;
}

private void expandCodePaths(GraphInnerNode root) {
    // First recursively expand the path of each child of the root
    foreach (child; root.children) {
        if (auto innerNodeChild = cast(GraphInnerNode) child) {
            // We only need to expand the inner nodes
            expandCodePaths(innerNodeChild);
        }
    }
    // Next expand the paths from the root node
    foreach (child; root.children) {
        // We can ignore the leaf nodes, since they have no path
        auto innerNodeChild = cast(GraphInnerNode) child;
        if (innerNodeChild is null) {
            continue;
        }
        // Next we need to trace the exit paths, so we keep track of the exiting child and its parent
        auto exitChild = innerNodeChild;
        auto exitParent = exitChild.parent;
        // We are looking for the nodes that are executed after the exit
        // These are found in the exit parent, after the index where the exiting ended
        size_t nextChildIndex;
        bool cyclical = false;
        // This loop traces the exit sequence
        do {
            // Get the block exit offset and target
            auto exitOffset = exitChild.block.exitOffset;
            auto exitTarget = exitChild.block.exitTarget;
            // Ignore paths that cycle back
            if (exitTarget is BlockLimit.START && !exitChild.block.isConditional()) {
                cyclical = true;
                break;
            }
            // First we go up once in the parent chain for every exit we do
            foreach (i; 0 .. exitOffset) {
                // There should always be a parent, except maybe at the last iteration
                // Since we can reach the root block, but not past it
                assert (exitParent !is null);
                exitChild = exitParent;
                exitParent = exitParent.parent;
            }
            // We reached the root block, there is no code path outside of it, so end here
            if (exitParent is null) {
                break;
            }
            // Otherwise we need to find where in the block we exited, so we know what comes next
            auto exitChildrenCount = exitParent.children.length;
            nextChildIndex = size_t.max;
            foreach (i, node; exitParent.children) {
                // Just find the index of the exited block in the parent's children
                if (exitChild is node) {
                    nextChildIndex = i;
                    break;
                }
            }
            // We should always be able to find it
            assert (nextChildIndex != size_t.max);
            // Continue the path into the next child
            nextChildIndex += 1;
            // Check that the exited block isn't the last
            if (nextChildIndex < exitChildrenCount) {
                break;
            }
            // If it is the last, then we exit to the parent block and start over
            exitChild = exitParent;
            exitParent = exitChild.parent;
        } while (exitParent !is null);
        // Check that we aren't outside the root block or adding a cycle
        if (exitParent !is null && !cyclical) {
            // Add the next code code in the path to our node
            innerNodeChild.children ~= exitParent.children[nextChildIndex .. $];
        }
    }
}

private void checkPathsReturn(GraphInnerNode root) {
    // Check all the paths out of the root
    foreach (child; root.children) {
        // If we have a leaf node, check for a return value
        if (auto leaf = cast(GraphLeafNode) child) {
            // Mark the leaf as reachable
            leaf.reached = true;
            // If we find one then this path returns
            if (auto return_ = cast(ReturnValueNode) leaf.statement) {
                return;
            }
        } else {
            // For an inner node, check recursively
            auto inner = child.castOrFail!GraphInnerNode();
            checkPathsReturn(inner);
            // If the node isn't conditional then only the path must return
            if (!inner.block.isConditional()) {
                return;
            }
        }
    }
    throw new SourceException("Missing return statement", root.block.end);
}

private void checkAllReachable(GraphInnerNode root) {
    foreach (child; root.children) {
        if (auto leaf = cast(GraphLeafNode) child) {
            if (!leaf.reached) {
                throw new SourceException("Statement is unreachable", leaf.statement);
            }
        } else {
            // For an inner node, check recursively
            checkAllReachable(child.castOrFail!GraphInnerNode());
        }
    }
}
