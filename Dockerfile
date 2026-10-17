ARG VERSION=1.0.0

FROM node:24-alpine AS builder
RUN apk add --update curl perl

ARG VERSION

WORKDIR /tmp

RUN wget -O crucix.tar.gz "https://github.com/calesthio/Crucix/archive/refs/heads/master.tar.gz"

ENV WD=/tmp/crucix
RUN mkdir -p "$WD"
RUN tar -zxvf /tmp/crucix.tar.gz --strip-components=1 -C "$WD" && cd "$WD" \
    && perl -i -pe "s/(server\s*:\s*\{)(?!\s*host)/\$1\n    host: '0.0.0.0',/g" crucix.config.mjs \
    && rm -rf .github .dockerignore \
    && npm install --production

RUN curl -Lo /tmp/wget https://busybox.net/downloads/binaries/1.31.0-i686-uclibc/busybox_CURL

FROM gcr.io/distroless/nodejs24-debian13

COPY --from=builder /tmp/crucix /app
COPY --from=builder /tmp/wget /usr/bin/wget

# Default port (override with -e PORT=xxxx)
EXPOSE 3117

# Health check
HEALTHCHECK --interval=60s --timeout=10s --retries=3 \
  CMD wget -qO- http://localhost:3117/api/health || exit 1

CMD ["/app/server.mjs"]
