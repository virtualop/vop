# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.hostname = 'vop.foo.net'

  config.vm.box = "ubuntu1404"
  config.vm.synced_folder ".", "/vagrant", type: "nfs"

  config.vm.provider ENV['VAGRANT_DEFAULT_PROVIDER'].to_sym do |domain|
    domain.memory = 512
    domain.cpus = 1
  end

  #config.vm.network "forwarded_port", guest: 3000, host: 3001

  config.ssh.forward_agent = true

  # install chef
  #if Vagrant.has_plugin?("vagrant-omnibus")
  #    config.omnibus.chef_version = 'latest'
  #end

  # install dependencies
  config.berkshelf.enabled = false

  # provision from cookbooks
  config.vm.provision "chef_zero" do |chef|
    chef.synced_folder_type = "nfs"
    chef.cookbooks_path = "cookbooks"
    #chef.data_bags_path = "data_bags"
    #chef.roles_path = "roles"

    # Add a recipe
    chef.add_recipe "vop::default"
  end
end
