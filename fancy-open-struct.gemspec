# -*- encoding: utf-8 -*-

require './lib/fancy-open-struct/version'

Gem::Specification.new do |s|
  s.name = "fancy-open-struct"
  s.version = FancyOpenStruct::VERSION
  s.authors = ["Thomas H. Chapin"]
  s.email = "tchapin@gmail.com"
  s.date = Time.now.utc.strftime("%Y-%m-%d")
  s.homepage = "http://github.com/tomchapin/fancy-open-struct"
  s.licenses = ["MIT"]

  s.summary = "OpenStruct subclass that returns nested hash attributes as FancyOpenStructs"
  s.description = <<-QUOTE.gsub(/^    /, '')
    FancyOpenStruct is a subclass of OpenStruct, and is a variant of RecursiveOpenStruct.
    This allows you to convert nested hashes into a structure where keys and values can be
    navigated and modified via dot-syntax, like: foo.bar = :something. This particular gem
    also adds support for Hash methods (such as length or merge), and also allows you to
    access and modify the data structure the same way that you would handle a normal Hash.

  QUOTE

  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files spec`.split("\n")
  s.require_paths = ["lib"]
  s.extra_rdoc_files = [
      "LICENSE.txt",
      "README.rdoc"
  ]

  s.add_development_dependency "bundler"
  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"
  s.add_development_dependency "rdoc"
  s.add_development_dependency "pry"
  s.add_development_dependency "coveralls"
  s.add_development_dependency "guard"
  s.add_development_dependency "guard-rspec"
  s.add_development_dependency "guard-bundler"
  s.add_development_dependency "simplecov-multi"

end

