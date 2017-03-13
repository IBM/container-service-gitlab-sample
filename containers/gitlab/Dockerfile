FROM alpine:3.5

ENV LANG en_US.utf8

COPY install.sh /
COPY entrypoint.sh /
RUN adduser -D -s /bin/false -g 'Gitlab' git
RUN sh /install.sh && rm /install.sh

ENTRYPOINT ["/entrypoint.sh"]
