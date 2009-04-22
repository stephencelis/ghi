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
end
