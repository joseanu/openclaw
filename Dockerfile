FROM coollabsio/openclaw:latest

USER root

# 1. Dependencias base (seguro de ejecutar aunque upstream ya las traiga)
RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates curl file git build-essential procps gnupg \
  && install -m 0755 -d /etc/apt/keyrings \
  && curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc \
  && chmod a+r /etc/apt/keyrings/docker.asc \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian bookworm stable" > /etc/apt/sources.list.d/docker.list \
  && apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    docker-ce-cli \
  && rm -rf /var/lib/apt/lists/*

# 2. Instalación idempotente de rclone/uv/brew (solo si faltan)
RUN set -eux; \
  if ! command -v rclone >/dev/null 2>&1; then \
    curl -fsSL https://rclone.org/install.sh | bash; \
  fi; \
  if ! command -v uv >/dev/null 2>&1; then \
    curl -LsSf https://astral.sh/uv/install.sh | env UV_UNMANAGED_INSTALL="/usr/local/bin" sh; \
  fi; \
  if [ ! -x /home/linuxbrew/.linuxbrew/bin/brew ]; then \
    id -u linuxbrew >/dev/null 2>&1 || useradd -m -s /bin/bash linuxbrew; \
    mkdir -p /home/linuxbrew/.linuxbrew; \
    chown -R linuxbrew:linuxbrew /home/linuxbrew; \
    su - linuxbrew -c 'NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'; \
  fi

# 3. Configuración GLOBAL del PATH (Para que funcione con 'su -' y con 'root')
ENV HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
ENV PATH="${HOMEBREW_PREFIX}/bin:${HOMEBREW_PREFIX}/sbin:${PATH}"

# Hace que el PATH sea persistente para sesiones interactivas
RUN if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then \
      grep -q 'brew shellenv' /etc/bash.bashrc || echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /etc/bash.bashrc; \
    fi

# Use repository scripts instead of whatever is bundled in base image.
COPY scripts/ /app/scripts/
RUN chmod +x /app/scripts/*.sh

# Verificación
RUN command -v rclone && rclone version \
  && command -v uv && uv --version \
  && command -v brew && brew --version \
  && command -v docker && docker --version
