# gist from sasimpson
module YandexDisk
  class Chunked
    def initialize(data, chunk_size)
      @size = chunk_size
      if data.respond_to? :read
        @file = data
      end
    end

    def read(a, b = nil)
      if @file
        if b
          @file.read(@size, b)
        else
          @file.read(@size)
        end
      end
    end

    def eof!
      @file.eof!
    end

    def eof?
      @file.eof?
    end
  end
end
