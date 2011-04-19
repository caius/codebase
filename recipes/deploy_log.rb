begin
  require 'codebase/recipes'
rescue Exception => e
  puts %{
    
    Couldn't load codebase - might wanna install the gem
  
  }
end
