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
      liblua5.4-dev \
      libsqlite3-dev \
      libshp-dev \
      libboost-program-options-dev \
      libboost-filesystem-dev \
      libboost-system-dev \
      rapidjson-dev \
      luarocks \
  && luarocks install luaflock \
	&& apt-get -y --purge autoremove \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

COPY ./tilemaker .

RUN mkdir -p ./build \
  && cd ./build \
  && cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=${PREFIX_DIR}/tilemaker \
  && cmake --build . --parallel $(nproc) \
  && cmake --build . --target install


FROM ${TARGET_IMAGE} AS final

ARG PREFIX_DIR=/usr/local/opt

# ubuntu 22.04
RUN DEBIAN_FRONTEND=noninteractive apt-get update -y \
	&& apt-get install -y \
    liblua5.4-0 \
    shapelib \
    libsqlite3-0 \
    lua-sql-sqlite3 \
    libboost-filesystem1.74.0 \
    libboost-program-options1.74.0 \
    libboost-system1.74.0 \
	&& apt-get -y --purge autoremove \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

# ubuntu 24.04
# RUN DEBIAN_FRONTEND=noninteractive apt-get update -y \
# 	&& apt-get install -y \
#     liblua5.4-0 \
#     shapelib \
#     libsqlite3-0 \
#     lua-sql-sqlite3 \
#     libboost-filesystem1.83.0 \
#     libboost-program-options1.83.0 \
#     libboost-system1.83.0 \
# 	&& apt-get -y --purge autoremove \
# 	&& apt-get clean \
# 	&& rm -rf /var/lib/apt/lists/*

COPY --from=builder ${PREFIX_DIR} ${PREFIX_DIR}

ENV PATH=${PREFIX_DIR}/tilemaker/bin:${PATH}

VOLUME /data

WORKDIR /data
