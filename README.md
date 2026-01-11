# tool-custom

Tool custome

git add . && git commit -m "1.0.0" && git push
docker build -t quanghuy2307/spatial-tool:1.0.0 .
docker push quanghuy2307/spatial-tool:1.0.0
docker run --rm -it -v D:\data-main\sources\tool-custome\datatest:/data quanghuy2307/spatial-tool:1.0.0 bash

NUM_THREADS=ALL_CPUS GDAL_NUM_THREADS=ALL_CPUS gdal_translate -expand rgba -co BIGTIFF=YES -co COMPRESS=LZW -co PREDICTOR=2 -co TILED=YES -co BLOCKXSIZE=512 -co BLOCKYSIZE=512
NUM_THREADS=ALL_CPUS gdal_translate -r lanczos -co TILE_FORMAT=PNG -co ZLEVEL=9
NUM_THREADS=ALL_CPUS GDAL_NUM_THREADS=ALL_CPUS gdaladdo -r lanczos

extract_mbtiles -o data/merged.mbtiles -i data/NC-48_1.mbtiles data/NC-48_2.mbtiles data/NC-48_3.mbtiles data/NC-48_4.mbtiles -ms merge -ovr -w 8 -ei

download_elevation_tiles -b 96,4,120,28 -w 8 -o srmt

find /data/srmt -type f -name "*.hgt" > hgt_list.txt \
&& dem_to_rgb -in elevation.vrt -out elevation.tif -c -w 16 \
&& NUM_THREADS=ALL_CPUS GDAL_NUM_THREADS=ALL_CPUS gdal_translate -r lanczos -co TILE_FORMAT=PNG -co ZLEVEL=9 elevation.tif elevation.mbtiles \
&& extract_mbtiles -o data/elevation.mbtiles -ovr -w 16 -ei -r lanczos -c
