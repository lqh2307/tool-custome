# tool-custom

Tool custome

git add . && git commit -m "1.0.0" && git push
docker build --build-arg BUILD_NUM_PROCESS=8 -t quanghuy2307/spatial-tool:1.0.0 .
docker push quanghuy2307/spatial-tool:1.0.0
docker run --rm -it -v D:\data-main\sources\tool-custome\datatest:/data quanghuy2307/spatial-tool:1.0.0 bash

NUM_THREADS=ALL_CPUS GDAL_NUM_THREADS=ALL_CPUS gdal_translate -expand rgba -co BIGTIFF=YES -co COMPRESS=LZW -co PREDICTOR=2 -co TILED=YES -co BLOCKXSIZE=512 -co BLOCKYSIZE=512
NUM_THREADS=ALL_CPUS gdal_translate -r lanczos -co TILE_FORMAT=PNG -co ZLEVEL=9
NUM_THREADS=ALL_CPUS GDAL_NUM_THREADS=ALL_CPUS gdaladdo -r lanczos

extract_mbtiles -o data/merged.mbtiles -i data/NC-48_1.mbtiles data/NC-48_2.mbtiles data/NC-48_3.mbtiles data/NC-48_4.mbtiles -ms merge -ovr -w 8 -ei -r lanczos -c -mi -ti -bz 1000

download_elevation_tiles -b 96,4,120,28 -w 8 -o srmt

find /data/srmt -type f -name "\*.hgt" > hgt_list.txt \
&& dem_to_rgb -in elevation.vrt -out elevation.tif -c -w 16 \
&& NUM_THREADS=ALL_CPUS GDAL_NUM_THREADS=ALL_CPUS gdal_translate -r lanczos -co TILE_FORMAT=PNG -co ZLEVEL=9 elevation.tif elevation.mbtiles \
&& extract_mbtiles -o data/elevation.mbtiles -ovr -w 16 -ei -r lanczos -c

#!/bin/bash

for f in 1M-500K/\*.tif; do
echo "Checking $f..."

# Check if any band has ColorInterpretation = Palette

if gdalinfo "$f" | grep -q 'ColorInterp=Palette'; then
echo " -> Palette detected, converting..."

    dir=$(dirname "$f")
    base=$(basename "$f")
    tmp="$dir/tmp_$base"

    NUM_THREADS=ALL_CPUS GDAL_NUM_THREADS=ALL_CPUS gdal_translate -expand rgba -co BIGTIFF=YES -co COMPRESS=LZW -co PREDICTOR=2 -co TILED=YES -co BLOCKXSIZE=512 -co BLOCKYSIZE=512 "$f" "$tmp" && mv -f "$tmp" "$f"

else
echo " -> No palette, skip"
fi
done

find 1M-500K -type f -name "\*.hgt" > data_list.txt
NUM_THREADS=ALL_CPUS GDAL_NUM_THREADS=ALL_CPUS gdal_translate -r lanczos -co TILE_FORMAT=PNG -co ZLEVEL=9 1M-500K/elevation.vrt elevation.mbtiles
