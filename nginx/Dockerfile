FROM nginx:latest

MAINTAINER arnoldcano@yahoo.com

RUN apt-get update && apt-get install -y unzip

ADD https://releases.hashicorp.com/consul-template/0.14.0/consul-template_0.14.0_linux_amd64.zip /tmp/
RUN unzip /tmp/consul-template_0.14.0_linux_amd64.zip -d /usr/local/bin

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
COPY default.ctmpl /templates/default.ctmpl

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
