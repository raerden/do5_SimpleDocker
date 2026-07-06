# ======================
# BUILD
# ======================
FROM ubuntu:22.04 AS builder

RUN apt-get update && apt-get install -y \
    gcc \
    libfcgi-dev \
 && rm -rf /var/lib/apt/lists/*

COPY server/server.c /app/server.c

RUN gcc /app/server.c -o /app/server -lfcgi


# ======================
# RUNTIME
# ======================
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    nginx \
    libfcgi0ldbl \
    curl \
 && rm -rf /var/lib/apt/lists/*

# non-root user
# RUN useradd -r -u 1001 -s /usr/sbin/nologin appuser

COPY --from=builder /app/server /app/server

COPY server/nginx/nginx.conf /etc/nginx/nginx.conf


# start script (no spawn-fcgi!)
RUN printf '#!/bin/sh\n\
set -e\n\
/app/server &\n\
nginx -g "daemon off;"\n' > /start.sh \
 && chmod +x /start.sh

HEALTHCHECK --interval=30s --timeout=3s \
 CMD curl -fs http://localhost/ || exit 1

# USER appuser

CMD ["/start.sh"]