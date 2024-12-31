import Foundation

public enum Abort: Sendable {
    public struct Reason: CustomDebugStringConvertible {
        public let debugDescription: String
        public init(_ why: String) {
            debugDescription = why
        }
    }

    public static func because(
        _ reason: Reason,
        file: StaticString = #file,
        line: UInt = #line,
        function: StaticString = #function
    ) -> Never {
        because(
            reason.debugDescription,
            file: file,
            line: line,
            function: function
        )
    }

    public static func because(
        _ reason: String,
        file: StaticString = #file,
        line: UInt = #line,
        function: StaticString = #function
    ) -> Never {
        let message = "Failed assertion in \(function) - \(reason)"
        let redactedMessage = SecurePatternManager.shared.redactSensitiveInfo(
            message
        )
        queuedFatalError(
            redactedMessage,
            file: file,
            line: line
        )
    }

    public static func `if`(
        _ condition: @autoclosure () -> Bool,
        because reason: Reason,
        file: StaticString = #file,
        line: UInt = #line,
        function: StaticString = #function
    ) {
        if condition() == true {
            Abort
                .because(
                    reason,
                    file: file,
                    line: line,
                    function: function
                )
        }
    }
}

public enum Assert {
    public static func isMainThread(
        _ file: StaticString = #file,
        line: UInt = #line,
        function: StaticString = #function
    ) {
        guard Thread.isMainThread else {
            Abort
                .because(
                    "This may only be executed on the main thread",
                    file: file,
                    line: line,
                    function: function
                )
        }
    }

    public static func that(
        _ condition: @autoclosure () -> Bool,
        because: Abort.Reason,
        file: StaticString = #file,
        line: UInt = #line,
        function: StaticString = #function
    ) {
        guard condition() == true else {
            Abort
                .because(
                    because,
                    file: file,
                    line: line,
                    function: function
                )
        }
    }

    public static func that(
        _ condition: @autoclosure () -> Bool,
        because: String,
        file: StaticString = #file,
        line: UInt = #line,
        function: StaticString = #function
    ) {
        that(
            condition(),
            because:
                Abort
                .Reason(
                    because
                ),
            file: file,
            line: line,
            function: function
        )
    }
}
