module GHI
  module Commands
    class Find < List
      def options
        OptionParser.new do |opts|
          opts.banner = 'usage: ghi find [options] <keywords>'
          opts.separator ''
          parse_globality(opts)
        end
      end

      def execute
        begin
          extract_keywords
          options.parse!(args)
        rescue OptionParser::InvalidOption => e
          fallback.parse! e.args
          retry
        end

        assigns[:repo] ||= repo if repo
        query = assigns[:q].dup # cached for output string
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

      def extract_keywords
        puts args
        keywords = []
        keywords << args.shift until args.empty? || args.first.start_with?('-')
        # raise missing_keywords if keywords.empty? || args.empty?

        assigns[:q] = keywords.join(' ')
      end

      def morph_params_to_qualifiers
        params = [:q, :sort, :order]
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

      def query
        assigns[:q]
      end

      def query_output_string(query)
        keywords = query.split
        pl = 's' if keywords.size > 1
        "with the keyword#{pl} #{keywords.join(', ')}"
      end

      def uri
        "/search/issues"
      end
    end
  end
end
