ARG BUILDER_IMAGE=ubuntu:24.04
ARG TARGET_IMAGE=ubuntu:24.04

# Build tilemaker
FROM ${BUILDER_IMAGE} AS tilemaker-builder

ARG BUILD_NUM_PROCESS
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

RUN cd ./tilemaker \
	&& mkdir -p ./build \
	&& cd ./build \
	&& cmake .. \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_INSTALL_PREFIX=${PREFIX_DIR}/tilemaker \
	&& cmake --build . --parallel ${BUILD_NUM_PROCESS:-$(nproc)} \
	&& cmake --build . --target install \
	&& cd ../.. \
	&& rm -rf ./tilemaker


# Build gdal
FROM ${BUILDER_IMAGE} AS gdal-builder

ARG BUILD_NUM_PROCESS
ARG PREFIX_DIR=/usr/local/opt

RUN DEBIAN_FRONTEND=noninteractive apt-get update -y \
	&& apt-get upgrade -y \
	&& apt-get install -y \
 		build-essential \
		cmake \
		swig \
		autoconf \
		automake \
		python3-dev \
		python3-numpy \
		python3-setuptools \
		libcurl4-openssl-dev \
		libgeos-dev \
		libproj-dev \
		libsqlite3-dev \
		librasterlite2-dev \
		libspatialite-dev \
		libpng-dev \
		libjpeg-dev \
		libgif-dev \
		libwebp-dev \
		libtiff-dev \
		libexpat-dev \
		libxerces-c-dev \
		libzstd-dev \
		libpq-dev \
		libopenjp2-7-dev \
		libmuparser-dev \ 
		libhdf4-alt-dev \
		libhdf5-serial-dev \
		libxml2-dev \
		libcairo2-dev \
		libpcre3-dev \
		libkml-dev \
		libheif-dev \
		libavif-dev \
		libdeflate-dev \
		liblz4-dev \
		libbz2-dev \
		libblosc-dev \
		libbrotli-dev \
		libarchive-dev \
		libaec-dev \
		liblzma-dev \
		libfreexl-dev \
		openjdk-21-jdk \
	&& apt-get -y --purge autoremove \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

COPY ./gdal .

RUN cd ./gdal \
	&& mkdir -p ./build \
	&& cd ./build \
	&& cmake .. \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_INSTALL_RPATH='$ORIGIN/../lib' \
		-DCMAKE_INSTALL_PREFIX=${PREFIX_DIR}/gdal \
	&& cmake --build . --parallel ${BUILD_NUM_PROCESS:-$(nproc)} \
	&& cmake --build . --target install \
	&& cd ../.. \
	&& rm -rf ./gdal


# Build target
FROM ${TARGET_IMAGE} AS final

ARG PREFIX_DIR=/usr/local/opt

RUN DEBIAN_FRONTEND=noninteractive apt-get update -y \
	&& apt-get install -y \
		python3 \
		python3-pip \
		python3-venv \
		python3-numpy \
		python3-jsonschema \
		liblua5.4-0 \
		shapelib \
		libsqlite3-0 \
		lua-sql-sqlite3 \
		libboost-filesystem1.83.0 \
		libboost-program-options1.83.0 \
		libboost-system1.83.0 \
		zlib1g \
		osmosis \
		libcurl4 \
		libpython3.12 \
		libgeos-3.12.1 \
		libgeos-c1v5 \
		libproj25 \
		librasterlite2-1 \
		libspatialite8 \
		libpng16-16 \
		libjpeg-turbo8 \
		libgif7 \
		libwebp7 \
		libtiff6 \
		libbz2-1.0 \
		liblz4-1 \
		libexpat1 \
		libxerces-c3.2 \
		libzstd1 \
		libpq5 \
		libopenjp2-7 \
		libmuparser2v5 \
		libtcmalloc-minimal4 \
		libhdf4-0-alt \
		libhdf5-103-1 \
		libxml2 \
		libcairo2 \
		libpcre3 \
		libkmlbase1 \
		libkmlconvenience1 \
		libkmldom1 \
		libkmlengine1 \
		libkmlregionator1 \
		libkmlxsd1 \
		libheif1 \
		libavif16 \
		libdeflate0 \
		libblosc1 \
		libbrotli1 \
		libarchive13 \
		libaec0 \
		liblzma5 \
		libfreexl1 \
		openjdk-21-jre \
		zip \
		unzip \
		tar \
		gzip \
		xz-utils \
		bzip2 \
		zstd \
		p7zip-full \
		rar \
	&& python3 -m venv ${PREFIX_DIR}/venv \
	&& ${PREFIX_DIR}/venv/bin/pip install --no-cache-dir Pillow rasterio mapbox-vector-tile \
	&& apt-get -y --purge autoremove \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/* \
	&& rm -rf /root/.cache/pip

COPY --from=tilemaker-builder ${PREFIX_DIR} ${PREFIX_DIR}
COPY --from=gdal-builder ${PREFIX_DIR} ${PREFIX_DIR}
COPY ./scripts ${PREFIX_DIR}/scripts

ENV PATH=${PREFIX_DIR}/venv/bin:${PREFIX_DIR}/tilemaker/bin:${PREFIX_DIR}/gdal/bin:${PREFIX_DIR}/gdal/local/bin:${PREFIX_DIR}/scripts:${PATH}
ENV LD_LIBRARY_PATH=${PREFIX_DIR}/gdal/lib
ENV PYTHONPATH=${PREFIX_DIR}/gdal/local/lib/python3.12/dist-packages

VOLUME /data

WORKDIR /data
