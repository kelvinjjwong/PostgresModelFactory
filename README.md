# PostgresModelFactory

A library to access PostgreSQL database by codable models.

Built for  ![Platform](https://img.shields.io/badge/platform-macOS%2011%20+-ff7711.svg)

Built with ![swift](https://img.shields.io/badge/Swift-5-blue) ![xcode](https://img.shields.io/badge/Xcode-14.3-blue) ![SPM](https://img.shields.io/badge/SPM-ff7711)

## Usage

#### Define a model class for a database table

- [Foo](https://github.com/kelvinjjwong/PostgresModelApp/blob/master/PostgresModelApp/Data/DBO/Foo.swift)

#### Data access layer

1. Abstract CRUD interfact (optional)

- [FooDao](https://github.com/kelvinjjwong/PostgresModelApp/blob/master/PostgresModelApp/Data/DAO/FooDao.swift)
- [FooDaoInterface](https://github.com/kelvinjjwong/PostgresModelApp/blob/master/PostgresModelApp/Data/DAO/FooDaoInterface.swift)

2. CRUD and Version migration

- [FooDaoPostgresCK](https://github.com/kelvinjjwong/PostgresModelApp/blob/master/PostgresModelApp/Data/DAO/FooDaoPostgresCK.swift)

## Sample

- [FetchTests](https://github.com/kelvinjjwong/PostgresModelFactory/blob/master/Tests/PostgresModelFactoryTests/FetchTests.swift)


## Installation

#### Swift Package Manager

Specify dependency in `Package.swift` by adding this:

```swift
.package(url: "https://github.com/kelvinjjwong/PostgresModelFactory.git", .upToNextMajor(from: "1.0.18"))
```

In `targets` section, add `PostgresModelFactory` to `dependencies` list:

```swift
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "MyApp",
            dependencies: ["PostgresClientKit", "AnotherLibrary"]),
    ],
```

Then run `swift build` to download and integrate the package.

#### CocoaPods

Use [CocoaPods](http://cocoapods.org/) to install `PostgresModelFactory` by adding it to `Podfile`:

```ruby
pod 'PostgresModelFactory', '~> 1.0.18'
```

Then run `pod install` to download and integrate the package.


## Dependency

- [PostgresClientKit](https://github.com/codewinsdotcom/PostgresClientKit): to manage data in PostgreSQL database ([Apache Licence 2.0](https://github.com/codewinsdotcom/PostgresClientKit/blob/master/LICENSE))
- [LoggerFactory](https://github.com/kelvinjjwong/LoggerFactory) (MIT License)

## License

[The MIT License](LICENSE)
