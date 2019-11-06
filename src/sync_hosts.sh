#!/bin/bash

NO_HOSTS_UPDATE=NO
while [[ $# > 0 ]]
do
  key="$1"

  case $key in
    -e|--exist-hosts)
      NO_HOSTS_UPDATE=YES
      ;;
    -h|--help)
      echo "Usage: sync_hosts.sh [-e|--exist-hosts]"
      exit
      ;;
    --default)
      DEFAULT=YES
      ;;
    *)
      ;;
  esac
  shift # past argument or value
done

if [ $NO_HOSTS_UPDATE == NO ]
then
  echo "Enter the string used to filter out your instances: "
  read -e grep_str
  res=`python ~/novahosts.py $grep_str 2>&1`
  if [[ $res ]]
  then
    echo $res
    echo "Fail to run novahosts.py"
    exit -1
  fi
  nins=`cat /dev/shm/hosts | wc -l`
  if [[ $nins == 0 ]]
  then
    echo No instance found
    exit
  fi
  echo "These are the instances:"
  cat /dev/shm/hosts
  while true
  do
    read -p "Are they correct? [yes/no] " correct
    case $correct in
      [Yy]* ) sudo sh -c "cat /dev/shm/hosts > /etc/hosts" && rm -f /dev/shm/hosts; break;;
      [Nn]* ) exit;;
      * ) echo "Please answer yes or no.";;
    esac
  done
fi
cat /etc/hosts | awk '{print $2}' | sort > ~/nodes

HOSTS=`cat /etc/hosts | grep -v ib | awk '{print $2}'`
IPS=`cat /etc/hosts | grep -v ib | awk '{print $1}'`

rm -f ~/.ssh/known_hosts
for host in $HOSTS
do
  ssh-keyscan -H $host >> ~/.ssh/known_hosts
done

for ip in $IPS
do
  ssh-keyscan -H $ip >> ~/.ssh/known_hosts
done

for host in $HOSTS
do
  echo "Copying to node $host ..."
  rsync -az /etc/hosts $host:/tmp/hosts &
  rsync -az ~/nodes $host:/home/cc/nodes &
  rsync -az ~/.ssh/* $host:/home/cc/.ssh/ &
  rsync -az ~/.bashrc $host:/home/cc/.bashrc &
  rsync -az ~/.bash_aliases $host:/home/cc/.bash_aliases &
done
wait

echo "Synchronizing ..."
if mpssh > /dev/null 2>&1
then
  mpssh -bf ~/nodes "sudo mv /tmp/hosts /etc/hosts" > /dev/null 2>&1
else
  for host in ${HOSTS[@]}
  do
    ssh $host "sudo mv /tmp/hosts /etc/hosts"
  done
fi

echo "Done"
