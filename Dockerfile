ARG BUILDER_IMAGE=ubuntu:24.04
ARG TARGET_IMAGE=ubuntu:24.04

# Build tilemaker
FROM ${BUILDER_IMAGE} AS tilemaker-builder

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
	&& cmake --build . --parallel $(nproc) \
	&& cmake --build . --target install \
	&& cd ../.. \
	&& rm -rf ./tilemaker


# Build tippecanoe
FROM ${BUILDER_IMAGE} AS tippecanoe-builder

ARG PREFIX_DIR=/usr/local/opt

RUN DEBIAN_FRONTEND=noninteractive apt-get update -y \
	&& apt-get upgrade -y \
	&& apt-get install -y \
		build-essential \
		libsqlite3-dev \
		zlib1g-dev \
	&& apt-get -y --purge autoremove \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

COPY ./tippecanoe .

RUN cd ./tippecanoe \
	&& PREFIX=${PREFIX_DIR}/tippecanoe \
		make -j$(nproc) \
	&& PREFIX=${PREFIX_DIR}/tippecanoe \
		make install \
	&& cd .. \
	&& rm -rf ./tippecanoe


# Build gdal
FROM ${BUILDER_IMAGE} AS gdal-builder

ARG PREFIX_DIR=/usr/local/opt

RUN DEBIAN_FRONTEND=noninteractive apt-get update -y \
	&& apt-get upgrade -y \
	&& apt-get install -y \
		build-essential \
		cmake \
		libproj-dev \
		libsqlite3-dev \
		librasterlite2-dev \
		libspatialite-dev \
		libpng-dev \
		libjpeg-dev \
		libgif-dev \
		libwebp-dev \
		libtiff-dev \
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
	&& cmake --build . --parallel $(nproc) \
	&& cmake --build . --target install \
	&& cd ../.. \
	&& rm -rf ./gdal


# Build osmium-tool
FROM ${BUILDER_IMAGE} AS osmium-tool-builder

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
	&& apt-get -y --purge autoremove \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

COPY ./osmium-tool .

RUN cd ./osmium-tool \
	&& mkdir -p ./build \
	&& cd ./build \
	&& cmake .. \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_INSTALL_PREFIX=${PREFIX_DIR}/osmium-tool \
	&& cmake --build . --parallel $(nproc) \
	&& cmake --build . --target install \
	&& cd ../.. \
	&& rm -rf ./osmium-tool


# Build target
FROM ${TARGET_IMAGE} AS final

ARG PREFIX_DIR=/usr/local/opt

RUN DEBIAN_FRONTEND=noninteractive apt-get update -y \
	&& apt-get install -y \
		python3 \
		python3-numpy \
		python3-rasterio \
		liblua5.4-0 \
		shapelib \
		libsqlite3-0 \
		lua-sql-sqlite3 \
		libboost-filesystem1.83.0 \
		libboost-program-options1.83.0 \
		libboost-system1.83.0 \
		zlib1g \
		osmosis \
		libproj25 \
		librasterlite2-1 \
		libspatialite8 \
		libpng16-16t64 \
		libjpeg-turbo8 \
		libgif7 \
		libwebp7 \
		libtiff6 \
		libosmium2-dev \
		libprotozero-dev \
		nlohmann-json3-dev \
		libbz2-1.0 \
		liblz4-1 \
		libexpat1 \
	&& apt-get -y --purge autoremove \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

COPY --from=tilemaker-builder ${PREFIX_DIR} ${PREFIX_DIR}
COPY --from=tippecanoe-builder ${PREFIX_DIR} ${PREFIX_DIR}
COPY --from=gdal-builder ${PREFIX_DIR} ${PREFIX_DIR}
COPY --from=osmium-tool-builder ${PREFIX_DIR} ${PREFIX_DIR}
COPY ./scripts ${PREFIX_DIR}/scripts

ENV PATH=${PREFIX_DIR}/tilemaker/bin:${PREFIX_DIR}/tippecanoe/bin:${PREFIX_DIR}/gdal/bin:${PATH}:${PREFIX_DIR}/osmium-tool/bin:${PATH}:${PREFIX_DIR}/scripts

VOLUME /data

WORKDIR /data
