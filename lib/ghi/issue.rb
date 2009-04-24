class GHI::Issue
  attr_reader :number, :title, :body, :votes, :state, :user, :created_at,
    :updated_at

  def initialize(options = {})
    @number     = options["number"]
    @title      = options["title"]
    @body       = options["body"]
    @votes      = options["votes"]
    @state      = options["state"]
    @user       = options["user"]
    @created_at = options["created_at"]
    @updated_at = options["updated_at"]
  end

  #-
  # REFACTOR: This code is duplicated from cli.rb:gets_from_editor.
  #+
  def ==(other_issue)
    case other_issue
    when Array
      other_title = other_issue.first.strip
      other_body  = other_issue[1..-1].join.sub(/\b\n\b/, " ").strip
      title == other_title && body == other_body
    else
      super other_issue
    end
  end
end
