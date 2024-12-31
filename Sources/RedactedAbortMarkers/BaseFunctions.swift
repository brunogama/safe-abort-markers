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

public func queuedPrint<T: Sendable>(_ object: T) {
    outputQueue.async {
        print(object)
    }
}

public func queuedPrintError(_ string: String) {
    outputQueue.async {
        fflush(stdout)
        fputs(string + "\n", stderr)
    }
}

public func queuedFatalError(
    _ string: String,
    file: StaticString = #file,
    line: UInt = #line
) -> Never {
    outputQueue.sync {
        fflush(stdout)
        let file = "\(file)".bridge().lastPathComponent
        fputs("\(string): file \(file), line \(line)\n", stderr)
    }

    abort()
}

public func queuedFatalError(
    _ reason: Abort.Reason,
    file: StaticString = #file,
    line: UInt = #line
) -> Never {
    queuedFatalError(
        reason.debugDescription,
        file: file,
        line: line
    )
}

public func absurd(file: StaticString = #file, line: UInt = #line) -> Never {
    queuedFatalError(
        Abort.Reason.invalidLogic,
        file: file,
        line: line
    )
}

public func placeholder(
    file: StaticString = #file,
    line: UInt = #line
) -> Never {
    queuedFatalError(
        Abort.Reason.notYetImplemented,
        file: file,
        line: line
    )
}

public func abort(
    _ why: String,
    file: StaticString = #file,
    line: UInt = #line
) -> Never {
    queuedFatalError(
        why,
        file: file,
        line: line
    )
}

public func abort(
    _ reason: Abort.Reason,
    file: StaticString = #file,
    line: UInt = #line
) -> Never {
    queuedFatalError(
        reason.debugDescription,
        file: file,
        line: line
    )
}
