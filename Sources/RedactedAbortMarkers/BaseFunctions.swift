import Dispatch
import Foundation

private let outputQueue: DispatchQueue = {
    let queue = DispatchQueue(
        label: "com.secure.abort.outputQueue",
        qos: .userInteractive,
        target: .global(qos: .userInteractive)
    )
    
    defer { setupAtExitHandler() }
    return queue
}()

private func setupAtExitHandler() {
    atexit {
        outputQueue.sync(flags: .barrier) {}
    }
}

/**
 A thread-safe version of Swift's standard `print()`.

 - parameter object: Object to print.
 */
public func queuedPrint<T: Sendable>(_ object: T) {
    outputQueue.async {
        print(object)
    }
}

/**
 A thread-safe, newline-terminated version of `fputs(..., stderr)`.

 - parameter string: String to print.
 */
public func queuedPrintError(_ string: String) {
    outputQueue.async {
        fflush(stdout)
        fputs(string + "\n", stderr)
    }
}

/**
 A thread-safe, newline-terminated version of `fatalError(...)` that doesn't leak
 the source path from the compiled binary.
 */
public func queuedFatalError(_ string: String, file: StaticString = #file, line: UInt = #line) -> Never {
    outputQueue.sync {
        fflush(stdout)
        let file = "\(file)".bridge().lastPathComponent
        fputs("\(string): file \(file), line \(line)\n", stderr)
    }

    abort()
}

public func queuedFatalError(_ reason: Abort.Reason, file: StaticString = #file, line: UInt = #line) -> Never {
    queuedFatalError(reason.debugDescription, file: file, line: line)
}

public func absurd<T>(file: StaticString = #file, line: UInt = #line) -> T {
    queuedFatalError(Abort.Reason.invalidLogic, file: file, line: line)
}

public func placeholder<T>(file: StaticString = #file, line: UInt = #line) -> T {
    queuedFatalError(Abort.Reason.notYetImplemented, file: file, line: line)
}

public func abort<T>(_ why: String, file: StaticString = #file, line: UInt = #line) -> T {
    queuedFatalError(why, file: file, line: line)
}

public func abort<T>(_ reason: Abort.Reason, file: StaticString = #file, line: UInt = #line) -> T {
    queuedFatalError(reason.debugDescription, file: file, line: line)
}
