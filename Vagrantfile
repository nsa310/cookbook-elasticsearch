Vagrant::Config.run do |config|
  config.vm.box       = 'lucid64'
  config.vm.box_url   = 'http://files.vagrantup.com/lucid64.box'

  config.vm.customize do |vm|
    vm.name        = 'elasticsearch'
    vm.memory_size = 1024
  end

  config.vm.network :bridged, '33.33.33.10'

  config.vm.provision :chef_solo do |chef|

    chef.cookbooks_path    = [ File.expand_path('../..', __FILE__),
                               File.expand_path('../tmp/cookbooks', __FILE__),
                               "#{ENV['HOME']}/cookbooks" ]
    chef.provisioning_path = '/etc/vagrant-chef'
    chef.log_level         = :debug

    chef.run_list = %w| apt
                        java
                        vim
                        nginx
                        monit
                        elasticsearch
                        elasticsearch::proxy_nginx
                        elasticsearch::plugin_aws
                        elasticsearch::test |

    chef.json = {
      elasticsearch: {
        cluster_name: "elasticsearch_vagrant",

        limits: {
          nofile:  1024,
          memlock: 512
        },

        nginx: {
          users: [{
            username: 'USERNAME',
            password: 'PASSWORD'
          }]
        }
      }
    }

  end
end
