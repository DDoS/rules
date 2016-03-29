module ruleslang.semantic.context;

public class Context {
    private Context parent;
    private ForeignNameSpace foreignNames;
    private ImportedNameSpace importedNames;
    private ScopeNameSpace scopeNames;
    private IntrisicNameSpace intrisicNames;
}

public interface NameSpace {

}

public class ForeignNameSpace : NameSpace {

}

public class ImportedNameSpace : NameSpace {

}

public class ScopeNameSpace : NameSpace {

}

public class IntrisicNameSpace : NameSpace {

}
