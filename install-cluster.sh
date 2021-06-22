export VERSION=latest-$CLUSTER_OCP_VERSION
if [[ ! -f oc-$VERSION ]]; then
	export RELEASE_IMAGE=$(curl -s https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$VERSION/release.txt | grep 'Pull From: quay.io' | awk -F ' ' '{print $3}')
	curl -s https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$VERSION/openshift-client-linux.tar.gz | tar zxvf - oc
	mv oc oc-$VERSION
fi
export cmd=openshift-baremetal-install
export pullsecret_file=$ODIR/crc-pull-secret
export extract_dir=$(pwd)

if [[ ! -f openshift-baremetal-install-$VERSION ]]; then
	./oc-$VERSION adm release extract --registry-config "${pullsecret_file}" --command=$cmd --to "${extract_dir}" ${RELEASE_IMAGE}
	mv openshift-baremetal-install openshift-baremetal-install-$VERSION
fi

if [[ ! -f $IDIR/install-config.yaml ]]; then
        cat <<EOF > $IDIR/install-config.yaml
apiVersion: v1
baseDomain: ${BASE_DOM} 
metadata:
  name: ${CLUSTER_NAME} 
networking:
  #clusterNetworks:
  #- cidr: 10.128.0.0/14
  #  hostPrefix: 23
  #networkType: OpenShiftSDN
  #serviceNetwork:
  #- 172.30.0.0/16
  machineCIDR: $CLUSTER_SUBNET/24 
  networkType: OVNKubernetes
compute:
- name: worker
  replicas: 0 
controlPlane:
  name: master
  replicas: 3 
  platform:
    baremetal: {}
platform:
  baremetal:
    apiVIP: $CLUSTER_SUBNET_BASE.2 
    ingressVIP: $CLUSTER_SUBNET_BASE.3 
    bootstrapProvisioningIP: $PROV_SUBNET_BASE.4
    clusterProvisioningIP: $PROV_SUBNET_BASE.5
    provisioningNetworkInterface: ens3
    provisioningBridge: $PROV_NET 
    provisioningNetworkCIDR: $PROV_SUBNET/24 
    #provisioningNetwork:  
    externalBridge: $VIRT_NET 
    hosts:
      - name: master-1
        role: master
        bmc:
          address: ipmi://$CLUSTER_SUBNET_BASE.1:${CLUSTER_OCTET}11
          username: $BMCUSER 
          password: $BMCPASS 
        bootMACAddress: $CLUSTER_MAC:11
        hardwareProfile: default
      - name: master-2
        role: master
        bmc:
          address: ipmi://$CLUSTER_SUBNET_BASE.1:${CLUSTER_OCTET}12
          username: $BMCUSER
          password: $BMCPASS
        bootMACAddress: $CLUSTER_MAC:12
        hardwareProfile: default
      - name: master-3
        role: master
        bmc:
          address: ipmi://$CLUSTER_SUBNET_BASE.1:${CLUSTER_OCTET}13
          username: $BMCUSER
          password: $BMCPASS
        bootMACAddress: $CLUSTER_MAC:13
        hardwareProfile: default
pullSecret: '${PULL_SEC}'
sshKey: '$(cat $SSH_KEY)'
EOF
	cp $IDIR/install-config.yaml $IDIR/install-config.yaml.save
    ./openshift-baremetal-install-$VERSION --dir=./$IDIR create manifests
fi

cat <<EOF > $IDIR/router-replicas.yaml
apiVersion: operator.openshift.io/v1
kind: IngressController
metadata:
  name: default
  namespace: openshift-ingress-operator
spec:
  replicas: 1
  endpointPublishingStrategy:
    type: HostNetwork
  nodePlacement:
    nodeSelector:
      matchLabels:
        node-role.kubernetes.io/worker: ""
EOF

#cp $IDIR/router-replicas.yaml $IDIR/openshift/99_router-replicas.yaml

./openshift-baremetal-install-$VERSION --dir=./$IDIR --log-level debug create cluster
#./openshift-baremetal-install-$VERSION --dir=./$IDIR --log-level debug wait-for bootstrap-complete

#iptables -I LIBVIRT_INP -i ocp4201 -d 224.0.0.0/8 -p vrrp -j ACCEPT
#iptables -I LIBVIRT_OUT -o ocp4201 -d 224.0.0.0/8 -p vrrp -j ACCEPT

