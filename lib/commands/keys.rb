desc "View a list of all keys assigned to your user account. All keys are displayed in a table."
usage "cb keys"
command "keys" do
  require 'rubygems'
  use_hirb
  
  keys = api("users/#{username}/public_keys")
  keys = JSON.parse(keys).map{|k| k['public_key_join']}
  keys = keys.map{|k| {:description => k['description'], :key => k['key'][0, 50] + '...' }}
  table keys, :fields => [:description, :key], :headers => {:description => 'Description', :key => 'Key'}
end

desc "Add a new key to your Codebase user account. "
desc "By default, it will use the key located in '~/.ssh/id_rsa.pub' otherwise it'll use the key you specify."
flags "--description", "Description to use when uploading the key. Defaults to 'Key'"
usage "cb keys:add (path/to/key)"
command "keys:add" do |path|
  path = File.expand_path(".ssh/id_rsa.pub", "~") if path.nil?
  unless File.exist?(path)
    puts "Key file not found at '#{path}'"
    Process.exit(1)
  end
  
  data = {'public_key' => {'description' => (options[:description] || "Key"), 'key' => File.read(path)}}.to_json
  if api("users/#{username}/public_keys", data)
    puts "Successfully added key."
  else
    puts "An error occured while adding your key."
  end
end
