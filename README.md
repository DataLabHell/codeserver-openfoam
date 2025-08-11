# Codeserver + OpenFOAM Dev Container

A development container image that combines:

- **[OpenFOAM](https://openfoam.org/)** (dev build, version selectable)
- **[code-server](https://github.com/coder/code-server)** – browser-based VS Code
- **[uv](https://github.com/astral-sh/uv)** – ultra-fast Python package and environment manager
- Useful CLI tools: `git`, `htop`, `nano`, `vim`

Optimized for:

- **Kubeflow Notebooks** (with PVC mounted at `/home/jovyan`)
- **OKD/OpenShift** (runs with arbitrary UIDs)
- Local Docker usage

---

## Features

- **OpenFOAM** default version: `2506` (overridable at build time)
- code-server with Open VSX extension registry
- uv for fast Python dependency management
- Runs as non-root, UID/GID safe for OpenShift
- Writable `/home/jovyan` for mounted workspaces

---

## Build

```sh
# Build with default OpenFOAM version (2506)
docker build -t codeserver-openfoam:latest .

# Build with a specific OpenFOAM version
docker build -t codeserver-openfoam:2312 --build-arg VERSION=2312 .
```

---

## Run Locally

> By default, this container runs as a **non-root user** (`UID 1000`, `GID 100`) for security and OpenShift compatibility.
  When running locally, you may need to set the `HOME` environment variable and mount a directory your user can write to.
  In Kubeflow, `/home/jovyan` is typically replaced by a mounted PVC, so the directory exists and is writable.


```sh
docker run --rm -p 8888:8888 \
  -v "$PWD:/home/ubuntu" \
  -e HOME=/home/ubuntu \
  codeserver-openfoam:latest
```

Open your browser at: http://localhost:8888

> Note: The default config uses --auth none. In production, set a password or authentication proxy, see the [Enable Authentication](#enable-authentication) section for usage.

---

## Running in Kubeflow

When used as a Kubeflow Notebook image:

- The container will typically mount a Persistent Volume Claim (PVC) at `/home/jovyan`.
- Kubeflow runs notebook containers with an **arbitrary UID/GID**, so this image is prepared with OpenShift-compatible permissions (`g=u` on writable dirs).
- The default `HOME` in Kubeflow will be `/home/jovyan`, and the working directory is set accordingly.
- code-server will bind to port 8888.

Example in Kubeflow Notebook settings:

<img width="600" alt="kubeflow" src="https://github.com/user-attachments/assets/d66d21e7-6ae5-472c-aa83-76cabf04da00" />

Also mount the default workspace volume under the path `/home/jovyan`.

---

## Enable Authentication

For production, set a password:

```sh
docker run --rm -p 8888:8888 \
  -v "$PWD:/home/ubuntu" \
  -e HOME=/home/ubuntu \
  -e PASSWORD=mysecret \
  codeserver-openfoam:latest \
  --bind-addr 0.0.0.0:8888 \
  --auth password
```

After visiting http://localhost:8888 the password must be entered to access vscode.
