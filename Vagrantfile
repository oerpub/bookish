Vagrant.configure("2") do |config|
    config.vm.box = "precise64"
    config.vm.box_url = "http://files.vagrantup.com/precise32.box"
    config.vm.synced_folder "./", "/vagrant"
    config.vm.provision :shell, :path => "node-bootstrap.sh"
    config.vm.network :private_network, ip: '33.33.33.10'

    config.vm.provider :virtualbox do |vb|
        vb.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/v-root", "1"]
        # vb.customize ["modifyvm", :id, "--memory", "2048"]
        # vb.customize ["modifyvm", :id, "--cpus", "4"]
    end
end

