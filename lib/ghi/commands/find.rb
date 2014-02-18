module GHI
  module Commands
    class Find < List
      def options
        OptionParser.new do |opts|
          opts.banner = 'usage: ghi find <keyword(s)> [options]'
          opts.separator ''

          extract_globality(opts)
          extract_state(opts)
          extract_label_inclusion(opts)
          extract_label_exclusion(opts)
          extract_pull_request(opts)
          extract_fields(opts)

          opts.separator ''

          extract_assignee(opts)
          extract_assigment_to_you(opts)
          extract_creator(opts)
          extract_mentioned(opts)
          extract_user_bound_search(opts)

          opts.separator ''

          extract_verbosity(opts)
          extract_quiteness(opts)

        end
      end

      def execute
        # because of the keyword extraction we cannot let the OptionParser
        # handle requests for the help screen
        detect_help_request
        extract_keywords
        options.parse!(args)

        # TODO pagination. Is it broken in the search API?

        assigns[:repo] = repo if repo
        assigns[:state] ||= 'open'

        unless quiet
          print header = format_issues_header(prepared_format_params)
          print "\n" unless paginate?
        end

        # some preparations to handle the differences in the API's of the
        # issues (used by List) and search (used by Find)
        assigns.delete(:filter) # defined by List, we don't need it
        handle_pull_request_options
        extract_after_filters
        fix_key_names

        morph_params_to_qualifiers

        res = throb(
          0, format_state(assigns[:state], quiet ? CURSOR[:up][1] : '#')
        ) { api.get uri, assigns }

        print "\r#{CURSOR[:up][1]}" if header && paginate?

        page header do
          issues = res.body['items']

          issues = issues_without_excluded_labels(issues, after_filters[:exclude_labels])

          put_issues(issues)

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
        # labels need different handling due to the qualifier syntax
        labels = assigns.delete(:labels)
        params = [:q, :sort, :order, :per_page]
        # this should be safe to do, because :q is always the first element in assigns
        copy = assigns.dup
        assigns.clear
        copy.each do |k, v|
          if params.include?(k)
            assigns[k] = v
          else
            assigns[:q] << to_qualifier(k, v)
          end
        end
        add_labels(labels)
      end

      def add_labels(labels)
        if labels
          labels.each do |label|
            assigns[:q] << to_qualifier(:label, label)
          end
        end
      end

      def extract_after_filters
        [:exclude_labels].each do |f|
          filter = assigns.delete(f)
          after_filters[f] = filter if filter
        end
      end

      def to_qualifier(qualifier, value)
        v = value.kind_of?(Array) ? value.join(',') : value
        " #{qualifier}:#{v}"
      end

      def detect_help_request
        if args.any? && args.first.match(/^-?-h(elp)?$/)
          abort options.to_s
        end
      end

      def extract_fields(opts)
        opts.on('-f', '--fields <fields>...', Array,
                'specifies fields to search in: title, body and/or comment') do |fields|
          assigns[:in] = fields
        end
      end

      def extract_quiteness(opts)
        opts.on('-q', '--quiet') { self.quiet = true }
      end

      def extract_user_bound_search(opts)
        opts.on('--repos-of <user>', 'search in all repos of a user') do |user|
          @repo = nil
          assigns[:user] = user
        end
        opts.on('--my-repos', 'search in all of your repos') do
          @repo = nil
          assigns[:user] = Authorization.username
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

      # this is a little ugly but is needed to fulfill the contract
      # of Formatting#format_issues_header
      # Might be in order to refactor the handling of Arrays in List
      # to avoid this.
      def prepared_format_params
        params = assigns.merge(after_filters).map do |k, v|
          v = v.join(',') if v.kind_of?(Array)
          [k, v]
        end
        Hash[params]
      end

      # Some qualifiers/params have different naming in github's
      # APIs for issues and search.
      # We cannot use the proper values in the initial option extraction
      # because we want to use the the API of the Formatting module
      def fix_key_names
        changes = {
          creator: :author,
          mentioned: :mentions,
        }

        changes.each do |issue_key, search_key|
          if value = assigns.delete(issue_key)
            assigns[search_key] = value
          end
        end
      end

      def uri
        "/search/issues"
      end

      def find_mode?
        true
      end
    end
  end
end
