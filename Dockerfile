ARG IMAGE_TARGET=debian:stretch-slim

# first image to download qemu and make it executable
FROM alpine AS qemu
ARG QEMU=x86_64
ARG VERSION=1.3.3
ADD https://github.com/multiarch/qemu-user-static/releases/download/v2.11.0/qemu-${QEMU}-static /qemu-${QEMU}-static
RUN chmod +x /qemu-${QEMU}-static

FROM karalabe/xgo-latest AS build

RUN xgo --targets=linux/386,linux/amd64,linux/arm-5,linux/arm-6,linux/arm-7,linux/arm64 github.com/google/cadvisor

# second image to be deployed on dockerhub
FROM ${IMAGE_TARGET}
ARG QEMU=x86_64
COPY --from=qemu /qemu-${QEMU}-static /usr/bin/qemu-${QEMU}-static
ARG ARCH=amd64
ARG CADVISOR_ARCH=amd64
ARG VERSION=1.3.3
ARG BUILD_DATE
ARG VCS_REF
ARG VCS_URL

# ZFS MISSING!
RUN apt-get update && \
    apt-get install -yq --no-install-recommends ca-certificates wget dmsetup thin-provisioning-tools && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf

# Grab cadvisor from the staging directory.
# TODO: cadvisors
COPY --from=build /build/cadvisor-linux-${CADVISOR_ARCH} /usr/bin/cadvisor

EXPOSE 8080
ENTRYPOINT ["/usr/bin/cadvisor", "-logtostderr"]
LABEL de.uniba.ktr.cadvisor.version=$VERSION \
    de.uniba.ktr.cadvisor.name="cAdvisor" \
    de.uniba.ktr.cadvisor.docker.cmd="docker run --volume=/:/rootfs:ro --volume=/var/run:/var/run:rw --volume=/sys:/sys:ro --volume=/var/lib/docker/:/var/lib/docker:ro --volume=/dev/disk/:/dev/disk:ro --publish=8080:8080 --detach=true --name=cadvisor unibaktr/cadvisor" \
    de.uniba.ktr.cadvisor.vendor="Marcel Grossmann" \
    de.uniba.ktr.cadvisor.architecture=$ARCH \
    de.uniba.ktr.cadvisor.vcs-ref=$VCS_REF \
    de.uniba.ktr.cadvisor.vcs-url=$VCS_URL \
    de.uniba.ktr.cadvisor.build-date=$BUILD_DATE
