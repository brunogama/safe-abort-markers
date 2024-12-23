import Foundation
let foo: String? = "bar"

print(foo!)

public enum Abort: Sendable {
    public struct Reason: Sendable, CustomDebugStringConvertible, ExpressibleByStringLiteral {
        public typealias StringLiteralType = String
        
        public typealias ExtendedGraphemeClusterLiteralType = String
        
        public typealias UnicodeScalarLiteralType = String
        
        public static let deadCode: Reason = "Xcode requires this dead code"
        public static let mustBeOverridden: Reason = "This method must be overriden"
        public static let unreachable: Reason = "Absurd condition: This code should be unreachable"
        public static let notYetImplemented: Reason = "This code has not been"
        public static let invalidLogic: Reason = "Invalid logic resulted in a failed"
        
        public let debugDescription: String
        
        public init(_ why: String) {
            self.debugDescription = why
        }
        
        public init(stringLiteral value: String) {
            self = .init(value)
        }
    }
    
    public static func because(_ reason: Reason, file: StaticString = #file, line: UInt = #line, function: StaticString = #function) -> Never {
        because(reason.debugDescription, file: file, line: line, function: function)
    }
    
    public static func because(_ reason: String, file: StaticString = #file, line: UInt = #line, function: StaticString = #function) -> Never {
        let message = "Failed assertion in \(function) - \(reason)"
        let redactedMessage = SecurePatternManager.shared.redactSensitiveInfo(message)
        queuedFatalError(redactedMessage, file: file, line: line)
    }
    
    public static func `if`(_ condition: @autoclosure () -> Bool, because reason: Reason, file: StaticString = #file, line: UInt = #line, function: StaticString = #function) {
        if condition() == true {
            Abort.because(reason, file: file, line: line, function: function)
        }
    }
}

/// Secure assertions
public struct Assert {
    public static func isMainThread(_ file: StaticString = #file, line: UInt = #line, function: StaticString = #function) {
        guard Thread.isMainThread else {
            Abort.because("This may only be executed on the main thread", file: file, line: line, function: function)
        }
    }
    
    public static func that(_ condition: @autoclosure () -> Bool, because: Abort.Reason, file: StaticString = #file, line: UInt = #line, function: StaticString = #function) {
        guard condition() == true else {
            Abort.because(because, file: file, line: line, function: function)
        }
    }
    
    public static func that(_ condition: @autoclosure () -> Bool, because: String, file: StaticString = #file, line: UInt = #line, function: StaticString = #function) {
        that(condition(), because: Abort.Reason(because), file: file, line: line, function: function)
    }
}
