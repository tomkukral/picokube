#!/bin/bash
watch "./bin/kubectl get no; ./bin/kubectl get pvc; ./bin/kubectl get all --all-namespaces"
