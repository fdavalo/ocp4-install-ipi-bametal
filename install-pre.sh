mkdir -p $IDIR

sudo virsh net-destroy $VIRT_NET
sudo virsh net-undefine $VIRT_NET

cat <<EOF > $IDIR/$VIRT_NET.xml
<network xmlns:dnsmasq='http://libvirt.org/schemas/network/dnsmasq/1.0'>
  <name>$VIRT_NET</name>
  <domain name='$CLUSTER_NAME.$BASE_DOM' localOnly='no'/>
  <bridge name='$VIRT_NET' stp='on' delay='0'/>
  <forward mode="nat"/>
  <dns>
    <host ip='$CLUSTER_SUBNET_BASE.2'>
      <hostname>api.$CLUSTER_NAME.$BASE_DOM</hostname>
      <hostname>api-int.$CLUSTER_NAME.$BASE_DOM</hostname>
    </host>
    <host ip='$CLUSTER_SUBNET_BASE.3'>
      <hostname>test.apps.$CLUSTER_NAME.$BASE_DOM</hostname>
    </host>
    <host ip='$PROV_SUBNET_BASE.11'>
      <hostname>master-1.$CLUSTER_NAME.$BASE_DOM</hostname>
    </host>
    <host ip='$PROV_SUBNET_BASE.12'>
      <hostname>master-2.$CLUSTER_NAME.$BASE_DOM</hostname>
    </host>
    <host ip='$PROV_SUBNET_BASE.13'>
      <hostname>master-3.$CLUSTER_NAME.$BASE_DOM</hostname>
    </host>
  </dns>
  <ip address='$CLUSTER_SUBNET_BASE.1' netmask='$CLUSTER_SUBNET_NETMASK'>
    <dhcp>
      <range start='$CLUSTER_SUBNET_BASE.9' end='$CLUSTER_SUBNET_BASE.254' />
      <host mac='$CLUSTER_MAC:21' ip='$CLUSTER_SUBNET_BASE.21' name='master-front-1.$CLUSTER_NAME.$BASE_DOM'/>
      <host mac='$CLUSTER_MAC:22' ip='$CLUSTER_SUBNET_BASE.22' name='master-front-2.$CLUSTER_NAME.$BASE_DOM'/>
      <host mac='$CLUSTER_MAC:23' ip='$CLUSTER_SUBNET_BASE.23' name='master-front-3.$CLUSTER_NAME.$BASE_DOM'/>
    </dhcp>
  </ip>
  <dnsmasq:options>
        <dnsmasq:option value='address=/apps.${CLUSTER_NAME}.${BASE_DOM}/$CLUSTER_SUBNET_BASE.3'/>
        <dnsmasq:option value='address=/api.${CLUSTER_NAME}.${BASE_DOM}/$CLUSTER_SUBNET_BASE.2'/>
        <dnsmasq:option value='address=/api-int.${CLUSTER_NAME}.${BASE_DOM}/$CLUSTER_SUBNET_BASE.2'/>
        <dnsmasq:option value='server=/fr/127.0.0.1'/>
        <dnsmasq:option value='server=/com/127.0.0.1'/>
        <dnsmasq:option value='server=/io/127.0.0.1'/>
  </dnsmasq:options>
</network>
EOF

sudo virsh net-define $IDIR/$VIRT_NET.xml
sudo virsh net-autostart $VIRT_NET
sudo virsh net-start $VIRT_NET

export CLUSTER_BRIDGE=`sudo virsh net-info $VIRT_NET | grep Bridge | awk '{print $2;}'`

sudo virsh net-destroy $PROV_NET
sudo virsh net-undefine $PROV_NET

cat <<EOF > $IDIR/$PROV_NET.xml
<network xmlns:dnsmasq='http://libvirt.org/schemas/network/dnsmasq/1.0'>
  <name>$PROV_NET</name>
  <bridge name='$PROV_NET' stp='on' delay='0'/>
  <dns>
    <host ip='$CLUSTER_SUBNET_BASE.2'>
      <hostname>api.$CLUSTER_NAME.$BASE_DOM</hostname>
      <hostname>api-int.$CLUSTER_NAME.$BASE_DOM</hostname>
    </host>
    <host ip='$CLUSTER_SUBNET_BASE.3'>
      <hostname>test.apps.$CLUSTER_NAME.$BASE_DOM</hostname>
    </host>
    <host ip='$PROV_SUBNET_BASE.11'>
      <hostname>master-1.$CLUSTER_NAME.$BASE_DOM</hostname>
    </host>
    <host ip='$PROV_SUBNET_BASE.12'>
      <hostname>master-2.$CLUSTER_NAME.$BASE_DOM</hostname>
    </host>
    <host ip='$PROV_SUBNET_BASE.13'>
      <hostname>master-3.$CLUSTER_NAME.$BASE_DOM</hostname>
    </host>
  </dns>
  <ip address='$PROV_SUBNET_BASE.1' netmask='$PROV_SUBNET_NETMASK'>
    <dhcp>
      <range start='$PROV_SUBNET_BASE.9' end='$PROV_SUBNET_BASE.254' />
      <host mac='$CLUSTER_MAC:11' ip='$PROV_SUBNET_BASE.11' name='master-1.$CLUSTER_NAME.$BASE_DOM'/>
      <host mac='$CLUSTER_MAC:12' ip='$PROV_SUBNET_BASE.12' name='master-2.$CLUSTER_NAME.$BASE_DOM'/>
      <host mac='$CLUSTER_MAC:13' ip='$PROV_SUBNET_BASE.13' name='master-3.$CLUSTER_NAME.$BASE_DOM'/>
      <bootp file='http://$PROV_SUBNET_BASE.2/boot.ipxe'/>
    </dhcp>
  </ip>
  <dnsmasq:options>
        <dnsmasq:option value='address=/apps.${CLUSTER_NAME}.${BASE_DOM}/$CLUSTER_SUBNET_BASE.3'/>
        <dnsmasq:option value='address=/api.${CLUSTER_NAME}.${BASE_DOM}/$CLUSTER_SUBNET_BASE.2'/>
        <dnsmasq:option value='address=/api-int.${CLUSTER_NAME}.${BASE_DOM}/$CLUSTER_SUBNET_BASE.2'/>
        <dnsmasq:option value='server=/fr/127.0.0.1'/>
        <dnsmasq:option value='server=/com/127.0.0.1'/>
        <dnsmasq:option value='server=/io/127.0.0.1'/>
  </dnsmasq:options>
</network>
EOF

sudo virsh net-define $IDIR/$PROV_NET.xml
sudo virsh net-autostart $PROV_NET
sudo virsh net-start $PROV_NET

mkdir -p $IMDIR

#add/update vip primary DNS settings
grep -v "$CLUSTER_SUBNET_BASE." /etc/hosts | grep -v "${CLUSTER_NAME}.${BASE_DOM}" > $IDIR/hosts
echo "$CLUSTER_SUBNET_BASE.2 api.${CLUSTER_NAME}.${BASE_DOM} api-int.${CLUSTER_NAME}.${BASE_DOM}" >> $IDIR/hosts
echo "$CLUSTER_SUBNET_BASE.3 oauth-openshift.apps.${CLUSTER_NAME}.${BASE_DOM} console-openshift-console.apps.${CLUSTER_NAME}.${BASE_DOM}" >> $IDIR/hosts

sudo cp /etc/hosts $IDIR/hosts.save
sudo cp $IDIR/hosts /etc/hosts

sudo systemctl reload NetworkManager
sudo systemctl restart libvirtd

sudo nmcli connection modify $PROV_NET ipv6.addresses fd00:1101::1/64 ipv6.method manual
