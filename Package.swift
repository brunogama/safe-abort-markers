// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.
import Foundation
import PackageDescription
import CompilerPluginSupport

// MARK: - Constants

/// Adjust as needed for your local path structure.
let kLocalPathRelativeToProjectRoot = ".."

/// Your package name.
let kPackageName = "RedactedAbortMarkers"

/// A default version or tag you might associate with this release.
let kVersion = "1.0.0"

/// The platforms (min versions) you want to declare (e.g. iOS 15, macOS 11).
let kPlatforms: [SupportedPlatform] = [
    .iOS(.v15),
    .macOS(.v11)
]

// MARK: - Environment Detection

public struct Environment {
    /// Whether we’re in a Release build (`CONFIGURATION=RELEASE`).
    static var isReleaseBuild: Bool {
        ProcessInfo.processInfo.environment["CONFIGURATION"]?.uppercased() == "RELEASE"
    }
    
    /// Whether SwiftLint plugin usage is enabled (`Z_LINTERSUPPORT_ENABLED=1`).
    static var isLinterEnabled: Bool {
        ProcessInfo.processInfo.environment["Z_LINTERSUPPORT_ENABLED"] == "1"
    }
    
    /// Whether we should remove test targets (`Z_REMOVE_TESTS=1` or `isReleaseBuild`).
    static var shouldRemoveTests: Bool {
        ProcessInfo.processInfo.environment["Z_REMOVE_TESTS"] == "1"
        || isReleaseBuild
    }
}

// MARK: - Base Types

/// **ModuleTarget**: only the targets needed for a macro package.
///
///
public enum ModuleTarget: String, CaseIterable {
    case redactedAbortMarkers
    case redactedAbortMarkersTests
    
    /// Capitalize the first letter of the raw value.
    public var name: String {
        guard let first = rawValue.first else { return rawValue }
        return first.uppercased() + rawValue.dropFirst()
    }

    /// Identify if this is a test target (ends with "Tests"?).
    public var isTest: Bool {
        name.hasSuffix("Tests")
    }
}

/// We only have a single `DependencyModule` for local code in this macro example.
/// If you need more modules (e.g. remote frameworks, domain modules, etc.), add them.
public enum DependencyModule: String {
    case target

    var path: String {
        switch self {
        case .target:
            return kLocalPathRelativeToProjectRoot
        }
    }
}

// MARK: - Dependency Definitions

/// Example Git dependency structure (not used in this minimal macro sample).
public struct GitDependency {
    let url: String
    let version: String
}

/// Example Binary source structure (not used here unless you have a binary that depends on macros).
public enum BinarySource {
    case remote(url: String, checksum: String)
    case local(path: String, checksum: String)
}

/// **DependencyType** now includes `.macro` for macro targets,
/// and minimal others for completeness. But here we'll mostly use `.macro` or `.local`.
public enum DependencyType {
    case local(Set<ModuleTarget>)
    case macro(Set<ModuleTarget>)
    // If needed, you can keep or remove these:
    case git(GitDependency, dependencies: Set<ModuleTarget>)
    case binary(BinarySource, dependencies: Set<ModuleTarget>)
}

// MARK: - TargetSpec

/// A blueprint for each target in your package.
public struct TargetSpec {
    let name: String
    let dependencyType: DependencyType
    let dependencyModule: DependencyModule
    
    /// A default set of housekeeping files/folders to exclude (README, LICENSE, etc.).
    static let defaultExcludes = [
        "README.md", "LICENSE.md", "CHANGELOG.md",
        "CONTRIBUTING.md", ".gitignore", ".github", "danger.js"
    ]
}

// MARK: - TargetSpec Factory Methods

extension TargetSpec {
    /// A local Swift target referencing other local `ModuleTarget`s.
    public static func target(
        _ target: ModuleTarget,
        dependencies: Set<ModuleTarget>,
        dependencyModule: DependencyModule = .target
    ) -> TargetSpec {
        TargetSpec(
            name: target.name,
            dependencyType: .local(dependencies),
            dependencyModule: dependencyModule
        )
    }
    
    /// **Macro target** (Swift 5.9+).
    public static func macro(
        _ target: ModuleTarget,
        dependencies: Set<ModuleTarget> = [],
        dependencyModule: DependencyModule = .target
    ) -> TargetSpec {
        TargetSpec(
            name: target.name,
            dependencyType: .macro(dependencies),
            dependencyModule: dependencyModule
        )
    }
    
    // If you still want them for completeness, keep them:
    public static func git(
        _ name: String,
        url: String,
        version: String,
        dependencies: Set<ModuleTarget>,
        dependencyModule: DependencyModule = .target
    ) -> TargetSpec {
        TargetSpec(
            name: name,
            dependencyType: .git(GitDependency(url: url, version: version), dependencies: dependencies),
            dependencyModule: dependencyModule
        )
    }
    
    public static func binaryRemote(
        _ name: String,
        url: String,
        checksum: String,
        dependencies: Set<ModuleTarget>,
        dependencyModule: DependencyModule = .target
    ) -> TargetSpec {
        TargetSpec(
            name: name,
            dependencyType: .binary(.remote(url: url, checksum: checksum), dependencies: dependencies),
            dependencyModule: dependencyModule
        )
    }
    
    public static func binaryLocal(
        _ name: String,
        path: String,
        checksum: String,
        dependencies: Set<ModuleTarget>,
        dependencyModule: DependencyModule = .target
    ) -> TargetSpec {
        TargetSpec(
            name: name,
            dependencyType: .binary(.local(path: path, checksum: checksum), dependencies: dependencies),
            dependencyModule: dependencyModule
        )
    }
}

// MARK: - PackageBuilder

public struct PackageBuilder {
    private let specs: [TargetSpec]
    private(set) var packageDependencies: [Package.Dependency] = []
    
    public init(_ specs: [TargetSpec]) {
        self.specs = specs
    }
    
    /// Builds a SwiftPM `Package` from our `TargetSpec` list.
    public mutating func build() -> [Target]{
        // If linter is enabled, add SwiftLint plugin package
        if Environment.isLinterEnabled {
            packageDependencies.append(
                .package(
                    url: "https://github.com/realm/SwiftLint.git",
                    from: "0.54.0"
                )
            )
        }
        
        // Filter out test targets if removing tests
        let filteredSpecs = specs.filter { spec in
            // Attempt to parse the spec.name as ModuleTarget
            if let mt = ModuleTarget(rawValue: spec.name.lowercased()) {
                return !Environment.shouldRemoveTests || !mt.isTest
            }
            return true
        }
        
        var allTargets: [Target] = []
        let linterOrNot: [Target.PluginUsage]? = Environment.isLinterEnabled
            ? [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")]
            : nil
        
        for spec in filteredSpecs {
            switch spec.dependencyType {
            
            case .local(let localDeps):
                let localDepTargets = localDeps
                    .filter { !Environment.shouldRemoveTests || !$0.isTest }
                    .map { Target.Dependency.target(name: $0.name) }
                
                let newTarget = Target.target(
                    name: spec.name,
                    dependencies: localDepTargets,
                    path: spec.dependencyModule.path,
                    exclude: TargetSpec.defaultExcludes,
                    plugins: linterOrNot
                )
                allTargets.append(newTarget)

            case .macro(let localDeps):

                
                let macroDeps = localDeps
                    .filter { !Environment.shouldRemoveTests || !$0.isTest }
                    .map { Target.Dependency.target(name: $0.name) }
                
                let macroTarget = Target.macro(
                    name: spec.name,
                    dependencies: macroDeps,
                    path: spec.dependencyModule.path,
                    exclude: TargetSpec.defaultExcludes,
                    plugins: linterOrNot
                )
                allTargets.append(macroTarget)
                
            // If needed, we keep .git / .binary cases, or remove them:
            case .git(let gitDep, let localDeps):
                packageDependencies.append(
                    .package(url: gitDep.url, from: Version(stringLiteral: gitDep.version))
                )
                
                var targetDependencies = localDeps
                    .filter { !Environment.shouldRemoveTests || !$0.isTest }
                    .map { Target.Dependency.target(name: $0.name) }
                
                // For demo, assume product name == spec.name
                targetDependencies.append(.product(name: spec.name, package: spec.name))
                
                let newTarget = Target.target(
                    name: spec.name,
                    dependencies: targetDependencies,
                    path: spec.dependencyModule.path,
                    exclude: TargetSpec.defaultExcludes,
                    plugins: linterOrNot
                )
                allTargets.append(newTarget)
                
            case .binary(let source, let localDeps):
                switch source {
                case .remote(let url, let checksum):
                    let binaryTarget = Target.binaryTarget(
                        name: spec.name,
                        url: url,
                        checksum: checksum
                    )
                    allTargets.append(binaryTarget)
                case .local(let path, let checksum):
                    let binaryTarget = Target.binaryTarget(
                        name: spec.name,
                        path: path
                    )
                    allTargets.append(binaryTarget)
                }
                
                // If the binary has local Swift dependencies, define a “wrapper”
                if !localDeps.isEmpty {
                    var wrapperDependencies = localDeps
                        .filter { !Environment.shouldRemoveTests || !$0.isTest }
                        .map { Target.Dependency.target(name: $0.name) }
                    
                    // Also reference the binary target
                    wrapperDependencies.append(.target(name: spec.name))
                        
                    let wrapperName = "\(spec.name)Wrapper"
                    let wrapperTarget = Target.target(
                        name: wrapperName,
                        dependencies: wrapperDependencies,
                        path: spec.dependencyModule.path,
                        exclude: TargetSpec.defaultExcludes,
                        plugins: linterOrNot
                    )
                    
                    allTargets.append(wrapperTarget)
                    
                }
            }
        }
        return allTargets
    }
}

// MARK: - Example Specs

/// **Example**: A macro target plus an optional test target for verifying the macro.
let specs: [TargetSpec] = [
    .target(.redactedAbortMarkers, dependencies: [.redactedAbortMarkersTests], dependencyModule: .target),
    .target(.redactedAbortMarkersTests, dependencies: [.redactedAbortMarkers], dependencyModule: .target)
]

// MARK: - Build the Package

/// Build the Swift package from these specs, applying environment-based logic

var builder = PackageBuilder(specs)
let allTargets = builder.build()

let package = Package(
    name: "RedactedAbortMarkers",
    platforms: kPlatforms,
    products: [
        .library(
            name: "RedactedAbortMarkers",
            type: .static,
            targets: [.init(stringLiteral: "RedactedAbortMarkers")]
        )
    ],
    targets: [
        .target(name: "RedactedAbortMarkers"),
        .testTarget(
            name: "RedactedAbortMarkersTests",
            dependencies: [.init(stringLiteral: "RedactedAbortMarkers")]
        )
    ]
)
