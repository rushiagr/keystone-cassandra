sudo apt-get -y install git

git clone https://github.com/openstack-dev/devstack

cd devstack

cat > local.conf << EOF
[[local|localrc]]
ADMIN_PASSWORD=nova
DATABASE_PASSWORD=nova
RABBIT_PASSWORD=nova
SERVICE_PASSWORD=nova
SERVICE_TOKEN=s0m3-r4nd0m-53rv1c3-t0k3n

ENABLED_SERVICES=key,mysql,tempest

HOST_IP=127.0.0.1

KEYSTONE_REPO=https://github.com/rushiagr/keystone.git
KEYSTONE_BRANCH=liberty-cassandra-base-master

EOF

./stack.sh

cd ..

sudo apt-get install -y git python-dev libyaml-dev libpython2.7-dev openjdk-7-jdk ant

sudo update-alternatives --set java /usr/lib/jvm/java-7-openjdk-amd64/jre/bin/java

sudo pip install cql pyyaml psutil

git clone https://github.com/pcmanus/ccm.git

cd ccm

sudo python setup.py install

ccm create --version 2.1.9 --nodes 5 --start test

cd /opt/stack/keystone

git checkout -b liberty-cassandra origin/liberty-cassandra

cp others/keystone.conf.cassandra /etc/keystone/keystone.conf

ccm node1 cqlsh -f others/prerun.cql
ccm node1 cqlsh -f others/table-creation.cql
ccm node1 cqlsh -f others/keystonedbdump.cql

sudo apt-get install build-essential python-dev libev4 libev-dev

# HACK: installing cassandra-driver pip package will fail with some setuptools
# error. This is because devstack uses a custom version of pip. Here we will
# install Ubuntu's pip, and then remove it. We need to do this so that we
# install packages which are required to fix the setuptools error. These
# packages are dependencies of pip, so these will get installed when we install
# Ubuntu's pip. But ubuntu's pip conflicts with devstack's pip (on pip package
# 'six'). So we remove Ubuntu's pip (NOT 'remove --purge'), and leave the other
# dependencies of Ubuntu's pip as it is.
# TODO(rushiagr): Don't use this workaround and only install that one Ubuntu
# package which fixes this issue. python-setuptools?
sudo apt-get install python-pip
sudo apt-get remove python-pip python-six

sudo pip install cassandra-driver=2.5.1
sudo pip install blist

sudo python setup.py install

sudo service apache2 restart

cd ..
source devstack/openrc

keystone token-get
