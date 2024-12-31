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
    sourceLocation: SourceLocation = SourceLocation()
) -> Never {
    outputQueue.sync {
        fflush(stdout)
        let file = "\(sourceLocation.file)".bridge().lastPathComponent
        fputs(
            "\(string): file \(sourceLocation.file), line \(sourceLocation.line)\n",
            stderr
        )
    }

    abort()
}

public func queuedFatalError(
    reason: Abort.Reason,
    sourceLocation: SourceLocation = SourceLocation()
) -> Never {
    queuedFatalError(
        reason.debugDescription,
        sourceLocation: sourceLocation
    )
}

public func absurd(
    sourceLocation: SourceLocation = SourceLocation()
) -> Never {
    queuedFatalError(
        reason: .unreachable,
        sourceLocation: sourceLocation
    )
}

public func notImplemented(
    sourceLocation: SourceLocation = SourceLocation()
) -> Never {
    queuedFatalError(
        reason: .notYetImplemented,
        sourceLocation: sourceLocation
    )
}

public func abort(
    reason: Abort.Reason,
    sourceLocation: SourceLocation = SourceLocation()
) -> Never {
    queuedFatalError(
        reason.debugDescription,
        sourceLocation: sourceLocation
    )
}
