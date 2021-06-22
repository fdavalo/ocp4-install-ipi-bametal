sudo virsh net-destroy $VIRT_NET
sudo virsh net-undefine $VIRT_NET
sudo virsh net-destroy $PROV_NET
sudo virsh net-undefine $PROV_NET
rm -rf $ODIR/$IDIR/auth/ $ODIR/$IDIR/tls/ $ODIR/$IDIR/metadata.json $ODIR/$IDIR/terraform* $ODIR/$IDIR/.openshift_install*
sudo rm -rf /var/lib/libvirt/openshift-images/ocp4*

