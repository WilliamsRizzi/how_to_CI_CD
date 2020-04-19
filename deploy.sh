#!/bin/bash
set -o nounset
set -o errexit

# Unlock SSH private key using TRAVIS automatic encryption
# See https://docs.travis-ci.com/user/encrypting-files/#automated-encryption
# the following is the line the script will tell you to cutNpaste in your CD pipeline
#### VARIABLES EXPLANATION
## encrypted_<ID>_key ==> is the environment variable of the key contained in TravisCI
## encrypted_<ID>_iv  ==> is the environment variable of the key contained in TravisCI
## cloud.key.enc ==> is the name of the encripted key you committed to your git repository
## cloud.key ==> is the name of the decripted key that TravisCI will use to push on the deployment server the new image
openssl aes-256-cbc -K ${encrypted_<ID>_key} -iv ${encrypted_<ID>_iv} -in cloud.key.enc -out ./cloud.key -d

eval "$(ssh-agent -s)"
chmod 600 ./cloud.key
echo -e "Host ${SERVER_IP}\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config
ssh-add ./cloud.key

# Open SSH tunnel to forward remote Docker socket to local docker.sock file
# SSH is put in control-socket mode, to close the connection when we have finished
#### VARIABLES EXPLANATION
## SERVER_USER ==> is the environment vairable of the name of the user of the deployment server in TravisCI
## SERVER_IP ==> is the environment vairable of the name of the IP of the deployment server in TravisCI
ssh -M -S my-ctrl-socket -fnNT -o ExitOnForwardFailure=yes -L /tmp/docker.sock:/var/run/docker.sock ${SERVER_USER}@${SERVER_IP}

# Tell docker-compose to use the remote socket to talk to the Docker daemon on the server
export DOCKER_HOST=unix:///tmp/docker.sock

docker-compose pull

# Start up the new containers
docker-compose up --detach --force-recreate server

# Close the SSH connection using the control socket opened previously
#### VARIABLES EXPLANATION
## SERVER_USER ==> is the environment vairable of the name of the user of the deployment server in TravisCI
## SERVER_IP ==> is the environment vairable of the name of the IP of the deployment server in TravisCI
ssh -S my-ctrl-socket -O exit ${SERVER_USER}@${SERVER_IP}
