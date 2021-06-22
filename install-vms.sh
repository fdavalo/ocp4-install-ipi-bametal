rm -f ~/.vbmc/master.pid
vbmcd

sudo iptables -L LIBVIRT_INP -n -v > $IDIR/iptables

for ind in 1 2 3; do
	vbmc delete ${CLUSTER_NAME}-master-$ind

	sudo virt-install --name ${CLUSTER_NAME}-master-$ind \
  --pxe \
  --boot network \
  --disk size=30,path=$IMDIR/${CLUSTER_NAME}-master-$ind.qcow2,bus=scsi --ram 14000 --cpu host --vcpus 4 \
  --os-type linux --os-variant rhel7 \
  --network network=${PROV_NET},model=virtio,mac=$CLUSTER_MAC:1$ind \
  --network network=${VIRT_NET},model=virtio,mac=$CLUSTER_MAC:2$ind \
  --noreboot --noautoconsole &

    sleep 10

	vbmc add ${CLUSTER_NAME}-master-$ind --username $BMCUSER --password $BMCPASS --port ${CLUSTER_OCTET}1$ind --address $CLUSTER_SUBNET_BASE.1
	vbmc start ${CLUSTER_NAME}-master-$ind
    ipmitool -I lanplus -U $BMCUSER -P $BMCPASS -H $CLUSTER_SUBNET_BASE.1 -p ${CLUSTER_OCTET}1$ind power off

	if [[ $(grep udp $IDIR/iptables | grep $VIRT_NET | grep :${CLUSTER_OCTET}1$ind | wc -l) -eq 0 ]]; then
		sudo iptables -I LIBVIRT_INP -p udp -i $VIRT_NET --dport ${CLUSTER_OCTET}1$ind -j ACCEPT
	fi
done

if [[ 1 ]]; then exit 0; fi

vbmc delete ${CLUSTER_NAME}-worker-1

sudo virt-install --name ${CLUSTER_NAME}-worker-1 \
  --pxe \
  --boot network \
  --disk size=30,path=$IMDIR/${CLUSTER_NAME}-worker-1.qcow2,bus=scsi --ram 8192 --cpu host --vcpus 2 \
  --os-type linux --os-variant rhel7 \
  --network network=${VIRT_NET},model=virtio,mac=$CLUSTER_MAC:08 \
  --network network=${PROV_NET},model=virtio \
  --noreboot

vbmc add ${CLUSTER_NAME}-worker-1 --username $BMCUSER --password $BMCPASS --port 1${CLUSTER_OCTET}8 --address $CLUSTER_SUBNET_BASE.1
vbmc start ${CLUSTER_NAME}-worker-1

#sudo iptables -I LIBVIRT_INP -p udp -i $VIRT_NET --dport 1${CLUSTER_OCTET}8 -j ACCEPT

