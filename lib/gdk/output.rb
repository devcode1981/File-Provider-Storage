module GDK
  module Output
    def self.notice(message)
      puts "=> #{message}"
    end

    def self.warn(message)
      puts "(!) WARNING: #{message}"
    end

    def self.error(message)
      puts "(❌) Error: #{message}"
    end

    def self.success(message)
      puts "(✔) #{message}"
    end
  end
end
