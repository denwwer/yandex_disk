# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require 'yandex_disk/cfg'

Gem::Specification.new do |s|
  s.name                       = 'yandex_disk'
  s.version                    = YandexDisk::VERSION
  s.summary                    = 'API for Yandex Disk'
  s.description                = 'An easy-to-use client library for Yandex Disk API written in pure ruby.'
  s.author                     = 'Boris Murga'
  s.email                      = 'denwwer.c4@gmail.com'
  s.files                      = Dir.glob("lib/**/*")
  s.test_files                 = Dir.glob('spec/**/*')
  s.require_path               = 'lib'
  s.required_ruby_version      = '>= 1.9.3'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'codeclimate-test-reporter'
  s.add_development_dependency 'fastimage'
  s.post_install_message       = "Thanks for installation, check #{YandexDisk::HOME_PAGE} for news."
  s.homepage                   = YandexDisk::HOME_PAGE
  s.license                    = 'MIT'
end