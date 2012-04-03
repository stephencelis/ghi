module GHI
  module Authorization
    extend Formatting

    class Required < RuntimeError
    end

    class << self
      def token
        return @token if defined? @token
        @token = config 'ghi.token'
      end

      def authorize! user = username, pass = password, local = true
        return false unless user && pass

        res = throb {
          Client.new(user, pass).post(
            '/authorizations',
            :scopes   => %w(public_repo repo),
            :note     => 'ghi',
            :note_url => 'https://github.com/stephencelis/ghi'
          )
        }
        @token = res['token']
        
        run = []
        unless username
          run << "git config#{' --global ' unless local} github.user #{user}"
        end
        run << "git config#{' --global ' unless local} ghi.token #{token}"

        system run.join('; ')

        unless local
          at_exit do
            warn <<EOF
Your ~/.gitconfig has been modified by way of:

  #{run.join "\n  "}

#{bright { blink { 'Do not check this change into public source control!' } }}
Alternatively, set the following env var in a private dotfile:

  export GHI_TOKEN="#{token}"
EOF
          end
        end
      rescue Client::Error => e
        abort e.message
      end

      def username
        return @username if defined? @username
        @username = config 'github.user'
      end

      def password
        return @password if defined? @password
        @password = config 'github.password'
      end

      private

      def config key
        value = ENV["#{key.upcase.gsub '.', '_'}"] || `git config #{key}`.chomp
        value unless value.empty?
      end
    end
  end
end
