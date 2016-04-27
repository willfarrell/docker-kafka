FROM java:8-jre

MAINTAINER Wurstmeister 

RUN apt-get update \
	&& apt-get upgrade -y \
	&& apt-get install -y coreutils curl unzip wget jq net-tools \
	&& curl -sSL https://get.docker.com/ | sh

ENV KAFKA_VERSION="0.9.0.1" SCALA_VERSION="2.11"
ENV KAFKA_HOME /opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION}

ADD bin/* /usr/bin/
RUN download-kafka.sh \
	&& tar xfz /tmp/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz -C /opt \
	&& rm /tmp/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz \
	&& rm /usr/bin/download-kafka.sh

VOLUME ["/kafka"]

# Use "exec" form so that it runs as PID 1 (useful for graceful shutdown)
CMD ["start-kafka.sh"]
