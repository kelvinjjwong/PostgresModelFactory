# PostgresModelFactory

A library to access PostgreSQL database by codable models.

Built for  ![Platform](https://img.shields.io/badge/platform-macOS%2011%20+-ff7711.svg)

Built with ![swift](https://img.shields.io/badge/Swift-5-blue) ![xcode](https://img.shields.io/badge/Xcode-14.3-blue) ![SPM](https://img.shields.io/badge/SPM-ff7711)

## Usage and Demo

#### Define a model class for a database table

- [Foo](https://github.com/kelvinjjwong/PostgresModelApp/blob/master/PostgresModelApp/Data/DBO/Foo.swift)

#### Data access layer

1. Abstract CRUD interfact (optional)

- [FooDao](https://github.com/kelvinjjwong/PostgresModelApp/blob/master/PostgresModelApp/Data/DAO/FooDao.swift)
- [FooDaoInterface](https://github.com/kelvinjjwong/PostgresModelApp/blob/master/PostgresModelApp/Data/DAO/FooDaoInterface.swift)

2. CRUD and Version migration

- [FooDaoPostgresCK](https://github.com/kelvinjjwong/PostgresModelApp/blob/master/PostgresModelApp/Data/DAO/FooDaoPostgresCK.swift)

#### Sample usage

- [ViewController](https://github.com/kelvinjjwong/PostgresModelApp/blob/master/PostgresModelApp/ViewController.swift)


## Dependency

- [PostgresClientKit](https://github.com/codewinsdotcom/PostgresClientKit): to manage data in PostgreSQL database ([Apache Licence 2.0](https://github.com/codewinsdotcom/PostgresClientKit/blob/master/LICENSE))
- [LoggerFactory](https://github.com/kelvinjjwong/LoggerFactory) (MIT License)

## License

[The MIT License](LICENSE)
