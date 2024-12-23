import Foundation

public enum PatternError: Error {
    case fileNotFound(String)
    case invalidPattern(String)
    case loadError(Error)
}
