FROM ubuntu

RUN apt update && \
	apt install -y \
		curl \
		nodejs \
		ssh \
		rsync \
        python3-pip && \
        pip3 install shyaml && \
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash && \
        export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

ADD entrypoint.sh /entrypoint.sh
RUN chmod +rx entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]