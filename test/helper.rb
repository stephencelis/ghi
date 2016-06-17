require "typhoeus"
require "json"
require "shellwords"
require "pp"
require "securerandom"
require "mock_data"
require "test/unit"

def append_token headers
	headers.merge(:Authorization=>"token #{ENV["GHI_TOKEN"]}")
end

def get_url path
	"https://api.github.com/#{path}"
end

def request path, method, options={}, use_basic_auth=true
	if options[:params].nil?
		options.merge!(:params=>{})
	end
	if options[:headers].nil?
		options.merge!(:headers=>{})
	end
	if options[:body].nil?
		options.merge!(:body=>{})
	end

	Typhoeus::Request.new(get_url(path),
												method: method,
												body: JSON.dump(options[:body]),
												params: options[:params],
												username: (if use_basic_auth then ENV["GITHUB_USER"] else nil end),
												password: (if use_basic_auth then ENV["GITHUB_PASSWORD"] else nil end),
												headers: (if use_basic_auth then options[:headers] else append_token(options[:headers]) end)
											 ).run
end

def head path, options={}
	request(path,:head,options)
end

def get path, options ={}
	request(path,:get,options)
end

def post path, options ={}
	request(path,:post,options)
end

def delete path, options ={}
	request(path,:delete,options)
end

def delete_repo repo_name
	unless ENV["NO_DELETE_REPO"]=="1"
		delete("repos/#{repo_name}")
	end
end

def ghi_exec
	File.expand_path('../ghi', File.dirname(__FILE__))
end

def get_attr index, attr
	Shellwords.escape(issues[index][attr])
end

def gen_token
	ENV["GHI_TOKEN"]=`#{ghi_exec} config --auth --just_print_token`.chop
	response=request("users/#{ENV['GITHUB_USER']}",:head,{},false)

	assert_equal('public_repo, repo',response.headers["X-OAuth-Scopes"])
end

def delete_token
	unless ENV["NO_DELETE_TOKEN"]=="1"
		token_info=get_body("authorizations","Impossible api error").detect {|token| token["token_last_eight"] == ENV["GHI_TOKEN"][-8..-1]}
		assert_not_equal(nil,token_info,"Token with hash: #{ENV["GHI_TOKEN"]} does not exist")
		delete("authorizations/#{token_info["id"]}")
	end
end

def create_repo
	repo_name=SecureRandom.uuid
	response=post("user/repos",{body:{'name':repo_name}})
	response_body=JSON.load(response.response_body)
	assert_not_equal(nil,response_body["name"],"Could not create repo #{repo_name}")
	response_body["full_name"]
end

def get_issue index=0
	if index == -1
		tmp_issues=issues
	else
		tmp_issues=[issues[index]]
	end
	for i in 0..(tmp_issues.length-1)
		tmp_issues[i][:des].gsub!(/\n/,"<br>")
		# http://stackoverflow.com/questions/12700218/how-do-i-escape-a-single-quote-in-ruby
		tmp_issues[i][:des].gsub!(/'/){"\\'"}
	end
	return (index != -1)?tmp_issues[0]:tmp_issues
end

def get_comment index=0
	comments[index]
end

def get_milestone index=0
	milestones[index]
end

def get_body path, err_msg=""
	response=get(path)
	assert_equal(200,response.code,err_msg)
	JSON.load(response.body)
end
