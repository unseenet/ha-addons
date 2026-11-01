# A council replica (UN-RFC 0054) as a Home Assistant add-on: the project's signed
# image (ghcr.io/unseenet/replica, see build.yaml) with a small start-up script that
# reads the add-on's options. The image keeps its tini, su-exec and non-root user.
ARG BUILD_FROM
FROM ${BUILD_FROM}

COPY rootfs /
# the replica in /data/replica, so the Supervisor's /data/options.json stays root's;
# the service user's home follows it
RUN chmod 755 /usr/local/bin/unseenet-addon \
 && sed -i 's#^\(unseenet:[^:]*:10001:[^:]*:[^:]*:\)/data:#\1/data/replica:#' /etc/passwd \
 && grep -q '^unseenet:.*:/data/replica:' /etc/passwd

ENV UNSEENET_REPLICA_DIR=/data/replica
# the image's own check, at the replica's new place: status.json at least every 30 minutes
HEALTHCHECK --interval=5m --timeout=15s --start-period=30m \
  CMD python3 -c "import os, time; \
raise SystemExit(0 if time.time() - os.stat('/data/replica/status.json').st_mtime < 1800 else 1)"

ARG BUILD_ARCH
ARG BUILD_VERSION
LABEL io.hass.type="addon" \
      io.hass.arch="${BUILD_ARCH}" \
      io.hass.version="${BUILD_VERSION}" \
      org.opencontainers.image.title="Unseenet council replica (Home Assistant add-on)" \
      org.opencontainers.image.source="https://github.com/unseenet/ha-addons" \
      org.opencontainers.image.licenses="Apache-2.0"

ENTRYPOINT ["/sbin/tini", "--", "unseenet-addon"]
