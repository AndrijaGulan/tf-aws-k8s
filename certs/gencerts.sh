#!/bin/bash

KUBERNETES_PUBLIC_ADDRESS=$1

check_prereqs () {
    declare -a req_progs=("cfssl" "cfssljson")

    for prog in "${req_progs[@]}"
    do
        if ! which "${prog}" > /dev/null 2>&1; then
            echo "${prog} not installed. Please install it then rerun this script."
            exit 1
        fi
    done
}

gen_certs () {
	cfssl gencert -initca ca-csr.json | cfssljson -bare ca

	cfssl gencert \
	  -ca=ca.pem \
  	  -ca-key=ca-key.pem \
  	  -config=ca-config.json \
  	  -profile=kubernetes \
  	  admin-csr.json | cfssljson -bare admin
	
	cfssl gencert \
          -ca=ca.pem \
          -ca-key=ca-key.pem \
          -config=ca-config.json \
          -profile=kubernetes \
          kube-controller-manager-csr.json | cfssljson -bare kube-controller-manager

	cfssl gencert \
	  -ca=ca.pem \
	  -ca-key=ca-key.pem \
	  -config=ca-config.json \
	  -profile=kubernetes \
	  kube-proxy-csr.json | cfssljson -bare kube-proxy

	cfssl gencert \
	  -ca=ca.pem \
	  -ca-key=ca-key.pem \
	  -config=ca-config.json \
	  -profile=kubernetes \
	  kube-scheduler-csr.json | cfssljson -bare kube-scheduler

	cfssl gencert \
	  -ca=ca.pem \
	  -ca-key=ca-key.pem \
	  -config=ca-config.json \
	  -hostname=10.32.0.1,10.0.1.10,10.0.1.11,10.0.1.12,${KUBERNETES_PUBLIC_ADDRESS},127.0.0.1,kubernetes.default \
	  -profile=kubernetes \
	  kubernetes-csr.json | cfssljson -bare kubernetes

	cfssl gencert \
	  -ca=ca.pem \
	  -ca-key=ca-key.pem \
	  -config=ca-config.json \
	  -profile=kubernetes \
	  service-account-csr.json | cfssljson -bare service-account
}

echo $KUBERNETES_PUBLIC_ADDRESS
#check_prereqs
#gen_certs
