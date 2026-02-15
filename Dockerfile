FROM coollabsio/openclaw:latest

USER root

# 1. Instalación de dependencias del sistema
RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates curl file git build-essential procps \
  && rm -rf /var/lib/apt/lists/*

# 2. Crear usuario y asegurar carpetas (Crucial para persistencia)
RUN useradd -m -s /bin/bash linuxbrew || true \
  && mkdir -p /home/linuxbrew/.linuxbrew \
  && chown -R linuxbrew:linuxbrew /home/linuxbrew

# 3. Instalación de herramientas (rclone y uv)
RUN curl -fsSL https://rclone.org/install.sh | bash \
  && curl -LsSf https://astral.sh/uv/install.sh | env UV_UNMANAGED_INSTALL="/usr/local/bin" sh

# 4. Instalación de Homebrew como el usuario correcto
# Nota: Usamos eval para que el PATH se configure en la sesión de instalación
RUN su - linuxbrew -c 'NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'

# 5. Configuración GLOBAL del PATH (Para que funcione con 'su -' y con 'root')
ENV HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
ENV PATH="${HOMEBREW_PREFIX}/bin:${HOMEBREW_PREFIX}/sbin:${PATH}"

# Hace que el PATH sea persistente para sesiones interactivas
RUN echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /etc/bash.bashrc

# Verificación
RUN rclone version && uv --version && brew --version