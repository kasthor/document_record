$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "document_record/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "document_record"
  s.version     = DocumentRecord::VERSION
  s.authors     = ["Kasthor Corleone"]
  s.email       = ["kasthor@kasthor.com"]
  s.homepage    = ""
  s.summary     = "Uses an Active Record as a schema-less document"
  s.description = "Uses an Active Record as a schema-less document"

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency "document_hash", "~> 0.0.12"
  s.add_dependency "rails", "~> 3.2.11"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "debugger"
end
