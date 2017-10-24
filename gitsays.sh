#!/bin/bash
hostIP="172.17.0.1"
[[ $# -lt 1 ]] && echo -e "Atencao:\n\tForneca uma mensagem para o commit\n\nUsage: \n\t$0 Inserindo arquivos x, y e z\n" && exit 1
scp -rp root@${hostIP}:/etc/puppetlabs/code/environments/production/modules/\{lamp,web_user,sshd,accounts,ntp,web,vimrc,cowsayings/}/ ./production/modules/
scp -rp root@${hostIP}:/etc/puppetlabs/code/environments/production/manifests/ ./production/
git add . -A
git commit . -m "$@"
git push -u origin master 2>/dev/null
