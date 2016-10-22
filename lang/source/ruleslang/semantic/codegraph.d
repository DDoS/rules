module ruleslang.semantic.codegraph;

import ruleslang.semantic.tree;

private static class CodeGraphNode {
    private CodeGraphInnerNode parent;

    protected abstract string asString(size_t indentCount = 0);
}

private static class CodeGraphLeafNode : CodeGraphNode {
    private immutable FlowNode statement;

    private this(immutable FlowNode statement) {
        this.statement = statement;
    }

    protected override string asString(size_t indentCount = 0) {
        return statement.toString();
    }
}

private static class CodeGraphInnerNode : CodeGraphNode {
    private CodeGraphNode[] children;
    private CodeGraphNode[] cycleChildren;
    private immutable BlockNode block;

    private this(immutable BlockNode block) {
        this.block = block;
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

public static string checkReturns(immutable BlockNode block) {
    // First create the code graph
    auto root = createCodeGraph(block);
    // Then expand all code paths so we can trace from the root the end of the block
    expandCodePaths(root);
    return root.asString();
}

private static CodeGraphInnerNode createCodeGraph(immutable BlockNode block) {
    // Create the node for the root block
    auto root = new CodeGraphInnerNode(block);
    foreach (i, statement; block.statements) {
        // For each statement, create the child node
        CodeGraphNode child;
        if (auto nestedBlock = cast(immutable BlockNode) statement) {
            // For nested blocks we use recursion
            child = createCodeGraph(nestedBlock);
        } else {
            // Any other block is just a leaf
            child = new CodeGraphLeafNode(statement);
        }
        // Set the root as the parent of the child
        child.parent = root;
        // Assign the child to the parent
        root.children ~= child;
    }
    return root;
}

private static void expandCodePaths(CodeGraphInnerNode root) {
    // First recursively expand the path of each child of the root
    foreach (child; root.children) {
        if (auto innerNodeChild = cast(CodeGraphInnerNode) child) {
            // We only need to expand the inner nodes
            expandCodePaths(innerNodeChild);
        }
    }
    // Next expand the paths from the root node
    foreach (child; root.children) {
        // We can ignore the leaf nodes, since they have no path
        auto innerNodeChild = cast(CodeGraphInnerNode) child;
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
            // First we go up once in the parent chain for every exit we do
            auto exitOffset = exitChild.block.exitOffset;
            auto exitTarget = exitChild.block.exitTarget;
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
            // Next we might need to offset the index based on the exit target
            final switch (exitTarget) with (BlockLimit) {
                case START:
                    // Since we go back to the start the index is the same
                    break;
                case END:
                    // We're breaking and proceeding onto the next statement
                    nextChildIndex += 1;
                    break;
            }
            // Check that the exited block isn't the last
            if (nextChildIndex < exitChildrenCount) {
                // Note that this condition always passes when exit is START
                cyclical = exitTarget is BlockLimit.START;
                break;
            }
            // If it is the last, then we exit to the parent block and start over
            exitChild = exitParent;
            exitParent = exitChild.parent;
        } while (exitParent !is null);
        // Check that we aren't outside the root block
        if (exitParent !is null) {
            // Add the next code code in the path to our node
            auto nextCodePath = exitParent.children[nextChildIndex .. $];
            if (cyclical) {
                innerNodeChild.cycleChildren ~= nextCodePath;
            } else {
                innerNodeChild.children ~= nextCodePath;
            }
        }
    }
}
