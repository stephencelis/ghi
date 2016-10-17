require "helper"
require "json"
require "pp"

# This is helpful if your account(fake) gets littered with repos.
# You need to run ruby -I. delete_all_repos.rb. If you are executing from a
# different directory then you need to change the parameter of -I
# appropriately.

puts "Warning this will delete ALL repositories from the account pointed by GITHUB_USER environment variable"
puts "The account name(login) is #{ENV["GITHUB_USER"]}"
puts "Do you want to continue [N/y]"
option = gets
if option.chop == "y"
  puts "Deleting"
  while true
    response=request("users/#{ENV["GITHUB_USER"]}/repos",:get,{},true)
    repos=JSON.load(response.body)
    if repos.length == 0
      puts "Exiting"
      break
    end
    repos.each do |repo|
      puts "Deleting #{repo["full_name"]}"
      delete_repo(repo["full_name"])
    end
  end
else
  puts 'Not deleting'
end
