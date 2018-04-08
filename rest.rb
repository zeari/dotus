require 'sinatra'
require "sinatra/reloader"
require 'byebug'
require 'open3'
require 'sinatra/cross_origin'
dir="vm-48-38.eng.lab.tlv.redhat.com:8443"

set :bind, '0.0.0.0'
configure do
  enable :cross_origin
end

before do
  response.headers['Access-Control-Allow-Origin'] = '*'
end

# routes...
options "*" do
  response.headers["Allow"] = "GET, POST, OPTIONS"
  response.headers["Access-Control-Allow-Headers"] = "Authorization, Content-Type, Accept, X-User-Email, X-Auth-Token"
  response.headers["Access-Control-Allow-Origin"] = "*"
  200
end

get '/' do
  File.read(File.join('public', 'index.html'))
end

# localhost:4567/ls - get list of current files\objs in the db
get '/ls' do
  content_type :json

  cmd = 'cd ' + dir + '; ../get_ls.sh '
  lstime = params[:time]
  if !lstime.nil?
   cmd += lstime
  end
  o, s = Open3.capture2(cmd)

  result = []
  o.split("\n").each do |line|
   result << line
  end

  JSON.pretty_generate(result)
end

#localhost:4567/history?path=pods/prometheus-0
get '/history' do
  content_type :json
  file_path = params[:path]
  jq = params[:jq]

  if jq.nil?
    script = "../get_history.sh"
  else
    script = "../get_history_with_jq.sh"
  end

  cmd = 'cd ' + dir + '; ' + script + ' ' + file_path + ' ' + jq.to_s
  o, s = Open3.capture2(cmd)
  result = []
  current_obj = {}

  o.split("\n").each do |json|
    begin
    if current_obj["time"].nil?
      current_obj["time"] = Time.parse(json)
    else
      begin
        current_obj["value"] = JSON.parse(json)
      rescue
        current_obj["value"] = json.tr '"', ''
      end
      result << current_obj.dup
      current_obj = {}
    end
    rescue Exception => e
      byebug
    end
  end

  JSON.pretty_generate(result)
end



