# encoding: utf-8

module GHI
  module Authorization
    extend Formatting

    class Required < RuntimeError
      def message() 'Authorization required.' end
    end

    class << self
      def token
        return @token if defined? @token
        pass = Security::GenericPassword.find(service: 'github.com/ghi')
        @token = (pass && pass.password) || nil
      end

      def authorize! user = username, pass = password, local = true
        return false unless user && pass
        code ||= nil # 2fa
        args = code ? [] : [54, "✔\r"]
        res = throb(*args) {
          headers = {}
          headers['X-GitHub-OTP'] = code if code
          body = {
            :scopes   => %w(public_repo repo),
            :note     => 'ghi',
            :note_url => 'https://github.com/stephencelis/ghi'
          }
          Client.new(user, pass).post(
            '/authorizations', body, :headers => headers
          )
        }
        @token = res.body['token']

        Security::GenericPassword.add('github.com/ghi', user, token)
        
      rescue Client::Error => e
        if e.response['X-GitHub-OTP'] =~ /required/
          puts "Bad code." if code
          print "Two-factor authentication code: "
          trap('INT') { abort }
          code = gets
          code = '' and puts "\n" unless code
          retry
        end

        abort "#{e.message}#{CURSOR[:column][0]}"
      end

      def username
        return @username if defined? @username
        @username = GHI.config 'github.user'
      end

      def password
        return @password if defined? @password
        @password = GHI.config 'github.password'
      end
    end
  end
end
