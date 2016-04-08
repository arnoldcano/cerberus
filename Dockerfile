FROM scratch

MAINTAINER arnoldcano@yahoo.com

COPY main /

ENTRYPOINT ["/main"]
