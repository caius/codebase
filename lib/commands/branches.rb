desc "Create a new branch locally and on the remote"
usage "cb mkbranch [new_branch_name] (source_branch)"
flags "--origin", "The origin to use when pushing to remote"
command "mkbranch", :required_args => 1 do |branch_name, source_branch|
  source_branch = "master" if source_branch.nil?
  remote_origin = "origin" if @options[:origin].nil?
  commands = []
  commands << "git push origin #{source_branch}:refs/heads/#{branch_name}"
  commands << "git fetch origin"
  commands << "git branch --track #{branch_name} origin/#{branch_name}"
  commands << "git checkout #{branch_name}"
  execute_commands(commands)
end

desc "Remove a branch from the remote service and remove it locally if it exists."
usage "cb rmbranch [branch_name]"
command "rmbranch", :required_args => 1 do |branch_name|
  commands = []
  commands << "git push origin :#{branch_name}"
  unless `git for-each-ref refs/heads/#{branch_name}`.empty?
    current_branch = `git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'`.chomp.split(/\s+/).last
    if branch_name == current_branch
      commands << "git checkout master" ## assume master...
    end
    commands << "git branch -d #{branch_name}"
  end
  execute_commands(commands)
end
