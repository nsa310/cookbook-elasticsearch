elasticsearch = "elasticsearch-#{node.elasticsearch[:version]}"

# Include the `curl` recipe, needed by `service status`
#
include_recipe "elasticsearch::curl"

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
remote_file "/tmp/elasticsearch-#{node.elasticsearch[:version]}.deb" do
  source "https://github.com/downloads/elasticsearch/elasticsearch/#{elasticsearch}.deb"
  action :create_if_missing
end

# Install ES
#
bash "Install Elasticsearch" do
  user "root"
  cwd  "/tmp"

  code <<-EOS
    sudo dpkg -i /tmp/#{elasticsearch}.tar.gz
  EOS
end

# Create ES config file
#
template "elasticsearch.yml" do
  path   "/etc/elasticsearch/elasticsearch.yml"
  source "elasticsearch.yml.erb"
  owner node.elasticsearch[:user] and group node.elasticsearch[:user] and mode 0755
end

# Create ES default file
#
template "elasticsearch" do
  path "/etc/default/elasticsearch"
  source "elasticsearch.default.erb"
  owner node.elasticsearch[:user] and group node.elasticsearch[:user] and mode 0755
end

# Add Monit configuration file
#
monitrc("elasticsearch", :pidfile => "#{node.elasticsearch[:pid_path]}/#{node.elasticsearch[:node_name].to_s.gsub(/\W/, '_')}.pid") \
  if node.recipes.include?('monit')
