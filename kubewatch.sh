#!/bin/bash
watch "kubectl get no; echo -e '\nReplication controllers (rc)'; kubectl get rc; echo -e '\nServices (svc)'; kubectl get svc; echo -e '\nPersistent volumes (pv)'; kubectl get pv; echo -e '\nPersistent volume claims (pvc)'; kubectl get pvc; echo -e '\nPods (po)'; kubectl get po -o wide"
