homepage = 'http://github.com'
Gem::Specification.new do |s|
  s.name                       = 'yandex_disk'
  s.version                    = '1.0.0'
  s.summary                    = 'API for Yandex Disk'
  s.description                = 'An easy-to-use client library for Yandex Disk API'
  s.author                     = 'Boris Murga'
  s.email                      = 'denwwer.c4@gmail.com'
  s.files                      = Dir.glob("lib/**/*")
  s.test_files                 = Dir.glob('spec/**/*')
  s.require_path               = '.'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'fastimage'
  s.post_install_message       = "Thanks for installation, check #{homepage} for news."
  s.homepage                   = homepage
  s.license                    = 'MIT'
end