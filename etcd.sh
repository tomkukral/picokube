#!/bin/bash

# https://coreos.com/etcd/docs/latest/clustering.html#static
# https://coreos.com/etcd/docs/latest/docker_guide.html

ETCD_IMAGE="quay.io/coreos/etcd:v3.1.2"
ETCD_NAME="0"
ETCD_LISTEN_IP="0.0.0.0"
ETCD_ADVERTISE_IP="127.0.0.1"

if [ "$1" == "pull-only" ]; then
	docker pull "$ETCD_IMAGE"
	exit 0
fi

if [ "$1" == "get-binary" ]; then
	[ ! -d bin ] && mkdir bin
	docker run --rm -ti \
		-v $PWD/bin/:/tmp/bin/ \
		--entrypoint cp $ETCD_IMAGE \
		-- /usr/local/bin/{etcd,etcdctl} /tmp/bin/
	./bin/etcd --version
	./bin/etcdctl --version
	exit 0
fi

# create data container
docker ps -a | grep data_etcd || docker create -v /var/etcd/data --name data_etcd $ETCD_IMAGE /bin/true

# remove etcd
docker stop etcd && docker rm etcd

# start etcd
docker run \
	--name etcd \
	--detach \
	--restart always \
	--volumes-from data_etcd \
	-p 2380:2380 \
	-p 4001:4001 \
	$ETCD_IMAGE etcd \
	--name "$ETCD_NAME" \
	--data-dir /var/etcd/data \
	--advertise-client-urls http://${ETCD_ADVERTISE_IP}:4001 \
	--listen-client-urls http://${ETCD_LISTEN_IP}:4001 \
	--listen-peer-urls http://${ETCD_LISTEN_IP}:2380 \
	--initial-advertise-peer-urls http://${ETCD_ADVERTISE_IP}:2380 \
	--initial-cluster-token etcd-cluster-1 \
	--initial-cluster ${ETCD_NAME}=http://${ETCD_ADVERTISE_IP}:2380 \
	--initial-cluster-state new
