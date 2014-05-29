# -*- encoding: utf-8 -*-

require './lib/fancy-open-struct/version'

Gem::Specification.new do |spec|

  spec.name = "fancy-open-struct"
  spec.version = FancyOpenStruct::VERSION
  spec.authors = ["Thomas H. Chapin"]
  spec.email = "tchapin@gmail.com"
  spec.date = Time.now.utc.strftime("%Y-%m-%d")
  spec.homepage = "http://github.com/tomchapin/fancy-open-struct"
  spec.licenses = ["MIT"]

  spec.summary = "OpenStruct subclass that returns nested hash attributes as FancyOpenStructs"
  spec.description = <<-QUOTE.gsub(/^    /, '')
    FancyOpenStruct is a subclass of OpenStruct, and is a variant of RecursiveOpenStruct.
    This allows you to convert nested hashes into a structure where keys and values can be
    navigated and modified via dot-syntax, like: foo.bar = :something. This particular gem
    also adds support for Hash methods (such as length or merge), and also allows you to
    access and modify the data structure the same way that you would handle a normal Hash.

  QUOTE

  spec.files = `git ls-files`.split("\n")
  spec.test_files = `git ls-files spec`.split("\n")
  spec.require_paths = ["lib"]
  spec.extra_rdoc_files = [
      "LICENSE.txt",
      "CHANGELOG",
      "README.rdoc"
  ]

  spec.required_ruby_version = '>= 1.9.3'

  spec.add_dependency "awesome_print"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rdoc"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "coveralls"
  spec.add_development_dependency "guard"
  spec.add_development_dependency "guard-rspec"
  spec.add_development_dependency "guard-bundler"
  spec.add_development_dependency "simplecov-multi"

end

