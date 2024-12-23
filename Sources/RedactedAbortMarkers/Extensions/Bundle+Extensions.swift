import Foundation

public extension Bundle {
    func loadSecurePatterns(filenames: [String]) throws {
        for filename in filenames {
            try SecurePatternManager.shared.loadPatterns(fromBundle: self, filename: filename)
        }
    }
}
