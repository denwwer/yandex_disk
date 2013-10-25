module YandexDisk
  require 'yandex_disk/api'

  VERSION = '1.0.0'
  API_URL = 'https://webdav.yandex.ru'
  # DON'T TURN ON DEBUG FOR PRODUCTION
  DEBUG = false

  class << self
    def version
      YandexDisk::VERSION
    end

    def login(login, pwd)
      Api.new(login, pwd)
    end
  end
end