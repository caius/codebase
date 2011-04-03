Capistrano::Configuration.instance(:must_exist).load do
  
  after "deploy:symlink", 'codebase:deploy'
  
  namespace :codebase do
    
    desc "Open the Codebase comparison for the changes which are due to be deployed"
    task :pending, :except => { :no_release => true } do
      if match = repository.match(/git\@(codebasehq|gitbase)\.com\:([\w\-]+)\/([\w\-]+)\/([\w\-]+)\.git/)
        from = source.next_revision(current_revision)
        to   = `git ls-remote #{repository} #{branch}`.split(/\s+/).first
        url  = "https://#{match[2]}.codebasehq.com/#{match[3]}/#{match[4]}/compare/#{from}..#{to}"
        puts "Opening... #{url}"
        system("open #{url}")
      else
        puts "! Repository does not match a valid Codebase Git URL."
      end
    end
    
    desc 'Log a deployment in Codebase'
    task :deploy do
      username = `git config codebase.username`.chomp.strip
      api_key  = `git config codebase.apikey`.chomp.strip
      
      if username == '' || api_key == ''
        puts "  * Codebase is not configured on your computer. Run 'codebase setup' to auto configure it."
        puts "  * Deployments will not be tracked."
        next
      end
      
      regex = /git\@(gitbase|codebasehq)\.com:(.*)\/(.*)\/(.*)\.git/
      unless m = repository.match(regex)
        puts "  * \e[31mYour repository URL does not a match a valid CodebaseHQ Clone URL\e[0m"
      else
        url = "#{m[2]}.codebasehq.com"
        project = m[3]
        repository = m[4]
        
        puts "  * \e[44;33mAdding Deployment to your CodebaseHQ account\e[0m"
        puts "      -  Account......: #{url}"
        puts "      -  Username.....: #{username}"
        puts "      -  API Key......: #{api_key[0,10]}..."
        
        puts "      -  Project......: #{project}"
        puts "      -  Repository...: #{repository}"
        
        environment_to_send = begin
          if respond_to?(:environment)
            env = environment.dup
            env.gsub!(/\W+/, ' ')
            env.strip!
            env.downcase!
            env.gsub!(/\ +/, '-')        
            puts "      -  Environment..: #{env}" unless env.nil? || env.empty?
            env
          else
            ''
          end
        end
        
        servers = roles.values.collect{|r| r.servers}.flatten.collect{|s| s.host}.uniq.join(', ') rescue ''
        
        puts "      -  Servers......: #{servers}"
        puts "      -  Revision.....: #{real_revision}"
        puts "      -  Branch.......: #{branch}"
        
        xml = []
        xml << "<deployment>"
        xml << "<servers>#{servers}</servers>"
        xml << "<revision>#{real_revision}</revision>"
        xml << "<environment>#{environment_to_send}</environment>"
        xml << "<branch>#{branch}</branch>"
        xml << "</deployment>"
        
        require 'net/http'
        require 'uri'
        
        real_url = "http://#{url}/#{project}/#{repository}/deployments"
        puts "      -  URL..........: #{real_url}"
        
        url = URI.parse(real_url)
        
        req = Net::HTTP::Post.new(url.path)
        req.basic_auth(username, api_key)
        req.add_field('Content-type', 'application/xml')
        req.add_field('Accept', 'application/xml')
        res = Net::HTTP.new(url.host, url.port).start { |http| http.request(req, xml.join) }
        case res
        when Net::HTTPCreated then puts "  * \e[32mAdded deployment to Codebase\e[0m"
        else 
          puts "  * \e[31mSorry, your deployment was not logged in Codebase - please check your config above.\e[0m"
        end
      end
    end
    
  end
end
