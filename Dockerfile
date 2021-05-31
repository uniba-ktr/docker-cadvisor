FROM golang as build
ENV GOOS=linux
ENV CGO_ENABLED=1
ARG VERSION=v0.35.0

WORKDIR ${GOPATH}/src/github.com/google
RUN git clone --branch ${VERSION} https://github.com/google/cadvisor.git
WORKDIR ${GOPATH}/src/github.com/google/cadvisor
RUN make build

FROM alpine
ARG VERSION=master
ARG BUILD_DATE
ARG VCS_REF
ARG VCS_URL
ARG TARGETPLATFORM

# Without zfs for arm
RUN apk --no-cache add libc6-compat device-mapper findutils && \
    apk --no-cache add zfs || true && \
    apk --no-cache add thin-provisioning-tools --repository http://dl-3.alpinelinux.org/alpine/edge/main/ && \
    echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf && \
    rm -rf /var/cache/apk/*

# Grab cadvisor from the staging directory.
COPY --from=build /go/src/github.com/google/cadvisor/cadvisor /usr/bin/cadvisor

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s \
  CMD wget --quiet --tries=1 --spider http://localhost:8080/healthz || exit 1

ENTRYPOINT ["/usr/bin/cadvisor", "-logtostderr"]

LABEL de.uniba.ktr.cadvisor.version=$VERSION \
      de.uniba.ktr.cadvisor.name="cAdvisor" \
      de.uniba.ktr.cadvisor.docker.cmd="docker run --volume=/:/rootfs:ro --volume=/var/run:/var/run:rw --volume=/sys:/sys:ro --volume=/var/lib/docker/:/var/lib/docker:ro --volume=/dev/disk/:/dev/disk:ro --publish=8080:8080 --detach=true --name=cadvisor unibaktr/cadvisor" \
      de.uniba.ktr.cadvisor.vendor="Marcel Grossmann" \
      de.uniba.ktr.cadvisor.architecture=$TARGETPLATFORM \
      de.uniba.ktr.cadvisor.vcs-ref=$VCS_REF \
      de.uniba.ktr.cadvisor.vcs-url=$VCS_URL \
      de.uniba.ktr.cadvisor.build-date=$BUILD_DATE
