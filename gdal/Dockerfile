# ARG BUILDER_IMAGE=ubuntu:22.04
# ARG TARGET_IMAGE=ubuntu:22.04
ARG BUILDER_IMAGE=ubuntu:24.04
ARG TARGET_IMAGE=ubuntu:24.04

FROM ${BUILDER_IMAGE} AS builder

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
		libdeflate-dev \
		libzstd-dev \
		libpq-dev \
		libopenjp2-7-dev \
    libmuparser-dev \  
	&& apt-get -y --purge autoremove \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

COPY ./gdal .

RUN mkdir -p ./build \
	&& cd ./build \
	&& cmake .. \
		-DCMAKE_BUILD_TYPE=Release \
	  -DCMAKE_INSTALL_RPATH='$ORIGIN/../lib' \
		-DCMAKE_INSTALL_PREFIX=${PREFIX_DIR}/gdal \
	&& cmake --build . --parallel $(nproc) \
	&& cmake --build . --target install


FROM ${TARGET_IMAGE} AS final

ARG PREFIX_DIR=/usr/local/opt

# ubuntu 22.04
# RUN DEBIAN_FRONTEND=noninteractive apt-get update -y \
# 	&& apt-get install -y \
# 		libproj22 \
# 		libsqlite3-0 \
# 		librasterlite2-1 \
# 		libspatialite7 \
# 		libpng16-16 \
# 		libjpeg-turbo8 \
# 		libgif7 \
# 		libwebp7 \
# 		libtiff5 \
# 	&& apt-get -y --purge autoremove \
# 	&& apt-get clean \
# 	&& rm -rf /var/lib/apt/lists/*

# ubuntu 24.04
RUN DEBIAN_FRONTEND=noninteractive apt-get update -y \
	&& apt-get install -y \
		ca-certificates \
		python3 \
		python3-numpy \
		libcurl4t64 \
		libpython3.12 \
		libgeos3.12.1 \
		libgeos-c1v5 \
		libproj25 \
		libsqlite3-0 \
		librasterlite2-1 \
		libspatialite8 \
		libpng16-16t64 \
		libjpeg-turbo8 \
		libgif7 \
		libwebp7 \
		libtiff6 \
		libexpat1 \
		libxerces-c3.2 \
		libdeflate0 \
		libzstd1 \
		libpq5 \
		libopenjp2-7 \
		libmuparser2v5 \
		libtcmalloc-minimal4 \
	&& apt-get -y --purge autoremove \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

COPY --from=builder ${PREFIX_DIR} ${PREFIX_DIR}

ENV PATH=${PREFIX_DIR}/gdal/bin:${PATH}
ENV LD_LIBRARY_PATH=${PREFIX_DIR}/gdal/lib
ENV PYTHONPATH=${PREFIX_DIR}/gdal/local/lib/python3.12/dist-packages

VOLUME /data

WORKDIR /data
