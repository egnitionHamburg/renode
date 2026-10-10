FROM ubuntu:22.04

# Fix Colima/VirtioFS dpkg fsync I/O errors
# (This is totally safe on Linux CI too, and actually speeds up apt-get installs!)
RUN echo "force-unsafe-io" > /etc/dpkg/dpkg.cfg.d/force-unsafe-io

ENV DEBIAN_FRONTEND=noninteractive

# Install minimal dependencies for headless execution and building
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    git \
    automake \
    autoconf \
    libtool \
    g++ \
    coreutils \
    uml-utilities \
    libc6-dev \
    gcc \
    python3 \
    python3-pip \
    python3-venv \
    cmake \
    make \
    ninja-build

# Install .NET 8 SDK
RUN wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    apt-get update && \
    apt-get install -y dotnet-sdk-8.0

# Install pyrenode3 globally
RUN pip3 install git+https://github.com/antmicro/pyrenode3.git

WORKDIR /renode

# Copy the local repo into the container
COPY . /renode

# Build Renode natively. One MSBuild node and no shared compiler server: the parallel build runs out of memory
# in a 4 GB Docker VM.
RUN ./build.sh -- -m:1 -p:UseSharedCompilation=false

# Set PATH so 'renode' and 'renode-test' commands work globally
ENV PATH="/renode:${PATH}"
ENV PYRENODE_PATH="/renode"

# Set default entrypoint to standard bash shell
CMD ["/bin/bash"]
