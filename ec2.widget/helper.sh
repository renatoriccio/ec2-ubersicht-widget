#! /bin/bash

export PATH=$PATH:/usr/local/bi
source ec2.widget/config

shell() {
    IP=`/usr/local/bin/aws ec2 describe-instances --instance-ids $1 --region $2  | grep PublicIpAddress | awk -F ":" '{print $2}' | sed 's/[",]//g'`

    USER_STR=`/usr/local/bin/aws ec2 describe-instances --instance-ids $1 --region $2 --query Reservations[*].Instances[].Tags --output=text | grep -i "^user\t"`
    if [ $? -eq 0 ]
    then
       USER=`echo $USER_STR | cut -d " " -f2`
    fi

    url=`printf '%s@%s' $USER $IP`

    osascript -e 'tell application "Terminal" to do script "ssh -i '${KEY_PATH}' '${url}'"'
}

"$@"
