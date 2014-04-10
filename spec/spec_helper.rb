# encoding: UTF-8
require 'codeclimate-test-reporter'
require 'simplecov'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
    SimpleCov::Formatter::HTMLFormatter,
    CodeClimate::TestReporter::Formatter
]
SimpleCov.start
require 'rubygems'
require 'yandex_disk'
require 'fileutils'

RSpec.configure do |config|
  config.fail_fast = true

  config.before(:each) do
    init_test_files
  end

  config.after(:each) do
    clear!
  end
end

# login and password for yandex disk
LOGIN = ''
PWD   = ''

# test settings
FILES_PATH    = File.dirname(__FILE__) + '/files'
DOWNLOAD_PATH = FILES_PATH + '/downloads'
FILE_TEXT     = 'Hi developer.'

def init_test_files
  FileUtils.mkdir_p(DOWNLOAD_PATH) if !Dir.exist?(DOWNLOAD_PATH)
  FileUtils.mkdir_p(FILES_PATH) if !Dir.exist?(FILES_PATH)

  @text_file = FILES_PATH + '/sample.txt'
  File.open(@text_file, 'w+'){|f| f.write(FILE_TEXT)} unless File.file? @text_file
  @text_file.freeze

  @image_file = FILES_PATH + '/sample.jpg'
  @image_file.freeze

  raise Exception, "Please add any image file named 'sample.jpg' to #{FILES_PATH}" unless File.file? @image_file
end

# Delete test files and delete test path 'my' on Yandex disc
def clear!
  @yd.delete('/my').should be_true if @yd
  FileUtils.rm_rf DOWNLOAD_PATH
end

