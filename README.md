# ocp4-install-ipi-bametal
Install Openshift 4 using IPI Bare Metal installer on your PC 

Pre-requisites
--------------

* A VM with RHEL where you can run those scripts and create your cluster and vms.
* You can also use vms from differents hosts (vbmc allows adding remote vms from remote hosts), but you will have to extand your network configs.

* You need to install libvirtd, .... and ipmitools (rpms).
* You also need to install Virtual BMC (pip3) : https://github.com/openstack/virtualbmc

Configuration
-------------

Edit install-env.sh to adapt some parameters (directories, where qemu images are stored, choose your vlan, ...)

Installation
------------

* Source install-env.sh
* Run install-pre.sh (creates libvirt networks).
* Run install-vms.sh (creates master vms and add them to vbmc).
* Run install-cluster.sh (generates intall-config.yaml for baremetal installer and launch the install).

Steps
-----

* The baremetal installer is going to create a bootstrap VM.
* The bootstrap VM will ignite the cluster with an etcd instance and kubernetes api server.
* The bootstrap VM will also start ironic to manage the setup of master vms.
* Ironic will use ipmitools to power On the master VM.
* The master VM will boot on ipxe url handled by ironic/dnsmasq on bootstrap VM.
* The master VM will download CoreOS images and reboot when done.
* The master VM will first boot on hd and start coreOS ignition (downloading operators and settings), then reboot when done.
* The master VM will boot normally on hd and start kubelet + operators (network, api, etcd, ...).
* The bootstrap VM will keep the cluster API until one master node will re-claim the IP when its API operator will be ready.
* When all master nodes are ready, bootstrap VM will be destroyed by the baremetal installer.

Potential issues
----------------

* Ironic starts all the master vm at the same time, and sometimes, your hosts could be overloaded and a node pxe boot could timeout :

  * * watch out and restart the vm

* When a node is starting (after the two reboot), if your hosts is overloaded, a node can have timeout during dhcp/garp exchanges and could not see the bootstrap node using the API IP and could start the API IP on the master node even when it is not ready yet and this could break the cluster setup : 

  * * if needed, on master node, crictl exec on keepalived container and add bootstrap peer ip on config and kill -HUP on keepalived pids






