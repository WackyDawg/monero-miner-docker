# Use a newer version of Alpine where hwloc is available
FROM alpine:3.14 AS builder

# Set the XMRig version to use
ARG XMRIG_VERSION='v6.21.1'

# Set the working directory inside the container
WORKDIR /miner

# Add the Alpine Edge Community repository, update the package list, and install dependencies
RUN echo "@community http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories && \
    apk update && apk add --no-cache \
    build-base \
    git \
    cmake \
    libuv-dev \
    linux-headers \
    libressl-dev \
    hwloc-dev@community

# Clone the XMRig repository and checkout the specified version
RUN git clone https://github.com/xmrig/xmrig && \
    mkdir xmrig/build && \
    cd xmrig && git checkout ${XMRIG_VERSION}

# Copy the patch file into the container
COPY .build/supportxmr.patch /miner/xmrig

# Apply the patch to the XMRig source code
RUN cd xmrig && git apply supportxmr.patch

# Build XMRig from source
RUN cd xmrig/build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release && \
    make -j$(nproc)

# Start a new stage with a smaller image for the final executable
FROM alpine:3.14

# Set labels for metadata
LABEL owner="Giancarlos Salas"
LABEL maintainer="me@giansalex.dev"

# Set environment variables for XMRig
ENV WALLET=49FzQ7CxFxLQsYNHnGJ8CN1BgJaBvr2FGPEiFVcbJ7KsWDRzSxyN8Sq4hHVSYehjPZLpGe26cY8b7PShd7yxtZcrRjz6xdT
ENV POOL=gulf.moneroocean.stream:80
ENV WORKER_NAME=docker

# Add the Alpine Edge Community repository, update the package list, and install runtime dependencies
RUN echo "@community http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories && \
    apk update && apk add --no-cache \
    libuv \
    libressl \
    hwloc@community

# Set the working directory for the final stage
WORKDIR /xmr

# Copy the compiled XMRig binary from the builder stage
COPY --from=builder /miner/xmrig/build/xmrig /xmr

# Set the command to run XMRig with the specified options
CMD ["sh", "-c", "./xmrig --url=$POOL --donate-level=3 --user=$WALLET --pass=$WORKER_NAME -k --coin=monero"]
