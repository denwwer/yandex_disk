module YandexDisk
  require 'yandex_disk/api'

  class << self
    def version
      YandexDisk::VERSION
    end

    def login(login, pwd)
      Api.new(login, pwd)
    end
  end
end