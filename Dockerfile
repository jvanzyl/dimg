FROM alpine:3.9.4
MAINTAINER "Jason van Zyl" <jason@vanzyl.ca>

ARG user
ARG uid
ARG group
ARG gid

RUN addgroup -g ${gid} ${group}
RUN adduser -D ${user} -u ${uid} -G ${group}

# We need the standard certs in order to connect over TLS with the world
RUN apk update
RUN apk add ca-certificates
RUN rm -rf /var/cache/apk/*

# Setup the path to include the new binaries we have mounted in the workspace
ENV PATH="/workspace/concord/bin:${PATH}"

USER ${user}
