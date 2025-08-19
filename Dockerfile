# Set default OpenFOAM version, can be overridden at build time
# Example: docker build -t openfoam-2506 --build-arg VERSION=2506 .
ARG VERSION=2506
FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim AS uvstage
FROM ghcr.io/kubeflow/kubeflow/notebook-servers/codeserver:v1.9.2 AS codeserver
FROM docker.io/opencfd/openfoam-dev:${VERSION}

# Use the existing openfoam user from the OpenFOAM image
ENV SHELL=/bin/bash

# Ensure consistent UID/GID (optional, if needed for OKD)
ENV NB_UID=1000
ENV NB_GID=100

# Copy uv binary
COPY --from=uvstage --chown=${NB_UID}:${NB_GID} --chmod=755 /usr/local/bin/uv /usr/local/bin

# Copy CodeServer binaries
COPY --from=codeserver /usr/bin/code-server /usr/bin/code-server
COPY --from=codeserver /usr/lib/code-server /usr/lib/code-server

# Prepare home directory
ENV HOME=/home/jovyan
RUN mkdir -p ${HOME} && chown -R ${NB_UID}:${NB_GID} ${HOME}
WORKDIR $HOME

# OpenShift compatibility: make /home/jovyan writable by arbitrary UID
RUN chgrp -R 0 /home/jovyan && chmod -R g=u /home/jovyan

# Set environment for uv
ENV UV_NO_CACHE=True
ENV UV_LINK_MODE=copy

# OpenShift compatibility: make /opt writable by arbitrary UID
RUN chgrp -R 0 /opt && chmod -R g=u /opt

# APT packages
# package source of openfoam is not correctly setup, so ignore errors
RUN apt-get update || true
RUN apt-get install -y --no-install-recommends \
  git htop nano vim curl telnet

USER ${NB_UID}

EXPOSE 8888

# Entry point will use $HOME
ENTRYPOINT ["code-server"]
CMD ["--bind-addr", "0.0.0.0:8888", "--auth", "none"]