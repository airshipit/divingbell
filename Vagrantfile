# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
    config.vm.box = "generic/ubuntu1804"

    [:virtualbox, :parallels, :libvirt, :hyperv].each do |provider|
        config.vm.provider provider do |vplh, override|
            vplh.cpus = 4
            vplh.memory = 4096
        end
    end

    config.vm.synced_folder "./", "/root/deploy/airship-divingbell"

    config.vm.define "dbtest" do |node|
    node.vm.hostname = "dbtest"
    node.vm.provision :shell, inline: <<-SHELL
      #mkdir /root/deploy
      #git clone https://git.airshipit.org/airship-divingbell /root/deploy/airship-divingbell
      git clone https://git.openstack.org/openstack/openstack-helm-infra /root/deploy/openstack-helm-infra
      cd /root/deploy/openstack-helm-infra
      ./tools/gate/devel/start.sh full
      cd /root/deploy/airship-divingbell/
      ./tools/gate/scripts/010-build-charts.sh
      ./tools/gate/scripts/020-test-divingbell.sh
    SHELL
    end
end
