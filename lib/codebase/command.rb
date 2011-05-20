module Codebase
  class Command
    
    def initialize(block)
      (class << self;self end).send :define_method, :command, &block
    end
    
    def call(options, *args)
      @options = options
      arity = method(:command).arity
      args << nil while args.size < arity
      send :command, *args
    end
    
    def use_hirb
      begin
        require 'hirb'
        extend Hirb::Console
      rescue LoadError
        puts "Hirb is not installed. Install hirb using '[sudo] gem install hirb' to get cool ASCII tables"
        Process.exit(1)
      end
    end
    
    def options
      @options || Hash.new
    end

    def configured?
      git_config_variable(:domain) && git_config_variable(:username) && apikey
    end
    
    def new_username?
      git_config_variable(:username).match(/(.+)\/(.+)/)
    end
    
    def domain
      @domain ||= new_username? ? "#{new_username?[1]}.codebasehq.com" : git_config_variable(:domain)
    end
    
    def username
      @username ||= new_username? ? new_username?[2] : git_config_variable(:username)
    end
    
    def api_username
      @api_username = "#{domain.split('.').first}/#{username}"
    end
    
    def apikey
      @apikey ||= git_config_variable(:apikey)
    end
    
    def in_repository?
      repository_status != :false
    end
    
    def repository_properties
      return false unless in_repository?
      origin_name = (git_config_variable(:remote) || 'origin')
      remote_url  = git_config_variable("remote.#{origin_name}.url")
      if remote_url =~ /git\@(gitbase|codebasehq|cbhqdev)\.com:(.*)\/(.*)\/(.*)\.git/
        {:domain => $1, :account => $2, :project => $3, :repository => $4}
      else
        raise Codebase::Error, "Invalid Codebase repository (#{remote_url})"
      end
    end
    
    def repository_status
      @in_repository ||= (`git branch 2> /dev/null` && $?.success? ? true : :false) 
    end
    
    def execute_commands(array)
      for command in array
        puts "\e[44;33m" + command + "\e[0m"
        exit_code = 0
        IO.popen(command) do |f|
          output = f.read
          exit_code = Process.waitpid2(f.pid)[1]
        end
        if exit_code != 0
          $stderr.puts "An error occured running: #{command}"
          Process.exit(1)
        end
      end
    end
    
    def git_config_variable(name)
      if name.is_a?(Symbol)
        r = `git config codebase.#{name.to_s}`.chomp
      else
        r = `git config #{name.to_s}`.chomp
      end
      r.empty? ? nil : r
    end
    
    def api_request(url, username, password, data = nil)
      require 'uri'
      require 'net/http'
      require 'net/https'
      uri = URI.parse(url)
      if data
        req = Net::HTTP::Post.new(uri.path)
      else
        req = Net::HTTP::Get.new(uri.path)
      end
      req.basic_auth(username, password)
      req.add_field("Accept", "application/json")
      req.add_field("Content-type", "application/json")
      res = Net::HTTP.new(uri.host, uri.port)
      if url.include?('https://')
        res.use_ssl = true
        res.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      res = res.request(req, data)
      case res
      when Net::HTTPSuccess
        return res.body
      when Net::HTTPServiceUnavailable
        puts "The API is currently unavailable. Please check your codebase account has been enabled for API access."
        Process.exit(1)
      when Net::HTTPForbidden, Net::HTTPUnauthorized
        puts "Access Denied. Ensure you have correctly configured your local Gem installation using the 'cb setup' command."
        Process.exit(1)
      else
        return false
      end
    end
    
    def api(path, data = nil)
      api_request("http://api3.codebasehq.com/#{path}", api_username, apikey, data)
    end

  end
end
