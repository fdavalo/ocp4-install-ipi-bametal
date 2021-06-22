export ODIR=/home/fdavalo/home/baremetal/cluster
export EDIR=/home/fdavalo
export PATH=$PATH:$ODIR
export BASE_DOM=cluster
export CLUSTER_OCTET=102
export CLUSTER_NAME=ocp4-$CLUSTER_OCTET
export SSH_KEY="/home/fdavalo/.ssh/id_rsa.pub"
export PULL_SEC=$(cat $ODIR/crc-pull-secret)

#host to guests isolated network
export VIRT_NET="ocp4$CLUSTER_OCTET"
export PROV_NET="prov$CLUSTER_OCTET"

export CLUSTER_SUBNET=192.168.$CLUSTER_OCTET.0
export PROV_SUBNET=192.169.$CLUSTER_OCTET.0
export CLUSTER_SUBNET_BASE=`echo $CLUSTER_SUBNET | awk -F\. '{print $1"."$2"."$3;}'`
export PROV_SUBNET_BASE=`echo $PROV_SUBNET | awk -F\. '{print $1"."$2"."$3;}'`
export CLUSTER_SUBNET_NETMASK=255.255.255.0
export PROV_SUBNET_NETMASK=255.255.255.0
export CLUSTER_MAC=52:$(echo $CLUSTER_OCTET | od -x | awk '{print substr($2,1,2)":"substr($2,3,2)":"substr($3,1,2)":"substr($3,3,2);}' | head -1)
export PROV_MAC=50:$(echo $CLUSTER_OCTET | od -x | awk '{print substr($2,1,2)":"substr($2,3,2)":"substr($3,1,2)":"substr($3,3,2);}' | head -1)

export IDIR=install_dir_$CLUSTER_NAME
export IMDIR=$IDIR/images

export CLUSTER_OCP_VERSION=4.7
export CLUSTER_OCP_VERSION_MINOR=4.7.9

export VERSION=latest-$CLUSTER_OCP_VERSION
export RELEASE_IMAGE=$(curl -s https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$VERSION/release.txt | grep 'Pull From: quay.io' | awk -F ' ' '{print $3}')

export BMCUSER=bmc
export BMCPASS=bmc2ocp$
export INTERNET_GATEWAY=192.168.0.254
