# syntax=docker/dockerfile:1.7
#
# Runtime image for the DataLens Theme Fork UI.
#
# It reuses the upstream 0.3831.0 image (nginx + node server) and only adds:
#   - the fork nginx config (proxying /api/run* to the Rust monolith);
#   - a seed themes.json and an entrypoint that prepares the writable store.
#
# The built UI (102 MB public/, ~29 MB without source maps) is not committed.
# Either mount it as a volume (default compose setup) or bake it at build time:
#
#   docker build --build-arg DIST_URL=https://.../dist.tar.gz -t ui-theme-fork .
#
# The tarball must contain the *contents* of dist/ (public, server, shared, ...).

ARG BASE_IMAGE=ghcr.io/datalens-tech/datalens-ui:0.3831.0@sha256:5c720832463cc54c43307a9aeafb8f881fb54facc548edac35efb8ccfe327b0f
FROM ${BASE_IMAGE}

ARG DIST_URL=""
ARG DIST_SHA256=""

LABEL org.opencontainers.image.title="DataLens UI Theme Fork" \
      org.opencontainers.image.description="DataLens UI fork with Theme Studio, per-user themes and a streaming batch chart client" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.base.name="ghcr.io/datalens-tech/datalens-ui:0.3831.0" \
      org.opencontainers.image.base.digest="sha256:5c720832463cc54c43307a9aeafb8f881fb54facc548edac35efb8ccfe327b0f"

ENV THEMES_DATA_DIR=/opt/app/theme-data \
    THEMES_DATA_PATH=/opt/app/theme-data/themes.json

COPY --chmod=0644 nginx/nginx.conf /etc/nginx/nginx.conf
COPY --chown=app:app theme-data.example/themes.json /opt/app/theme-data.seed/themes.json
COPY --chmod=0755 docker/entrypoint.sh /usr/local/bin/theme-fork-entrypoint.sh

USER root

RUN mkdir -p /opt/app/theme-data \
 && chmod 0755 /opt/app/theme-data.seed \
 && chmod 0644 /opt/app/theme-data.seed/themes.json \
 && chown app:app /opt/app/theme-data /opt/app/theme-data.seed \
 && if [ -n "${DIST_URL}" ]; then \
        echo "theme-fork: downloading dist from ${DIST_URL}"; \
        rm -rf /opt/app/dist && mkdir -p /opt/app/dist; \
        DIST_URL="${DIST_URL}" node -e 'const fs=require("fs");const u=process.env.DIST_URL;fetch(u,{redirect:"follow"}).then(async r=>{if(!r.ok)throw new Error("HTTP "+r.status);fs.writeFileSync("/tmp/dist.tar.gz",Buffer.from(await r.arrayBuffer()))}).catch(e=>{console.error(e);process.exit(1)})'; \
        if [ -n "${DIST_SHA256}" ]; then echo "${DIST_SHA256}  /tmp/dist.tar.gz" | sha256sum -c -; fi; \
        tar -xzf /tmp/dist.tar.gz -C /opt/app/dist; \
        rm -f /tmp/dist.tar.gz; \
        chown -R app:app /opt/app/dist; \
    fi

USER app

ENTRYPOINT ["/usr/local/bin/theme-fork-entrypoint.sh"]
