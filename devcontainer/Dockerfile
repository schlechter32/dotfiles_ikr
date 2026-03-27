FROM ubuntu:24.04

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      git \
      less \
      libgmt-dev \
      procps \
      sudo \
      unzip \
      xz-utils \
      zsh \
    && rm -rf /var/lib/apt/lists/*

RUN usermod -l dev -d /home/dev -m -s /usr/bin/zsh ubuntu \
    && groupmod -n dev ubuntu \
    && mkdir -p /nix \
    && chown dev:dev /nix \
    && echo "dev ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/dev \
    && chmod 0440 /etc/sudoers.d/dev

USER dev
ENV HOME=/home/dev
ENV SHELL=/usr/bin/zsh
ENV DOTFILES_INSTALL_MODE=container
ENV NIX_CONFIG="experimental-features = nix-command flakes"
ENV PATH="$HOME/.nix-profile/bin:$HOME/.local/state/nix/profile/bin:$HOME/.local/bin:$HOME/.cargo/bin:$HOME/nbin:$PATH"

COPY --chown=dev:dev devcontainer /tmp/devcontainer-build
COPY --chown=dev:dev . /home/dev/dotfiles

RUN curl -fsSL https://nixos.org/nix/install | sh -s -- --no-daemon \
    && . "$HOME/.nix-profile/etc/profile.d/nix.sh" \
    && nix profile install path:/tmp/devcontainer-build#container-tools \
    && cargo-binstall -y television \
    && curl -fsSL https://opencode.ai/install | bash \
    && rm -rf /tmp/devcontainer-build

WORKDIR /workspace
