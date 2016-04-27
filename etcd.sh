#!/bin/bash

# create data_etcd
docker ps -a | grep data_etcd || docker create -v /var/etcd/data --name data_etcd tomkukral/gentoo-etcd /bin/true


# remove etcd
docker rm etcd

docker run \
	--name etcd \
	--detach \
	--restart always \
	--net host \
	--volumes-from data_etcd \
	tomkukral/gentoo-etcd etcd \
		--name {{kube_nodes[inventory_hostname].id}} \
		--data-dir /var/etcd/data \
		--advertise-client-urls http://127.0.0.1:4001 \
		--listen-client-urls http://127.0.0.1:4001 \
		--listen-peer-urls http://{{ ansible_dbr0.ipv4.address }}:4000 \
		--initial-advertise-peer-urls http://{{ ansible_dbr0.ipv4.address }}:4000 \
		--initial-cluster-token etcd-cluster-1 \
		--initial-cluster 0=http://172.17.0.1:4000,1=http://172.17.1.1:4000,2=http://172.17.2.1:4000 \
		--initial-cluster-state existing
