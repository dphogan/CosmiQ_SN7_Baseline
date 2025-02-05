# Adapted from: https://raw.githubusercontent.com/CosmiQ/solaris/master/docker/gpu/Dockerfile
# docker build -t sn7_baseline_image /path_to_docker/
# NV_GPU=0 nvidia-docker run -it -v /local_data:/local_data -v  --rm -ti --ipc=host --name sn7_baseline_gpu0 sn7_baseline_image

FROM nvidia/cuda:10.2-devel-ubuntu16.04
LABEL maintainer="avanetten <avanetten@iqt.org>"

ENV CUDNN_VERSION 7.3.0.29
LABEL com.nvidia.cudnn.version="${CUDNN_VERSION}"
ARG solaris_branch='master'

# prep apt-get and cudnn
RUN apt-get update && apt-get install -y --no-install-recommends \
	    apt-utils \
            libcudnn7=$CUDNN_VERSION-1+cuda9.0 \
            libcudnn7-dev=$CUDNN_VERSION-1+cuda9.0 && \
    apt-mark hold libcudnn7 && \
    rm -rf /var/lib/apt/lists/*

# install requirements
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    bc \
    bzip2 \
    ca-certificates \
    curl \
    emacs \
    git \
    less \
    libgdal-dev \
    libssl-dev \
    libffi-dev \
    libncurses-dev \
    libgl1 \
    jq \
    nfs-common \
    parallel \
    python-dev \
    python-pip \
    python-wheel \
    python-setuptools \
    tree \
    unzip \
    vim \
    wget \
    build-essential \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

SHELL ["/bin/bash", "-c"]
ENV PATH /opt/conda/bin:$PATH

# install anaconda
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-4.5.4-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p /opt/conda && \
    rm ~/miniconda.sh && \
    /opt/conda/bin/conda clean -tipsy && \
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "conda activate base" >> ~/.bashrc

# prepend pytorch and conda-forge before default channel
RUN conda update conda && \
    conda config --prepend channels conda-forge && \
    conda config --prepend channels pytorch

# get dev version of solaris and create conda environment based on its env file
WORKDIR /root/
RUN git clone https://github.com/cosmiq/solaris.git && \
    cd solaris && \
    git checkout ${solaris_branch} && \
    conda env create -f environment-gpu.yml
ENV PATH /opt/conda/envs/solaris/bin:$PATH

RUN cd solaris && pip install .

# install various conda dependencies into the space_base environment
RUN conda install -n solaris \
                     jupyter \
                     jupyterlab \
                     ipykernel

# add a jupyter kernel for the conda environment in case it's wanted
RUN source activate solaris && python -m ipykernel.kernelspec \
    --name solaris --display-name solaris

# ensure solaris is activated
# RUN conda activate solaris

# Need imagecodecs for Planet files
RUN pip install imagecodecs

# Copy baseline into image
COPY ./ ./

# open ports for jupyterlab and tensorboard
EXPOSE 8888 6006

RUN ["/bin/bash"]
