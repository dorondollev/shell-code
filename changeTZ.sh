#!/bin/sh

MYTZ=America/New_York
#MYTZ=Asia/Jerusalem
ENV=`env | grep "OVERRIDE_TZ_EST=1"`
if [ $? -eq 0 ]
then
        TZ=EST
        echo "TZ=$TZ" >> /etc/profile
        echo "export TZ" >> /etc/profile
        exit 0
fi
RELEASE=`grep ^ID /etc/os-release`
if [[ $RELEASE =~ centos ]] || [[ $RELEASE =~ fedora ]]
then
        echo "Release is centos or fedora"
        rm -f /etc/localtime
        ln -s /usr/share/zoneinfo/America/New_York /etc/localtime
        #ln -s /usr/share/zoneinfo/Asia/Jerusalem /etc/localtime
        readlink /etc/localtime
elif [[ $RELEASE =~ ubuntu ]]
then
        echo "Release is Ubuntu"
        apt-get install -yq tzdata
        ln -fs /usr/share/zoneinfo/America/New_York /etc/localtime
        dpkg-reconfigure -f noninteractive tzdata
elif [[ $RELEASE =~ alpine ]]
then
        echo "Release is Alpine"
        apk add --no-cache tzdata
else
        echo "None of the above releases is on this machine"
fi

TZ=$MYTZ
echo "TZ=$TZ" >> /etc/profile
echo "export TZ" >> /etc/profile
