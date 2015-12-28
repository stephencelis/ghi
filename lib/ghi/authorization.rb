# encoding: utf-8
require 'socket'

module GHI
  module Authorization
    extend Formatting

    class Required < RuntimeError
      def message() 'Authorization required.' end
    end

    class << self
      def token
        return @token if defined? @token
        @token = GHI.config 'ghi.token'
      end

      def authorize! user = username, pass = password, local = true
        return false unless user && pass
        code ||= nil # 2fa
        args = code ? [] : [54, "✔\r"]
        note = %w[ghi]
        note << "(#{GHI.repo})" if local
        note << "on #{Socket.gethostname}"
        res = throb(*args) {
          headers = {}
          headers['X-GitHub-OTP'] = code if code
          body = {
            :scopes   => %w(public_repo repo),
            :note     => note.join(' '),
            :note_url => 'https://github.com/stephencelis/ghi'
          }
          Client.new(user, pass).post(
            '/authorizations', body, :headers => headers
          )
        }
        @token = res.body['token']

        unless username
          system "git config#{' --global' unless local} github.user #{user}"
        end

        store_token! user, token, local
      rescue Client::Error => e
        if e.response['X-GitHub-OTP'] =~ /required/
          puts "Bad code." if code
          print "Two-factor authentication code: "
          trap('INT') { abort }
          code = gets
          code = '' and puts "\n" unless code
          retry
        end

        if e.errors.any? { |err| err['code'] == 'already_exists' }
          host = GHI.config('github.host') || 'github.com'
          message = <<EOF.chomp
A ghi token already exists!

Please revoke all previously-generated ghi personal access tokens here:

  https://#{host}/settings/tokens
EOF
        else
          message = e.message
        end
        abort "#{message}#{CURSOR[:column][0]}"
      end

      def username
        return @username if defined? @username
        @username = GHI.config 'github.user'
      end

      def password
        return @password if defined? @password
        @password = GHI.config 'github.password'
      end

      private

      def store_token! username, token, local
        if security
          run  = []

          run << security('delete', username)
          run << security('add', username, token)

          find = security 'find', username, false
          run << %(git config#{' --global' unless local} ghi.token "!#{find}")

          system run.join ' ; '

          puts "✔︎ Token saved to keychain."
          return
        end

        command = "git config#{' --global' unless local} ghi.token #{token}"
        system command

        unless local
          at_exit do
            warn <<EOF
Your ~/.gitconfig has been modified by way of:

  #{command}

#{bright { blink { 'Do not check this change into public source control!' } }}

You can increase security by storing the token in a secure place that can be
fetched from the command line. E.g., on OS X:

  git config --global ghi.token \\
    "!security -a #{username} -s github.com -l 'ghi token' -w"

Alternatively, set the following env var in a private dotfile:

  export GHI_TOKEN="#{token}"
EOF
          end
        end
      end

      def security command = nil, username = nil, password = nil
        if command.nil? && username.nil? && password.nil?
          return system 'which security >/dev/null'
        end

        run = [
          'security',
          "#{command}-internet-password",
          "-a #{username}",
          '-s github.com',
          "-l 'ghi token'"
        ]
        run << %(-w#{" #{password}" if password}) unless password.nil?
        run << '>/dev/null 2>&1' unless command == 'find'

        run.join ' '
      end
    end
  end
end
