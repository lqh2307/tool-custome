# tool-custom

Tool custome

git add . && git commit -m "1.0.0" && git push
docker build -t quanghuy2307/spatial-tool:1.0.0 .
docker push quanghuy2307/spatial-tool:1.0.0
docker run --rm -it -v D:\Downloads:/data quanghuy2307/spatial-tool:1.0.0 bash

GDAL_NUM_THREADS=ALL_CPUS gdal_translate -expand rgba -co BIGTIFF=YES -co COMPRESS=LZW -co PREDICTOR=2 -co TILED=YES -co BLOCKXSIZE=512 -co BLOCKYSIZE=512
gdal_translate -r lanczos -co TILE_FORMAT=PNG -co ZLEVEL=9
GDAL_NUM_THREADS=ALL_CPUS gdaladdo -r lanczos

python extract_mbtiles -o datatest/merged.mbtiles -i datatest/NC-48_1.mbtiles datatest/NC-48_2.mbtiles datatest/NC-48_3.mbtiles datatest/NC-48_4.mbtiles -ms merge
