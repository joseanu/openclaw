FROM coollabsio/openclaw:latest

USER root

RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    file \
    git \
    build-essential \
    procps \
  && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash linuxbrew || true

RUN curl -fsSL https://rclone.org/install.sh | bash \
  && curl -LsSf https://astral.sh/uv/install.sh | env UV_UNMANAGED_INSTALL="/usr/local/bin" sh \
  && su - linuxbrew -c 'NONINTERACTIVE=1 CI=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"' \
  && rclone version \
  && uv --version \
  && /home/linuxbrew/.linuxbrew/bin/brew --version

ENV PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:${PATH}"
