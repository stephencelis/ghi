module GHI
  module Commands
    autoload :Command,   'ghi/commands/command'

    autoload :List,      'ghi/commands/list'
    autoload :Open,      'ghi/commands/open'
    autoload :Assign,    'ghi/commands/assign'
    autoload :Close,     'ghi/commands/close'
    autoload :Comment,   'ghi/commands/comment'
    autoload :Config,    'ghi/commands/config'
		autoload :Disable,   'ghi/commands/disable'
    autoload :Edit,      'ghi/commands/edit'
		autoload :Enable,    'ghi/commands/enable'
    autoload :Help,      'ghi/commands/help'
    autoload :Label,     'ghi/commands/label'
    autoload :Lock,      'ghi/commands/lock'
    autoload :Milestone, 'ghi/commands/milestone'
    autoload :Reopen,    'ghi/commands/reopen'
    autoload :Show,      'ghi/commands/show'
		autoload :Status,    'ghi/commands/status'
    autoload :Unassign,  'ghi/commands/unassign'
    autoload :Unlock,    'ghi/commands/unlock'
    autoload :Version,   'ghi/commands/version'
  end
end
