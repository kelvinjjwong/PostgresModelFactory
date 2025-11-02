Pod::Spec.new do |s|
  s.name        = "PostgresModelFactory"
  s.version     = "1.0.20"
  s.summary     = "A library to access PostgreSQL database by codable models."
  s.homepage    = "https://github.com/kelvinjjwong/PostgresModelFactory"
  s.license     = { :type => "MIT" }
  s.authors     = { "kelvinjjwong" => "kelvinjjwong@outlook.com" }

  s.requires_arc = true
  s.swift_version = "5.0"
  s.osx.deployment_target = "13.0"
  s.source   = { :git => "https://github.com/kelvinjjwong/PostgresModelFactory.git", :tag => s.version }
  s.source_files = "Sources/PostgresModelFactory/**/*.swift"

  s.dependency 'PostgresClientKit', '~> 1.5.0'
  s.dependency 'LoggerFactory', '~> 1.2.0'
end
