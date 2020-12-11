#!/bin/bash

external_ip=$1
internal_ip=$2
i=$3
instance_hostname="ip-10-0-1-2${i}"

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -hostname=${instance_hostname},${external_ip},${internal_ip} \
  -profile=kubernetes \
  worker-${i}-csr.json | cfssljson -bare worker-${i}
