#!/bin/bash

sudo systemctl status iptables &> /dev/null

if [ $? = 0 ]
then
echo "The iptables service is working fine"
echo "You can add rules now"
echo "Enter source IP(Network or single IP)"
read src
echo "Enter destination website or IP"
read dst
echo "Specify destination port"
read dstp
echo "Enter protocol"
read proto
echo "Enter target/action"
read target

echo "Adding Command"
sudo iptables -I FORWARD 1 -p $proto -s $src -d $dst --dport $dstp -j $target
sudo iptables -I FORWARD 2 -p $proto -s $dst -d $src --sport $dstp -j $target

echo "The rules are added successfuly"
else
echo "iptables servive is down"
fi