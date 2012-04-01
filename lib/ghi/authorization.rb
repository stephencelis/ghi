module GHI
  module Authorization
    class Required < RuntimeError
    end

    class << self
      def token
        return @token if defined? @token
        value = `git config ghi.token`.chomp
        @token = value unless value.empty?
      end

      def authorize! username = username, password = password, global = true
        res = Client.new(username, password).post(
          '/authorizations',
          :scopes   => %w(public_repo repo),
          :note     => 'ghi',
          :note_url => 'https://github.com/stephencelis/ghi'
        )
        @token = res['token']
        `git config #{'--global ' if global} ghi.token #@token`
      end

      def username
        config 'user'
      end

      def password
        config 'password'
      end

      private

      def config key
        ENV["GITHUB_#{key.upcase}"] || `git config github.#{key}`.chomp
      end
    end
  end
end
