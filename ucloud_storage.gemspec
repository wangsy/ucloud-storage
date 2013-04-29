# -*- encoding: utf-8 -*-
require File.expand_path('../lib/ucloud_storage/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Sooyong Wang", "Kunha Park"]
  gem.email         = ["wangsy@wangsy.com", "potato9@gmail.com"]
  gem.description   = %q{ucloud storage API}
  gem.summary       = %q{simple API for authorize, upload files}
  gem.homepage      = "https://github.com/wangsy/ucloud-storage"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "ucloud_storage"
  gem.require_paths = ["lib"]
  gem.version       = UcloudStorage::VERSION

	gem.add_development_dependency "rspec"
	gem.add_development_dependency "vcr"
	gem.add_development_dependency "webmock"

	gem.add_dependency "httparty"

	gem.rubyforge_project = "ucloudstorage"
end