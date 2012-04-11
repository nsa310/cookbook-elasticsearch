# Load settings from data bag 'elasticsearch/settings' -
#
settings = Chef::DataBagItem.load('elasticsearch', 'settings') rescue {}

# === VERSION ===
#
default.elasticsearch[:version]   = "0.19.0"

# === PATHS ===
#
default.elasticsearch[:dir]       = "/home"
default.elasticsearch[:user]      = "elasticsearch"
default.elasticsearch[:conf_path] = "/home/elasticsearch-#{default.elasticsearch[:version]}/config"
default.elasticsearch[:data_path] = "/home/elasticsearch-#{default.elasticsearch[:version]}/data"
default.elasticsearch[:log_path]  = "/home/elasticsearch-#{default.elasticsearch[:version]}/logs"
default.elasticsearch[:pid_path]  = "/var/run/elasticsearch"

# === MEMORY ===
#
# Maximum amount of memory to use is automatically computed as 2/3 of total available memory.
# You may choose to configure it in your node configuration instead.
#
max_mem = "#{(node.memory.total.to_i - (node.memory.total.to_i/3) ) / 1024}m"
default.elasticsearch[:min_mem] = max_mem
default.elasticsearch[:max_mem] = max_mem

# === LIMITS ===
#
default.elasticsearch[:limits]  = {}
default.elasticsearch[:limits][:memlock] = 'unlimited'
default.elasticsearch[:limits][:nofile]  = '64000'

# === SETTINGS ===
#
default.elasticsearch[:node_name]      = node.name
default.elasticsearch[:cluster_name]   = ( settings['cluster_name'] || "elasticsearch" rescue "elasticsearch" )
default.elasticsearch[:index_shards]   = "5"
default.elasticsearch[:index_replicas] = "1"

# === PERSISTENCE ===
#
default.elasticsearch[:gateway][:type] = nil
