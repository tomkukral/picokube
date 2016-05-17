#!/bin/bash
watch "./bin/kubectl get no; echo -e '\nReplication controllers (rc)'; ./bin/kubectl get rc; echo -e '\nServices (svc)'; ./bin/kubectl get svc; echo -e '\nPersistent volumes (pv)'; ./bin/kubectl get pv; echo -e '\nPersistent volume claims (pvc)'; ./bin/kubectl get pvc; echo -e '\nPods (po)'; ./bin/kubectl get po -o wide"
