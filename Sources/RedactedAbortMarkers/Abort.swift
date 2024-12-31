import Foundation

public enum Abort: Sendable {
    public struct Reason: CustomDebugStringConvertible {
        public let debugDescription: String
        public init(_ why: String) {
            debugDescription = why
        }
    }

    public static func because(
        reason: Reason,
        sourceLocation: SourceLocation = SourceLocation()
    ) -> Never {
        because(
            reason.debugDescription,
            sourceLocation: sourceLocation
        )
    }

    public static func because(
        _ reason: String,
        sourceLocation: SourceLocation = SourceLocation()
    ) -> Never {
        let message =
            "Failed assertion in \(sourceLocation.function) - \(reason)"
        let redactedMessage = SecurePatternManager.shared.redactSensitiveInfo(
            message
        )
        queuedFatalError(
            redactedMessage,
            sourceLocation: sourceLocation
        )
    }

    public static func `if`(
        _ condition: @autoclosure () -> Bool,
        because reason: Reason,
        sourceLocation: SourceLocation = SourceLocation()
    ) {
        if condition() == true {
            Abort.because(
                reason: reason,
                sourceLocation: sourceLocation
            )
        }
    }
}
