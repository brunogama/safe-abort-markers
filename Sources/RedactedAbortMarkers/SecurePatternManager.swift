import Foundation

public final class SecurePatternManager: @unchecked Sendable {
    public static let shared = SecurePatternManager()
    
    private(set) var loadedCategories: [PatternCategory] = []
    private(set) var compiledPatterns: [(NSRegularExpression, String)] = []
    
    private init() {}
    
    /// Load patterns from a JSON file in the bundle
    public func loadPatterns(fromBundle bundle: Bundle = .main, filename: String) throws {
        guard let url = bundle.url(forResource: filename, withExtension: "json") else {
            throw PatternError.fileNotFound(filename)
        }
        
        let data = try Data(contentsOf: url)
        let categories = try JSONDecoder().decode([PatternCategory].self, from: data)
        Task {
            await addLoadedCategories(add: categories)
            compilePatterns()
        }
        
        
    }
    public func addLoadedCategories(add category: [PatternCategory]) async {
        self.loadedCategories.append(contentsOf: category)
    }
    
    /// Compile all patterns into regex for performance
    private func compilePatterns() {
        compiledPatterns = loadedCategories
            .flatMap { $0.patterns }
            .sorted { $0.priority > $1.priority }
            .compactMap { pattern in
                guard let regex = try? NSRegularExpression(
                    pattern: pattern.pattern,
                    options: [.caseInsensitive]
                ) else { return nil }
                return (regex, pattern.replacement)
            }
    }
    
    /// Redact sensitive information from text
    public func redactSensitiveInfo(_ text: String) -> String {
        var result = text
        let range = NSRange(location: 0, length: text.utf16.count)
        
        // Apply patterns in priority order
        for (regex, replacement) in compiledPatterns {
            result = regex.stringByReplacingMatches(
                in: result,
                options: [],
                range: range,
                withTemplate: replacement
            )
        }
        
        return result
    }
    
    /// Get all loaded categories for inspection
    public var categories: [PatternCategory] {
        loadedCategories
    }
}
