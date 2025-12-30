ARG BUILDER_IMAGE=ubuntu:24.04
ARG TARGET_IMAGE=ubuntu:24.04

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
		osmosis \
		libproj25 \
		librasterlite2-1 \
		libspatialite8 \
		libpng16-16 \
		libjpeg-turbo8 \
		libgif7 \
		libwebp7 \
		libtiff6 \
	&& apt-get -y --purge autoremove \
	&& apt-get clean \
	&& /var/lib/apt/lists/*

COPY --from=tilemaker-builder ${PREFIX_DIR} ${PREFIX_DIR}
COPY --from=gdal-builder ${PREFIX_DIR} ${PREFIX_DIR}

ENV PATH=${PREFIX_DIR}/scripts:${PREFIX_DIR}/tilemaker/bin:${PREFIX_DIR}/gdal/bin:${PATH}

VOLUME /data

WORKDIR /data
