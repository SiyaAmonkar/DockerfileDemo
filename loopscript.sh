#!/bin/sh
OC_PASS=$1
OC_USER=$2
OC_CLUSTER=$3
ARGO_PROJECT=$4
SSH_KEY=$5
HOME=$6


echo $OC_PASS $OC_USER $OC_CLUSTER $ARGO_PROJECT $SSH_KEY $HOME
echo "$(echo -ne 'nameserver 9.3.89.109\n'; cat /etc/resolv.conf)" > /etc/resolv.conf
echo $OC_PASS | oc login -u $OC_USER $OC_CLUSTER -n $ARGO_PROJECT --insecure-skip-tls-verify=true
old_ci_commit_id=""
git config --global --add core.sshCommand 'ssh -i $SSH_KEY -o StrictHostKeyChecking=no'
cd $HOME
while true
do
# check change in commit ID's for ci repo
              
  git clone -b master --single-branch git@github.ibm.com:open-ce/ci.git --depth=1
  echo "cloning complete"
  cd ci && ci_commit_id=$(git log --format="%H" -n 1) 
  echo "current commit_id = " $ci_commit_id
  if [ $old_ci_commit_id = $ci_commit_id ]
  then
    echo "No new commits to ci"
    # send a slack notification
  else
    echo "Refresh templates and crons"
    bash scripts/refresh_template.sh
    bash scripts/refresh_cron.sh
    old_ci_commit_id=$ci_commit_id
    # send a slack notification
    #status=$(curl -X POST \
    #-H 'Content-type: application/json' \
    #--data '{"text":"Openshift cluster '$OC_CLUSTER' is now at commit github.ibm.com/open-ce/ci/commit/'$ci_commit_id' Templates and Cron Jobs Refreshed"}' \
    #https://hooks.slack.com/services/T0J9J1L92/B01Q679P9LM/$SLACK_TOKEN)
    #echo $status
    fi
    # Poll after 15 mins
    sleep 10
    # Delete old ci repo
    cd ../
    rm -rf ci
done


