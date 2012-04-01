module GHI
  module Commands
    # Alias to `ghi assign -d`.
    #--
    # FIXME: Consider making this an alias, instead.
    #++
    class Unassign < Assign
      def execute
        args.unshift '-d'
        super
      end
    end
  end
end
