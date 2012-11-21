# encoding: UTF-8
Gem::Specification.new do |s|
  s.platform     = Gem::Platform::RUBY
  s.name         = 'spree_yandex_market_scraper'
  s.version      = '0.1'
  s.summary      = 'Get product description and images from Yandex.Market'
  s.required_ruby_version = '>= 1.9.1'

  s.author       = 'Maxim Kulkin'
  s.email        = 'maxim.kulkin@gmail.com'
  s.homepage     = 'https://github.com/maximkulkin/spree_yandex_market_scraper'

  s.files        = `git ls-files`.split("\n")
  s.test_files   = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_path = 'lib'

  s.add_dependency 'spree_core', '> 1.0.0'
end
