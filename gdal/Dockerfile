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
 	&& rm -rf ./gdal*


FROM ${TARGET_IMAGE} AS final

ARG PREFIX_DIR=/usr/local/opt

# ubuntu 22.04
RUN DEBIAN_FRONTEND=noninteractive apt-get update -y \
	&& apt-get install -y \
		libproj22 \
		libsqlite3-0 \
		librasterlite2-1 \
		libspatialite7 \
		libpng16-16 \
		libjpeg-turbo8 \
		libgif7 \
		libwebp7 \
		libtiff5 \
	&& apt-get -y --purge autoremove \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

# ubuntu 24.04
# RUN DEBIAN_FRONTEND=noninteractive apt-get update -y \
# 	&& apt-get install -y \
# 		libproj25 \
# 		libsqlite3-0 \
# 		librasterlite2-1 \
# 		libspatialite8 \
# 		libpng16-16 \
# 		libjpeg-turbo8 \
# 		libgif7 \
# 		libwebp7 \
# 		libtiff6 \
# 	&& apt-get -y --purge autoremove \
# 	&& apt-get clean \
# 	&& rm -rf /var/lib/apt/lists/*

COPY --from=builder ${PREFIX_DIR} ${PREFIX_DIR}

ENV PATH=${PREFIX_DIR}/gdal/bin:${PATH}

VOLUME /data

WORKDIR /data
