#!/bin/bash

# config
MASTER="127.0.0.1"
NODEIP="127.0.0.1"
SERVICERANGE="172.18.0.0/24"

NAME="k8s.$1"
IMAGE="gcr.io/google_containers/hyperkube-amd64:v1.6.0"
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

"get-binary")
	[ ! -d bin ] && mkdir bin

	docker run --rm -ti \
		-v $PWD/bin/:/tmp/bin/ \
		--entrypoint cp $IMAGE \
		-- /hyperkube /tmp/bin/

	./bin/hyperkube --version
	ln -vs hyperkube ./bin/kubectl
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
			--insecure-bind-address=0.0.0.0 \
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

	echo "WARNING: kubelet in container is very experimental as will probable fail. Use kubelet-bare to get working enviroment."

	remove_container "$NAME"

	docker run \
		--name "$NAME" \
		--detach \
		--restart $RESTART \
		--net host \
		--privileged \
    		--volume /var/run:/var/run:rw \
		--volume /var/lib/docker:/var/lib/docker:rw \
		--volume /var/lib/kubelet:/var/lib/kubelet:rw \
    		--volume /sys:/sys:ro \
		$IMAGE /hyperkube kubelet \
			--api_servers=http://$MASTER:8080 \
			--address=$NODEIP \
			--enable-server \
			--v=2 \
			--node-ip 127.0.0.1
	;;

"kubelet-bare")
	echo "preparing to run bare $NAME"

	if [ ! -x "./bin/hyperkube" ]; then
		echo "./bin/hyperkube is missing or not executable"
		echo "Please run ./kubernetes.sh get-binary because hyperkube binary is required to run kubelet-bare"
		exit 1
	fi

	NODE_IP="$2"

	if [ "$NODE_IP" == "" ]; then
		echo "NODE_IP is missing"
		exit 1
	fi

	./bin/hyperkube kubelet \
			--api_servers=http://$MASTER:8080 \
			--hostname-override $NODE_IP
			--address=0.0.0.0 \
			--node-ip $NODE_IP \
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
	echo "available: apiserver, controller-manager, scheduler, kubelet, proxy, pull-only, get-binary"
	;;
esac
