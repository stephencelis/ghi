require "typhoeus"
require "json"
require "pp"

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

def get_body path, err_msg=""
	response=get(path)
	assert_equal(200,response.code,err_msg)
	JSON.load(response.body)
end
