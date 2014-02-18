module GHI
  module Commands
    class Find < List
      def options
        OptionParser.new do |opts|
          opts.banner = 'usage: ghi find [options] <keyword(s)>'
          opts.separator ''
          extract_globality(opts)
          extract_state(opts)
          extract_pull_request(opts)
          extract_repository(opts)
        end
      end

      def execute
        begin
          # because of the keyword extraction we cannot let the OptionParser
          # handle requests for the help screen
          detect_help_request
          extract_keywords
          options.parse!(args)
        rescue OptionParser::InvalidOption => e
          fallback.parse! e.args
          retry
        end

        query = assigns[:q].dup # cached for output string

        assigns[:per_page] = 100
        assigns[:repo] = repo
        assigns[:state] ||= 'open'

        handle_pull_request_options

        morph_params_to_qualifiers


        unless quiet
          print header = format_issues_header
          print "\n" unless paginate?
        end

        res = throb(
          0, format_state(assigns[:state], quiet ? CURSOR[:up][1] : '#')
        ) { api.get uri, assigns }

        print "\r#{CURSOR[:up][1]}" if header && paginate?
        #format_state(query_output_string(query))

        page header do
          issues = res.body['items']
          puts format_issues(issues, repo.nil?)

          break unless res.next_page
          res = throb { api.get res.next_page }
        end
      end

      private

      def after_filters
        @after_filters ||= {}
      end

      def extract_keywords
        keywords = []
        keywords << args.shift until args.empty? || args.first.start_with?('-')
        abort "No keyword(s) given.\n#{options}" if keywords.empty?

        assigns[:q] = keywords.join(' ')
      end

      def morph_params_to_qualifiers
        params = [:q, :sort, :order, :per_page]
        # this should be safe to do, because :q is always the first element in assigns
        copy = assigns.dup
        assigns.clear
        copy.each do |k, v|
          if params.include?(k)
            assigns[k] = v
          else
            assigns[:q] << " #{k}:#{v}"
          end
        end
      end

      def detect_help_request
        if args.any? && args.first.match(/^-?-h(elp)?$/)
          abort options.to_s
        end
      end

      def query_output_string(query)
        keywords = query.split
        pl = 's' if keywords.size > 1
        "with the keyword#{pl} #{keywords.join(', ')}"
      end

      def extract_repository(opts)
        opts.on('-r', '--repository <repo>', 'specifies a repository to search') do |repo|
          @repo = repo
        end
      end

      def handle_pull_request_options
        str = case
              when exclude_pull_requests then 'issue'
              when pull_requests_only    then 'pr'
              else return
              end

        assigns[:type] = str
      end

      def uri
        "/search/issues"
      end
    end
  end
end
