# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'trello/list2card/version'

Gem::Specification.new do |spec|
  spec.name          = 'trello-list2card'
  spec.version       = Trello::List2Card::VERSION
  spec.author        = 'tomonocle'
  spec.email         = 'tomonocle@woot.co.uk'
  spec.license       = 'MIT'

  spec.summary       = 'Tool to summarise a Trello list to a card'
  spec.description   = 'A simple program to summarise the cards on a Trello list as a comment on a card, then archive the cards on the source list.'
  spec.homepage      = 'https://github.com/tomonocle/trello-list2card'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'ruby-trello', '~> 2.2'
  spec.add_dependency 'toml-rb', '~> 0.3'
end
