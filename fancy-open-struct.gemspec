# -*- encoding: utf-8 -*-

require './lib/fancy_open_struct'

Gem::Specification.new do |s|
  s.name = "fancy-open-struct"
  s.version = FancyOpenStruct::VERSION
  s.authors = ["Thomas H. Chapin"]
  s.email = "tchapin@gmail.com"
  s.date = Time.now.utc.strftime("%Y-%m-%d")
  s.homepage = "http://github.com/tomchapin/fancy-open-struct"
  s.licenses = ["MIT"]

  s.summary = "OpenStruct subclass that returns nested hash attributes as FancyOpenStructs"
  s.description = <<-QUOTE .gsub(/^    /,'')
    FancyOpenStruct is a subclass of OpenStruct, and is a variant of RecursiveOpenStruct.
    It differs from OpenStruct in that it allows nested hashes to be treated in a recursive
    fashion, and it also provides Hash methods for getting and setting values.

    For example:

        fos = FancyOpenStruct.new({ :a => { :b => 'c' } })
        fos.a.b # 'c'

        fos.foo = 'bar'
        fos[:foo] # 'bar'

        fos.length # 2

    Also, nested hashes can still be accessed as hashes:

        fos.a_as_a_hash # { :b => 'c' }

    QUOTE

  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files spec`.split("\n")
  s.require_paths = ["lib"]
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.rdoc"
  ]

  s.add_development_dependency(%q<rspec>, [">= 0"])
  s.add_development_dependency(%q<bundler>, [">= 0"])
  s.add_development_dependency(%q<rdoc>, [">= 0"])
end

