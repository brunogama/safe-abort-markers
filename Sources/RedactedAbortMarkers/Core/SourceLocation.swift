public struct SourceLocation: Sendable, Hashable, Equatable {

    public let file: String
    public let line: UInt
    public let column: UInt

    public init(
        file: StaticString = #file,
        line: UInt = #line,
        column: UInt = #column
    ) {
        #if DEBUG
            self.file = "\(file)".bridge().lastPathComponent
            self.line = line
            self.column = column
        #else
            self.file = "\(file)"
            self.line = -1
            self.column = -1
        #endif
    }
}
