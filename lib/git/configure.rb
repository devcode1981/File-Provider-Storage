module Git
  class Configure
    def initialize(global: false)
      @global = global
    end

    def run!
      recommendations.each do |rec|
        puts rec.description
        puts "Possible input: #{rec.possible_values.join(',')} (default: #{rec.default})"

        input = STDIN.gets.chomp
        input = rec.default if input.empty?

        unless rec.valid_input_value?(input)
          abort("Invalid input: #{input}, possible values: #{rec.possible_values}")
        end

        set_config(rec.key, input)

        puts # New line to seperate each recommendation
      end
    end

    private

    def recommendations
      [
        Recommendation.new(
          'rerere.enabled',
          true,
          'While rebases, remember how previous conflicts were resolved and apply the same resolution'
        ),
        Recommendation.new(
          'help.autocorrect',
          -1,
          'Let git auto correct commands after some deciseconds, e.g. git branhc <something> will be executed as if you typed git branch',
          (-1..)
        ),
        Recommendation.new(
          'fetch.prune',
          true,
          'Prune references in remotes/<remote_name> if these are removed on the server'
        ),
        Recommendation.new(
          'tag.sort',
          '-v:refname',
          'Reverse sort the tags by name, meaning that v1.1 is listed before v1.0',
          %w{-v:refname v:refname}
        )
      ]
    end

    def set_config(key, value)
      if @global
        run_git(%W[config --global key value])
      else
        gdk_repositories.each do |repo|
          run_git(%W[config #{key} #{value}], repo_path: repo)
        end
      end
    end

    def run_git(args, repo_path: nil)
      # Passing an array to IO.popen guards against sh -c.
      # https://gitlab.com/gitlab-org/gitlab/blob/master/doc/development/shell_commands.md#bypass-the-shell-by-splitting-commands-into-separate-tokens
      raise 'command must be an array' unless args.is_a?(Array)

      args = args.unshift('git')
      if repo_path
        system(*args, chdir: repo_path)
      else
        system(*cmd)
      end
    end
  end

  class Recommendation
    attr_reader :key, :default, :possible_values, :description

    def initialize(key, default, desc, possible_values = [true, false])
      @key = key
      @default = default
      @description = desc
      @possible_values = possible_values

      raise 'default value is not valid for the recommendation' unless valid_input_value?(default)
    end

    def valid_input_value?(value)
      possible_values.map(&:to_s).include?(value.to_s)
    end
  end
end
