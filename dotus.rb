#!/bin/ruby 

require 'kubeclient'
#require 'openshift_client'
require 'fileutils'
require 'rubygems'
require 'git'
require 'json'
require 'benchmark'
require 'byebug'

config = YAML.load_file("config.yaml")
type = config["config"]["type"]
url = config["config"]["url"]
token = config["config"]["token"]
interval = config["config"]["interval"].to_i # in minutes
git_directory = config["config"]["directory"] # where to keep the data
kube_config_path = config["config"]["kube_config_path"]
api_version = "v1"
auth_options = { bearer_token: token }
ssl_options = { :client_cert=>nil, :client_key=>nil, :ca_file=>nil, :cert_store=>nil, :verify_ssl=>0 }
url = 'https://' + url

k8s_entitites_to_save = [:pods, :secrets, :services,
                     :nodes, :replication_controllers,
                     :resource_quotas, :limit_ranges,
                     :persistent_volumes, :persistent_volume_claims,
                     :component_statuses, :service_accounts]

# os_entitites_to_save = k8s_entitites_to_save + [:routes, :templates, :projects, :build,
#                                                 :build_config, :image, :image_stream]



if type == "kubernetes"
  entitites_to_save = k8s_entitites_to_save
# elsif type == "openshift"
#   entitites_to_save = os_entitites_to_save
end

if !kube_config_path.empty?
  config = client_class::Config.read(kube_config_path)
  url = config.context.api_endpoint
  api_version = config.context.api_version
  ssl_options = config.context.ssl_options
  auth_options =  config.context.auth_options
end

while true do
  by_namespace = {}

  begin
    client = Kubeclient::Client.new(url,
                              api_version,
                              :ssl_options  => ssl_options,
                              :auth_options => auth_options)

    unless client.discovered
      client.discover
    end

    FileUtils::mkdir_p(git_directory)
    initgit = false

    begin
     g = Git.open(git_directory)
    rescue
     puts  'need to init a new git repo in ' + git_directory
     initgit = true
    end

    if initgit
      p 'git init ' + git_directory
      g = Git.init(git_directory)
    end

    # erase all files and recreate later.
    Dir.foreach(git_directory) do |f|
      fn = File.join(git_directory, f)
      FileUtils.rm_rf(fn) if f != '.' && f != '..' && f != '.git'
    end

    puts Benchmark.measure {
       entitites_to_save.each do |entity_type|
        begin
          FileUtils::mkdir_p git_directory + '/' + entity_type.to_s

          # get data, write to files in a git repo
          print 'getting ' + entity_type.to_s
          ents = client.send('get_' + entity_type.to_s)

          ents.each do |ent|
	          filepath = entity_type.to_s + '/' + ent.metadata.name
            File.open(git_directory + '/' + filepath, 'w') { |file| file.write(JSON.pretty_generate(ent.to_h) + "\n") }
            namespace = ent["metadata"]["namespace"]
            if !namespace.nil?
              by_namespace[namespace] ||= []
              by_namespace[namespace] << filepath
            end 
          end
          puts '(' + ents.count.to_s + ')'
        rescue Exception => e
         puts '- can\'t get ' + entity_type.to_s + ": " + e.message
#         puts e.backtrace
        end
       end

       FileUtils.chdir(git_directory) do
         by_namespace.each do |namespace, files|
           FileUtils::mkdir_p './namespaces/' + namespace
           files.each do |file|
             FileUtils::mkdir_p './namespaces/' + namespace + '/' + file.split('/')[0]
             FileUtils.ln_s('../../../' + file, './namespaces/' + namespace + '/' + file.split('/')[0] + '/' + file.split('/')[1])
           end
         end
       end
    }

    File.open(git_directory + '/time', 'w') { |file| file.write(Time.now.utc.to_s + "\n") }
    g.add(:all=>true)
    g.commit(Time.now.utc)
  rescue Exception => e
    puts e.message  
    puts e.backtrace
  ensure
    sleep_seconds = 60 * interval
    puts 'sleeping until ' + (Time.now + sleep_seconds).to_s 
    sleep(sleep_seconds)
  end
end



