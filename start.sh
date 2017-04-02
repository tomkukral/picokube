#!/bin/bash

for i in {proxy,controller-manager,scheduler,apiserver}; do
	docker stop k8s.$i
	docker rm k8s.$i
done

docker stop etcd
docker rm etcd
docker rm data_etcd

echo "Sleep before start"
sleep 3

./etcd.sh

for i in {apiserver,controller-manager,scheduler,proxy}; do
	./kubernetes.sh $i
done
