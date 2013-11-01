module YandexDisk
  class ::String
    def blank?
      self.nil? || !self || self.strip.empty?
    end
  end

  class ::Object
    def blank?
      self.nil? || !self || self.empty?
    end
  end

  class ::Integer
    def to_readable(convert)
      return self unless convert

      conv = {'Byte' => 1024,
              'KB'   => 1024**2,
              'MB'   => 1024**3,
              'GB'   => 1024**4}

      conv.each do |suf, size|
        next if self >= size
        return "%.2f %s" % [ self / (size / 1024).to_f, suf ]
      end
    end
  end

end