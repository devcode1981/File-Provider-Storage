module GDK
  module Output
    COLORS = {
      red: '31',
      green: '32',
      yellow: '33',
      blue: '34',
      magenta: '35',
      cyan: '36',
      bright_red: '31;1',
      bright_green: '32;1',
      bright_yellow: '33;1',
      bright_blue: '34;1',
      bright_magenta: '35;1',
      bright_cyan: '36;1'
    }.freeze

    def self.color(index)
      COLORS.values[index % COLORS.size]
    end

    def self.ansi(code)
      "\e[#{code}m"
    end

    def self.reset_color
      ansi(0)
    end

    def self.puts(message = nil)
      $stdout.puts message
    end

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
