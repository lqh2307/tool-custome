ARG BUILDER_IMAGE=ubuntu:24.04
ARG TARGET_IMAGE=ubuntu:24.04

# Build mapserver
FROM ${BUILDER_IMAGE} AS mapserver-builder

ARG PREFIX_DIR=/usr/local/opt

RUN DEBIAN_FRONTEND=noninteractive apt-get update -y \
	&& apt-get upgrade -y \
	&& apt-get install -y \
		build-essential \
		cmake \
		libprotobuf-c-dev \
		libpng-dev \
		libjpeg-dev \
		libgif-dev \
		libproj-dev \
		libgdal-dev \
		libgeos-dev \
		libxml2-dev \
		libcurl4-openssl-dev \
		libsqlite3-dev \
		libpq-dev \
		libfcgi-dev \
		libfreetype6-dev \
		libfribidi-dev \
		libharfbuzz-dev \
		libcairo2-dev \
		zlib1g-dev \
	&& apt-get -y --purge autoremove \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

COPY ./mapserver .

RUN mkdir -p ./build \
	&& cd ./build \
	&& cmake .. \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_INSTALL_PREFIX=${PREFIX_DIR}/mapserver \
		-DWITH_CLIENT_WMS=ON \
		-DWITH_CLIENT_WFS=ON \
		-DWITH_SOS=ON \
	&& cmake --build . --parallel $(nproc) \
	&& cmake --build . --target install


# Build target
FROM ${TARGET_IMAGE} AS final

ARG PREFIX_DIR=/usr/local/opt

RUN DEBIAN_FRONTEND=noninteractive apt-get update -y \
	&& apt-get install -y \
		libprotobuf-c1 \
		libpng16-16t64 \
		libjpeg-turbo8 \
		libgif7 \
		libproj25 \
		libgdal34 \
		libgeos-c1t64 \
		libxml2 \
		libcurl4t64 \
		libsqlite3-0 \
		libpq5 \
		libfcgi0t64 \
		libfreetype6 \
		libfribidi0 \
		libharfbuzz0b \
		libcairo2 \
		zlib1g \
	&& apt-get -y --purge autoremove \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

COPY --from=mapserver-builder ${PREFIX_DIR} ${PREFIX_DIR}

ENV PATH=${PREFIX_DIR}/mapserver/bin:${PATH}

VOLUME /data

WORKDIR /data
