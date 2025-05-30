# ----------- Base Image with CUDA and Ubuntu 24.04 -----------
FROM nvidia/cuda:12.5.1-devel-ubuntu24.04 AS base

# ----------- Environment Setup -----------
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    CMAKE_BUILD_PARALLEL_LEVEL=8 \
    PIP_PREFER_BINARY=1 \
    PATH="/opt/venv/bin:$PATH"

# ----------- OS & Python Setup with Caching -----------
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        python3.12 python3.12-venv python3.12-dev \
        python3-pip build-essential gcc \
        curl wget git git-lfs vim ffmpeg ninja-build \
        libgl1 libglib2.0-0 && \
    ln -sf /usr/bin/python3.12 /usr/bin/python && \
    ln -sf /usr/bin/pip3 /usr/bin/pip && \
    python -m venv /opt/venv && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# ----------- Python Base Dependencies -----------
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --upgrade pip setuptools wheel packaging

# ----------- Install Torch Nightly for CUDA 12.8 -----------
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --pre torch torchvision torchaudio \
        --index-url https://download.pytorch.org/whl/nightly/cu128

# ----------- Core Runtime Libraries -----------
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install \
        pyyaml gdown triton comfy-cli \
        jupyterlab jupyterlab-lsp jupyter-server \
        jupyter-server-terminals ipykernel \
        jupyterlab_code_formatter

# ----------- ComfyUI Core Installation -----------
RUN --mount=type=cache,target=/root/.cache/pip \
    yes | comfy --workspace /ComfyUI install

# ----------- Final Runtime Layer -----------
FROM base AS final

# Extra CV Dependency
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install opencv-python

# ----------- Install Custom Nodes -----------
RUN mkdir -p /ComfyUI/custom_nodes && \
    for repo in \
        https://github.com/ssitu/ComfyUI_UltimateSDUpscale.git \
        https://github.com/kijai/ComfyUI-KJNodes.git \
        https://github.com/rgthree/rgthree-comfy.git \
        https://github.com/JPS-GER/ComfyUI_JPS-Nodes.git \
        https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes.git \
        https://github.com/Jordach/comfy-plasma.git \
        https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git \
        https://github.com/bash-j/mikey_nodes.git \
        https://github.com/ltdrdata/ComfyUI-Impact-Pack.git \
        https://github.com/Fannovel16/comfyui_controlnet_aux.git \
        https://github.com/yolain/ComfyUI-Easy-Use.git \
        https://github.com/kijai/ComfyUI-Florence2.git \
        https://github.com/ShmuelRonen/ComfyUI-LatentSyncWrapper.git \
        https://github.com/WASasquatch/was-node-suite-comfyui.git \
        https://github.com/theUpsider/ComfyUI-Logic.git \
        https://github.com/cubiq/ComfyUI_essentials.git \
        https://github.com/chrisgoringe/cg-image-picker.git \
        https://github.com/chflame163/ComfyUI_LayerStyle.git \
        https://github.com/chrisgoringe/cg-use-everywhere.git \
        https://github.com/welltop-cn/ComfyUI-TeaCache.git \
        https://github.com/Fannovel16/ComfyUI-Frame-Interpolation.git \
        https://github.com/Jonseed/ComfyUI-Detail-Daemon.git \
        https://github.com/kijai/ComfyUI-WanVideoWrapper.git \
        https://github.com/M1kep/ComfyLiterals.git; do \
        cd /ComfyUI/custom_nodes && \
        git clone --recursive "$repo"; \
        dir="/ComfyUI/custom_nodes/$(basename $repo .git)"; \
        [ -f "$dir/requirements.txt" ] && pip install -r "$dir/requirements.txt"; \
        [ -f "$dir/install.py" ] && python "$dir/install.py"; \
    done

# ----------- Assets & Entrypoint -----------
COPY src/start_script.sh /start_script.sh
COPY 4xLSDIR.pth /4xLSDIR.pth
RUN chmod +x /start_script.sh

CMD ["/start_script.sh"]
