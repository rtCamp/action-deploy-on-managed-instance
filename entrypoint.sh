#!/usr/bin/env bash

#================================================================#
#                    Node and NPM Setup                          #
#================================================================#

# Installing NVM
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

# Installing NPM Latest Version

if [ -z "$NPM_VERSION" ]
then
    
    NPM_VERSION="latest"
    export npm_install=$NPM_VERSION
    curl -L https://www.npmjs.com/install.sh | sh > /dev/null 2>&1

else
    
    export npm_install=$NPM_VERSION
    curl -L https://www.npmjs.com/install.sh | sh > /dev/null 2>&1

fi
    
# Installing Specified version of Node.js
if [ -z "$NODE_VERSION" ]
then
    
    NODE_VERSION=latest
    nvm install node

else
    
    # Installing Specified version of Node.js
    echo "Installing Specified version of Node.js"
    nvm install $NODE_VERSION

    # Switching to specified version of Node.js
    echo "Switching to specified version of Node.js"
    nvm use $NODE_VERSION

fi

#================================================================#
#                    Build Dir and command                       #
#================================================================#


if [ -z "$BUILD_DIRECTORY" ]
then
      
    echo "BUILD_DIRECTORY environment variable not set"

else
    
    if [ -z "$BUILD_COMMAND" ]
    then
    
        echo "BUILD_COMMAND environment variable not set"
    
    else
    
        cd $BUILD_DIRECTORY
        ls -la
        $BUILD_COMMAND
    
    fi

fi

if [ -z "$BUILD_SCRIPT" ]
then
    
    echo "BUILD_SCRIPT environment variable not set"

else

    cd $GITHUB_WORKSPACE    
    chmod +x "$BUILD_SCRIPT"
    $BUILD_SCRIPT

fi

#================================================================#
#                    Getting user name from hosts file           #
#================================================================#


export GITHUB_BRANCH=${GITHUB_REF##*heads/}
hosts_file="$GITHUB_WORKSPACE/.github/hosts.yml"
export hostname=$(cat "$hosts_file" | shyaml get-value "$GITHUB_BRANCH.hostname")
export ssh_user=$(cat "$hosts_file" | shyaml get-value "$GITHUB_BRANCH.user")

# Extracted from YML file
# echo $hostname
# echo $ssh_user

#================================================================#
#                    Setting up SSH                              #
#================================================================#

mkdir $HOME/.ssh
chmod 600 ~/.ssh
SSH_DIR="$HOME/.ssh"

echo "$PRIVATE_KEY" | tr -d '\r' > "$SSH_DIR/id_rsa"
chmod 600 "$SSH_DIR/id_rsa"
eval "$(ssh-agent -s)"
ssh-add "$SSH_DIR/id_rsa"

cat > /etc/ssh/ssh_config <<EOL
Host *
User $ssh_user
UserKnownHostsFile ${SSH_DIR}/known_hosts
EOL

ssh-keyscan "$hostname" >> ${SSH_DIR}/known_hosts

# Splitting Space separated String

IFS=' '
read -ra DEPLOYPATH <<< "$DEPLOY_LOCATIONS"

# Array of path
# echo ${DEPLOYPATH[0]}
# echo ${DEPLOYPATH[1]}

rsync -avzhp -e "ssh -i $HOME/.ssh/id_rsa" ${DEPLOYPATH[0]} $ssh_user@$hostname:${DEPLOYPATH[1]}