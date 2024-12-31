extension Abort.Reason {
    public static var deadCode: Self { .init("Xcode requires this dead code") }
    public static var mustBeOverridden: Self {
        .init("This method must be overriden")
    }
    public static var unreachable: Self {
        .init("Absurd condition: This code should be unreachable")
    }
    public static var notYetImplemented: Self {
        .init("This code has not been")
    }
    public static var invalidLogic: Self {
        .init("Invalid logic resulted in a failed")
    }
}
