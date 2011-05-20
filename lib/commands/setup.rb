desc "Setup the Codebase gem for your user account"
desc "This tool will automatically prompt you for your login details and then download your"
desc "details (including API key) and configure your local computer to use them."
usage "cb setup"
command "setup" do
  
  require 'highline/import'
  
  ## We need git...
  unless `which git` && $?.success?
    puts "To use the Codebase gem you must have Git installed on your local computer. Git is used to store"
    puts "important configuration variables which allow the gem to function."
    Process.exit(1)
  end
  
  puts "\e[33;44mWelcome to the CodebaseHQ Initial Setup Tool\e[0m"
  puts "This tool will get your local computer configured to use your codebase account. It will automatically configure"
  puts "the gem for API access so you can use many of the gem functions."  
  puts
  
  ## Are you in a repository?
  global = '--global'
  if in_repository?
    puts "You are currently in a repository directory."
    if agree("Would you like to only apply configuration to actions carried out from within this directory?")
      global = ''
      puts "OK, we'll add your API details to this repository only."
    else
      puts "OK, we'll configure your API details for your whole user account."
    end
  end
  
  ## Is this configured?
  if configured? && !global.empty?
    puts
    puts "This system is already configured as \e[32m#{username}\e[0m."
    unless agree("Do you wish to continue?")
      Process.exit(0)
    end
  end
  
  puts
    
  ## Get some details
  domain     = ask("CodebaseHQ domain (e.g. widgetinc.codebasehq.com): ") { |q| q.validate = /\A(\w+).(codebasehq|cbhqdev).(com|local)\z/ }
  username   = ask("Username: ") { |q| q.validate = /[\w\.]+/ }
  api_user   = username.match(/\//) ? username : "#{domain.split('.')[0]}/#{username}"
  api_domain = 'api3.codebasehq.com'
  password   = ask("Password: ") { |q| q.echo = false }

  ## Get the API key and save it...
  user_properties = api_request("https://#{api_domain}/profile", api_user, password)
  
  if user_properties
    user = JSON.parse(user_properties)["user"]
    system("git config #{global} codebase.username #{username}")
    system("git config #{global} codebase.apikey #{user['api_key']}")
    system("git config #{global} codebase.domain #{domain}")
    system("git config #{global} user.name '#{user['first_name']} #{user['last_name']}'")
    puts "Set user.name to '#{user['first_name']} #{user['last_name']}'"
    system("git config #{global} user.email #{user['email_address']}")
    puts "Set user.email to '#{user['email_address']}'"
    puts "\e[32mConfigured Codebase API authentication properties successfully.\e[0m"
  else
    puts "\e[37;41mAccess Denied. Please ensure you have entered your username & password correctly and try again.\e[0m"
    return
  end  
end
