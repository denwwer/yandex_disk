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
end