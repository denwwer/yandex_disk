# encoding: UTF-8
require 'simplecov'
SimpleCov.start
require 'rubygems'
require 'bundler/setup'
require 'yandex_disk'
require 'fileutils'

RSpec.configure do |config|
  config.fail_fast = true
  config.before(:each) do
    init_test_files
  end
end

# login and password for yandex disk
LOGIN = 'boxic2014'
PWD   = 'YanB0r1sM4r'

# test settings
FILES_PATH    = File.dirname(__FILE__) + '/files'
DOWNLOAD_PATH = FILES_PATH + '/downloads'
FILE_TEXT     = 'Hi developer.'

def init_test_files
  FileUtils.mkdir_p(DOWNLOAD_PATH) if !Dir.exist?(DOWNLOAD_PATH)
  @text_file = FILES_PATH + '/sample.txt'
  File.open(@text_file, 'w+'){|f| f.write(FILE_TEXT)} unless File.file? @text_file
  @text_file.freeze
  @image_file = FILES_PATH + '/sample.jpg'
  @image_file.freeze
  raise Exception, "File sample.jpg not found in #{FILES_PATH}" unless File.file? @image_file
end

def clear!
  @yd.delete('/my').should be_true
  FileUtils.rm_rf DOWNLOAD_PATH
end

