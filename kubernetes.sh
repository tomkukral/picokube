#!/bin/bash

# config
MASTER="127.0.0.1"
NODEIP="127.0.0.1"
SERVICERANGE="172.18.0.0/24"

NAME="k8s.$1"
IMAGE="gcr.io/google_containers/hyperkube-amd64:v1.2.3"
ETCD_SERVERS="http://127.0.0.1:4001"

RESTART="no"

## functions
remove_container () {
	if docker ps -a | grep "$NAME" > /dev/null; then
		docker stop "$NAME"
		docker rm "$NAME" && echo "old $NAME container removed"
	fi
}

case "$1" in
"pull-only")
	docker pull "$IMAGE"
	;;

"apiserver")
	echo "preparing to run container $NAME"

	remove_container "$NAME"

	docker run \
		--name "$NAME" \
		--detach \
		--restart $RESTART \
		--net host \
		$IMAGE /hyperkube apiserver \
			--insecure-bind-address=$MASTER \
			--external-hostname=$MASTER \
			--bind-address=$MASTER \
			--secure-port=0 \
			--etcd-servers=$ETCD_SERVERS \
			--service-cluster-ip-range=$SERVICERANGE \
			--v=2
	;;

"controller-manager")
	echo "preparing to run container $NAME"

	remove_container "$NAME"

	docker run \
		--name "$NAME" \
		--detach \
		--restart $RESTART \
		--net host \
		$IMAGE /hyperkube controller-manager \
			--master=$MASTER:8080 \
			--v=2
	;;

"scheduler")
	echo "preparing to run container $NAME"

	remove_container "$NAME"

	docker run \
		--name "$NAME" \
		--detach \
		--restart $RESTART \
		--net host \
		$IMAGE /hyperkube scheduler \
			--master=$MASTER:8080 \
			--v=2
	;;

"kubelet")
	echo "preparing to run container $NAME"

	remove_container "$NAME"

	docker run \
		--name "$NAME" \
		--detach \
		--restart $RESTART \
		--net host \
		--privileged \
		--volume /var/run/docker.sock:/var/run/docker.sock \
		$IMAGE /hyperkube kubelet \
			--api_servers=http://$MASTER:8080 \
			--address=$NODEIP \
			--enable-server \
			--v=2
	;;

"kubelet-bare")
	echo "preparing to run bare $NAME"

	hyperkube kubelet \
			--api_servers=http://$MASTER:8080 \
			--address=0.0.0.0 \
			--enable-server \
			--v=2
	;;

"proxy")
	echo "preparing to run container $NAME"

	remove_container "$NAME"

	docker run \
		--name "$NAME" \
		--detach \
		--restart $RESTART \
		--net host \
		--privileged \
		$IMAGE /hyperkube proxy \
			--bind-address=$NODEIP \
			--master=$MASTER:8080 \
			--v=2
	;;
*)
	echo "unknown component $1"
	echo "available: apiserver, controller-manager, scheduler, kubelet, proxy, pull-only"
	;;
esac
