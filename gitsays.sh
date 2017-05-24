#!/bin/bash
[[ $# -lt 1 ]] && echo -e "Atencao:\n\tForneca uma mensagem para o commit\n\nUsage: \n\t$0 Inserindo arquivos x, y e z\n" && exit 1
scp -rp root@192.168.56.110:/etc/puppetlabs/code/environments/production/ .
rm -rf  production/modules/dockeragent/.git
git add . -A
git commit . -m "$@"
