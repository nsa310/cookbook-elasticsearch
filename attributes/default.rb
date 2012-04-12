# Load settings from data bag 'elasticsearch/settings' -
#
settings = Chef::DataBagItem.load('elasticsearch', 'settings') rescue {}

# === VERSION ===
#
default.elasticsearch[:version]   = "0.19.2"

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
