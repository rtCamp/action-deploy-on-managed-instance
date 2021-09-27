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
export single_deploy_location=$(cat "$hosts_file" | shyaml get-value "$GITHUB_BRANCH.single_deploy_location")

#================================================================#
#                    Setting up SSH                              #
#================================================================#


function setup_private_key() {

	if [[ -n "$SSH_PRIVATE_KEY" ]]; then
	echo "$SSH_PRIVATE_KEY" | tr -d '\r' > "$SSH_DIR/id_rsa"
	chmod 600 "$SSH_DIR/id_rsa"
	eval "$(ssh-agent -s)"
	ssh-add "$SSH_DIR/id_rsa"

	if [[ -n "$JUMPHOST_SERVER" ]]; then
		ssh-keyscan -H "$JUMPHOST_SERVER" >> /etc/ssh/known_hosts 
	fi
	else
		# Generate a key-pair
		ssh-keygen -t rsa -b 4096 -C "GH-actions-ssh-deploy-key" -f "$HOME/.ssh/id_rsa" -N ""
	fi
}

function configure_ssh_config() {

if [[ -z "$JUMPHOST_SERVER" ]]; then
	# Create ssh config file. `~/.ssh/config` does not work.
	cat > /etc/ssh/ssh_config <<EOL
Host $hostname
HostName $hostname
IdentityFile ${SSH_DIR}/signed-cert.pub
IdentityFile ${SSH_DIR}/id_rsa
User $ssh_user
EOL
else
	# Create ssh config file. `~/.ssh/config` does not work.
	cat > /etc/ssh/ssh_config <<EOL
Host jumphost
	HostName $JUMPHOST_SERVER
	UserKnownHostsFile /etc/ssh/known_hosts
	User $ssh_user
Host $hostname
	HostName $hostname
	ProxyJump jumphost
	UserKnownHostsFile /etc/ssh/known_hosts
	User $ssh_user
EOL
fi
}

function setup_ssh_access() {

	printf "[\e[0;34mNOTICE\e[0m] Setting up SSH access to server.\n"

	SSH_DIR="$HOME/.ssh"
	mkdir -p "$SSH_DIR"
	chmod 700 "$SSH_DIR"

	setup_private_key
	configure_ssh_config
}
setup_ssh_access

ssh-keyscan "$hostname" >> ${SSH_DIR}/known_hosts

function maybe_install_submodules() {

	# Check and update submodules if any
	if [[ -f "$GITHUB_WORKSPACE/.gitmodules" ]]; then
		# add github's public key
		echo "|1|qPmmP7LVZ7Qbpk7AylmkfR0FApQ=|WUy1WS3F4qcr3R5Sc728778goPw= ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==" >> /etc/ssh/known_hosts

		identity_file=''
		if [[ -n "$SUBMODULE_DEPLOY_KEY" ]]; then
			echo "$SUBMODULE_DEPLOY_KEY" | tr -d '\r' > "$SSH_DIR/submodule_deploy_key"
			chmod 600 "$SSH_DIR/submodule_deploy_key"
			ssh-add "$SSH_DIR/submodule_deploy_key"
			identity_file="IdentityFile ${SSH_DIR}/submodule_deploy_key"
		fi

	# Setup config file for proper git cloning
	cat >> /etc/ssh/ssh_config <<EOL
Host github.com
HostName github.com
User git
UserKnownHostsFile /etc/ssh/known_hosts
${identity_file}
EOL
	git submodule update --init --recursive
fi
}
maybe_install_submodules

#================================================================#
#                    Deployment                                  #
#================================================================#


if [ -z $single_deploy_location ]
then
    DEPLOY_LOCATIONS=$GITHUB_WORKSPACE/.github/locations.csv

    # Splitting Space separated String
    echo "$DEPLOY_LOCATIONS this is deploy location"

    while read line;
    do

        source=$(echo $line | awk -F'[,]' '{print $1}')
        destination=$(echo $line | awk -F'[,]' '{print $2}')
        rsync -avzhP -e "ssh -o StrictHostKeyChecking=no" \
            --exclude '.git' \
            --exclude '.github' \
            --exclude 'deploy.php' \
            --exclude 'composer.lock' \
            --exclude '.env' \
            --exclude '.env.example' \
            --exclude '.gitignore' \
            --exclude '.gitlab-ci.yml' \
            --exclude 'Gruntfile.js' \
            --exclude 'package.json' \
            --exclude 'README.md' \
            --exclude 'gulpfile.js' \
            --exclude '.circleci' \
            --exclude 'package-lock.json' \
            --exclude 'package.json' \
            --exclude 'phpcs.xml' \
            --delete \
            $source $ssh_user@$hostname:$destination/

    done <<< "$(cat $DEPLOY_LOCATIONS)"
else
    rsync -avzhP -e "ssh -o StrictHostKeyChecking=no" \
        --exclude '.git' \
        --exclude '.github' \
        --exclude 'deploy.php' \
        --exclude 'composer.lock' \
        --exclude '.env' \
        --exclude '.env.example' \
        --exclude '.gitignore' \
        --exclude '.gitlab-ci.yml' \
        --exclude 'Gruntfile.js' \
        --exclude 'package.json' \
        --exclude 'README.md' \
        --exclude 'gulpfile.js' \
        --exclude '.circleci' \
        --exclude 'package-lock.json' \
        --exclude 'package.json' \
        --exclude 'phpcs.xml' \
        --delete \
        $GITHUB_WORKSPACE/ $ssh_user@$hostname:$single_deploy_location/
fi