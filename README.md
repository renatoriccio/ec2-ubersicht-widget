# ec2-Übersicht-widget
EC2 Übersicht Widget, allows to start/stop/terminate/shell EC2 instances

## Prerequisite

Install and configure [AWS Command Line Interface](https://aws.amazon.com/cli/)

## Configuration
Copy `ec2-widget` folder into Übersicht widget folder, then create a `config` file based on the `config_sample`.

### config file content
```
NAME=JohnDoe
OWNER=john.doe
REGION=eu-west-1
KEY_PATH=/home/.ssh/johndoe.pem
USER=ec2-user
```

###### NAME
Filter on the EC2 instance name

###### OWNER
Filter on a EC2 tag `owner`

###### REGION
Filter on EC2 region

###### REGION
Path to the local AWS pem file

###### USER
Default user used for logging into EC2 instances, this parameter can be overwritten defining an `user` tag on a specific EC2
