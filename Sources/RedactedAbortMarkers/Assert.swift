import Foundation

public enum Assert {
    public static func isMainThread(
        sourceLocation: SourceLocation = SourceLocation()
    ) {
        guard Thread.isMainThread else {
            Abort.because(
                "This may only be executed on the main thread",
                sourceLocation: sourceLocation
            )
        }
    }

    public static func that(
        _ condition: @autoclosure () -> Bool,
        because: Abort.Reason,
        sourceLocation: SourceLocation = SourceLocation()

    ) {
        guard condition() == true else {
            Abort.because(
                because,
                sourceLocation: sourceLocation
            )
        }
    }

    public static func that(
        _ condition: @autoclosure () -> Bool,
        because: String,
        sourceLocation: SourceLocation = SourceLocation()
    ) {
        that(
            condition(),
            because: Abort.Reason(because),
            sourceLocation: sourceLocation
        )
    }
}
