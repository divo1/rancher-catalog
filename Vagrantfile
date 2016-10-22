Vagrant.configure(2) do |config|
  config.vm.box = "debian/jessie64"
  config.vm.synced_folder ".", "/var/www/project"

  $script = <<-SCRIPT
    curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -
    apt-get install -y build-essential
    apt-get update
    apt-get install -y nodejs git
    apt-get install -y npm
    npm install -y -g n
    n latest
    cd /var/www/project/
    git clone https://github.com/Slashgear/generator-rancher-catalog.git
    cd /var/www/project/generator-rancher-catalog && npm install yo
    cd /var/www/project/generator-rancher-catalog && npm install -g generator-rancher-catalog
  SCRIPT

  config.vm.provision "shell", inline: $script, privileged: true
end
