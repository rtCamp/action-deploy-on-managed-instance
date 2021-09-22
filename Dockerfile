FROM ubuntu

ARG DEBIAN_FRONTEND=noninteractive

RUN apt update && \
	apt install -y \
		curl \
		nodejs \
		ssh \
		rsync \
        python3-pip && \
        pip3 install shyaml

ADD entrypoint.sh /entrypoint.sh
RUN chmod +rx entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]