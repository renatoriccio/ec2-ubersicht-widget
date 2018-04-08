#! /bin/bash

export PATH=$PATH:/usr/local/bi
source ec2.widget/config

shell() {
    IP=`/usr/local/bin/aws ec2 describe-instances --instance-ids $1 --region $2  | grep PublicIpAddress | awk -F ":" '{print $2}' | sed 's/[",]//g'`
    url=`printf 'ec2-user@%s' $IP`
    osascript -e 'tell application "Terminal" to do script "ssh -i '${KEY_PATH}' '${url}'"'
}

"$@"
