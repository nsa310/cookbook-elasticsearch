elasticsearch = "elasticsearch-#{node.elasticsearch[:version]}"

# Include the `curl` recipe, needed by `service status`
#
include_recipe "elasticsearch::curl"

# Create user and group
#
group node.elasticsearch[:user] do
  action :create
end

user node.elasticsearch[:user] do
  comment "ElasticSearch User"
  home    "#{node.elasticsearch[:dir]}/elasticsearch"
  shell   "/bin/bash"
  gid     node.elasticsearch[:user]
  supports :manage_home => false
  action  :create
end

# FIX: Work around the fact that Chef creates the directory even for `manage_home: false`
bash "remove the elasticsearch user home" do
  user    'root'
  code    "rm -rf  #{node.elasticsearch[:dir]}/elasticsearch"
  only_if "test -d #{node.elasticsearch[:dir]}/elasticsearch"
end

# Increase open file limits
#
bash "enable user limits" do
  user 'root'

  code <<-END.gsub(/^    /, '')
    echo 'session    required   pam_limits.so' >> /etc/pam.d/su
  END

  not_if { ::File.read("/etc/pam.d/su").match(/^session    required   pam_limits\.so/) }
end

bash "increase limits for the elasticsearch user" do
  user 'root'

  code <<-END.gsub(/^    /, '')
    echo '#{node.elasticsearch.fetch(:user, "elasticsearch")}     -    nofile    #{node.elasticsearch[:limits][:nofile]}'  >> /etc/security/limits.conf
    echo '#{node.elasticsearch.fetch(:user, "elasticsearch")}     -    memlock   #{node.elasticsearch[:limits][:memlock]}' >> /etc/security/limits.conf
  END

  not_if { ::File.read("/etc/security/limits.conf").include?("#{node.elasticsearch.fetch(:user, "elasticsearch")}     -    nofile")  }
end

# Download ES
#
remote_file "/tmp/elasticsearch-#{node.elasticsearch[:version]}.tar.gz" do
  source "https://github.com/downloads/elasticsearch/elasticsearch/#{elasticsearch}.tar.gz"
  action :create_if_missing
end

# Move to ES dir
#
bash "Move elasticsearch to #{node.elasticsearch[:dir]}/elasticsearch" do
  user "root"
  cwd  "/tmp"

  code <<-EOS
    tar xfz /tmp/#{elasticsearch}.tar.gz
    mv --force /tmp/#{elasticsearch}/* #{node.elasticsearch[:dir]}/elasticsearch/
  EOS

  creates "#{node.elasticsearch[:dir]}/elasticsearch/lib/#{elasticsearch}.jar"
  creates "#{node.elasticsearch[:dir]}/elasticsearch/bin/elasticsearch"
end

#Download ES service wrapper
#
remote file "/tmp/service.tar.gz" do
  source "http://github.com/elasticsearch/elasticsearch-servicewrapper/tarball/master"
  action :create_if_missing
end

#Move service wrapper
#
bash "Move ES service wrapper to #{node.elasticsearch[:dir]}/elasticsearch/bin" do
  user "root"

  code <<-EOS
    tar -xzf /tmp/service.tar.gz
    mv --force /tmp/service/* #{node.elasticsearch[:dir]}/elasticsearch/bin/
  EOS
end

#Modify ES init script in service wrapper
#
template "#{node.elasticsearch[:dir]}/elasticsearch/bin/service/elasticsearch" do
  source "elasticsearch.init.erb"
  owner 'root' and mode 0755
end

#Modify ES configuration of service wrapper
#
template "#{node.elasticsearch[:dir]}/elasticsearch/bin/service/elasticsearch.conf" do
  source "elasticsearch-service.conf.erb"
  owner 'root' and mode 0755
end

# Create service
#
bash "Install ES service wrapper from #{node.elasticsearch[:dir]}/elasticsearch/bin/service/elasticsearch" do
  user "root"
  code <<-EOS
    #{node.elasticsearch[:dir]}/elasticsearch/bin/service/elasticsearch install
  EOS
end

#Create lock dir
#
bash "create ES lock dir" do
  user "root"
  code <<-EOS
     mkdir #{node.elasticsearch[:dir]}/elasticsearch/lock
  EOS
end

# Ensure proper permissions
#
bash "Ensure proper permissions for #{node.elasticsearch[:dir]}/elasticsearch" do
  user    "root"
  code    <<-EOS
    chown -R #{node.elasticsearch[:user]}:#{node.elasticsearch[:user]} #{node.elasticsearch[:dir]}/elasticsearch
    chmod -R 775 #{node.elasticsearch[:dir]}/elasticsearch
  EOS
end

# Create ES config file
#
template "elasticsearch.yml" do
  path   "#{node.elasticsearch[:dir]}/elasticsearch/config/elasticsearch.yml"
  source "elasticsearch.yml.erb"
  owner node.elasticsearch[:user] and group node.elasticsearch[:user] and mode 0755

  notifies :restart, resources(:service => 'elasticsearch')
end

# Add Monit configuration file
#
monitrc("elasticsearch", :pidfile => "#{node.elasticsearch[:pid_path]}/#{node.elasticsearch[:node_name].to_s.gsub(/\W/, '_')}.pid") \
  if node.recipes.include?('monit')
