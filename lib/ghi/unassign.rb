module GHI
  # Alias to `ghi assign -d`.
  #--
  # FIXME: Consider making this an alias, instead.
  #++
  class Unassign < Assign
    def self.execute args
      super args.unshift('-d')
    end
  end
end
