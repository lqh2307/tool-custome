ARG BUILDER_IMAGE=ubuntu:22.04
ARG TARGET_IMAGE=ubuntu:22.04
# ARG BUILDER_IMAGE=ubuntu:24.04
# ARG TARGET_IMAGE=ubuntu:24.04

FROM ${BUILDER_IMAGE} AS builder

ARG PREFIX_DIR=/usr/local/opt

RUN DEBIAN_FRONTEND=noninteractive apt-get update -y \
	&& apt-get upgrade -y \
	&& apt-get install -y \
      build-essential \
      cmake \
			libosmium2-dev \
			libprotozero-dev \
			nlohmann-json3-dev \
			libboost-program-options-dev \
			libbz2-dev \
			zlib1g-dev \
			liblz4-dev \
			libexpat1-dev \
			pandoc \
	&& apt-get -y --purge autoremove \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

COPY ./osmium-tool .

RUN mkdir -p ./build \
  && cd ./build \
  && cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=${PREFIX_DIR}/osmium-tool \
  && cmake --build . --parallel $(nproc) \
  && cmake --build . --target install


FROM ${TARGET_IMAGE} AS final

ARG PREFIX_DIR=/usr/local/opt

# ubuntu 22.04
RUN DEBIAN_FRONTEND=noninteractive apt-get update -y \
	&& apt-get install -y \
		libosmium2-dev \
		libprotozero-dev \
		nlohmann-json3-dev \
		libboost-program-options1.74.0 \
		libbz2-1.0 \
		zlib1g \
		liblz4-1 \
		libexpat1 \
	&& apt-get -y --purge autoremove \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

# ubuntu 24.04
# RUN DEBIAN_FRONTEND=noninteractive apt-get update -y \
# 	&& apt-get install -y \
# 		libosmium2-dev \
# 		libprotozero-dev \
# 		nlohmann-json3-dev \
# 		libboost-program-options1.83.0 \
# 		libbz2-1.0 \
# 		zlib1g \
# 		liblz4-1 \
# 		libexpat1 \
# 	&& apt-get -y --purge autoremove \
# 	&& apt-get clean \
# 	&& rm -rf /var/lib/apt/lists/*

COPY --from=builder ${PREFIX_DIR} ${PREFIX_DIR}

ENV PATH=${PREFIX_DIR}/osmium-tool/bin:${PATH}

VOLUME /data

WORKDIR /data
