# tool-custom

Tool custome

git add . && git commit -m "1.0.0" && git push
docker build -t quanghuy2307/spatial-tool:1.0.0 .
docker push quanghuy2307/spatial-tool:1.0.0
docker run --rm -it -v C:\Users\ACER\Downloads\sources\tool-custome\datatest:/data quanghuy2307/spatial-tool:1.0.0 bash

GDAL_NUM_THREADS=ALL_CPUS gdal_translate -expand rgba -co BIGTIFF=YES -co COMPRESS=LZW -co PREDICTOR=2 -co TILED=YES -co BLOCKXSIZE=512 -co BLOCKYSIZE=512
gdal_translate -r lanczos -co TILE_FORMAT=PNG -co ZLEVEL=9
GDAL_NUM_THREADS=ALL_CPUS gdaladdo -r lanczos

extract_mbtiles -o data/merged.mbtiles -i data/NC-48_1.mbtiles data/NC-48_2.mbtiles data/NC-48_3.mbtiles data/NC-48_4.mbtiles -ms merge -ovr -w 8 -ei

docker run --name spatial-tool --rm -it -v D:\srmt:/data quanghuy2307/spatial-tool:1.0.0 bash

download_elevation_tiles -b 96,4,120,28 -w 512 -o srmt

find /data/srmt -type f -name "\*.hgt" > hgt_list.txt
GDAL_NUM_THREADS=ALL_CPUS gdalbuildvrt elevation.vrt -input_file_list hgt_list.txt \
&& GDAL_NUM_THREADS=ALL_CPUS gdal_translate -co COMPRESS=DEFLATE -co PREDICTOR=2 -co BIGTIFF=YES -co TILED=YES -co BLOCKXSIZE=512 -co BLOCKYSIZE=512 elevation.vrt elevation.tif \
&& GDAL_NUM_THREADS=ALL_CPUS gdalwarp -dstnodata 0 -co COMPRESS=DEFLATE -co PREDICTOR=2 -co BIGTIFF=YES -co TILED=YES -co BLOCKXSIZE=512 -co BLOCKYSIZE=512 elevation.tif elevation_tmp.tif \
&& mv elevation_tmp.tif elevation.tif \
&& dem_to_rgb -in elevation.tif -out elevation_tmp.tif -c -w 4 \
&& mv elevation_tmp.tif elevation.tif \
&& GDAL_NUM_THREADS=ALL_CPUS gdal_translate -r lanczos -co NAME=elevation -co VERSION=1.0.0 -co TILE_FORMAT=PNG -co ZLEVEL=9 -co BLOCKSIZE=256 elevation.tif elevation.mbtiles \
&& GDAL_NUM_THREADS=ALL_CPUS gdaladdo -r lanczos elevation.mbtiles
