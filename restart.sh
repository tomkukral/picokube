#!/bin/bash

for i in {kubelet,proxy,controller-manager,scheduler,apiserver}; do
	docker stop k8s.$i
	docker rm k8s.$i
done

docker stop etcd
docker rm data_etcd

echo "Sleep before start"
sleep 3

./etcd.sh

for i in {apiserver,controller-manager,scheduler,kubelet,proxy}; do
	./kubernetes.sh $i
done

sleep 2

./bin/kubectl create -f conf/nginx-rc.yml
./bin/kubectl create -f conf/nginx-svc.yml
