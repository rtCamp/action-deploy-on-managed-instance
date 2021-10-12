FROM ubuntu

ARG DEBIAN_FRONTEND=noninteractive

RUN apt update && \
	apt install -y \
		curl \
		nodejs \
		ssh \
		rsync \
		git \
		zip \
		unzip \
		python3-pip \
		software-properties-common && \
		add-apt-repository ppa:ondrej/php && \
		apt update && \
		apt-get install -y php7.4-cli php7.4-curl php7.4-json php7.4-mbstring php7.4-xml php7.4-iconv php7.4-zip && \
		pip3 install shyaml && \
		rm -rf /var/lib/apt/lists/*

# setup composer
RUN mkdir -p /composer && \
	curl -sS https://getcomposer.org/installer | \
	php -- --install-dir=/usr/bin/ --filename=composer

RUN echo "Downloading NVM"

RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash

ADD entrypoint.sh /entrypoint.sh
RUN chmod +rx entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]