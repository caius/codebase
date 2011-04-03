desc "Clone a repository."
desc "The application will ask you to choose a project & repository before cloning the repository to your clone computer."
usage "cb clone"
flags "--path", "The path to export your repository to (optional)"
command "clone" do  
  require 'rubygems'
  require 'json'
  require 'highline/import'
  HighLine.track_eof = false
  
  raise Codebase::NotConfiguredError unless configured?
        
  projects = JSON.parse(api('projects'))
  projects = projects.select{|p| p["project"]["status"].first == 'active'}.map{|p| p['project']}
  
  ## Please somebody tell me there is a better way to do this using highline...
  project_hash = {}
  project_id = choose do |menu|
    menu.select_by = :index
    menu.prompt = "Please select a project: "
    count = 0
    for project in projects
      project_hash[project['name']] = project['permalink']
      menu.choice(project['name'])
    end
  end
  
  project = project_hash[project_id]
  
  repositories = JSON.parse(api("#{project}/repositories"))
  repositories = repositories.map{|r| r['repository']}
  
  repos_hash = {}
  repo_id = choose do |menu|
    menu.select_by = :index
    menu.prompt = "Please select a repository:"
    for repository in repositories
      repos_hash[repository['name']] = repository
      menu.choice(repository['name'])
    end
  end
  
  repository = repos_hash[repo_id]['permalink']
  clone_url  = repos_hash[repo_id]['clone_url']
  scm        = repos_hash[repo_id]['scm']
  
  if @options[:path]
    export_path = @options[:path]
  else
    export_path = File.join(project, repository)
    folder = ask("Where would you like to clone this repository to? (default: #{export_path})")
    unless folder.nil? || folder.empty?
      export_path = folder
    end    
  end
  
  system("mkdir -p #{export_path}")
  
  case scm
  when 'git' then exec("git clone #{clone_url} #{export_path}")
  when 'hg'  then exec("hg clone ssh://#{clone_url} #{export_path}")
  when 'svn' then exec("svn checkout #{clone_url} #{export_path}")
  else
    puts "Unsupported SCM."
  end
end
