# The Unseenet node as a Home Assistant add-on: the project's signed image
# (ghcr.io/unseenet/node, see build.yaml) with a small start-up script that reads
# the add-on's options. The image keeps its tini, su-exec and non-root user.
ARG BUILD_FROM
FROM ${BUILD_FROM}

COPY rootfs /
# the node's data in /data/node, so the Supervisor's /data/options.json stays root's;
# the service user's home follows it
RUN chmod 755 /usr/local/bin/unseenet-addon \
 && sed -i 's#^\(unseenet:[^:]*:10001:[^:]*:[^:]*:\)/data:#\1/data/node:#' /etc/passwd \
 && grep -q '^unseenet:.*:/data/node:' /etc/passwd

ENV UNSEENET_DATA=/data/node \
    UNSEENET_MONITOR=/data/node/monitor.sock

ARG BUILD_ARCH
ARG BUILD_VERSION
LABEL io.hass.type="addon" \
      io.hass.arch="${BUILD_ARCH}" \
      io.hass.version="${BUILD_VERSION}" \
      org.opencontainers.image.title="Unseenet node (Home Assistant add-on)" \
      org.opencontainers.image.source="https://github.com/unseenet/ha-addons" \
      org.opencontainers.image.licenses="Apache-2.0"

ENTRYPOINT ["/sbin/tini", "--", "unseenet-addon"]
