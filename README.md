# tool-custom

Tool custome

git add . && git commit -m "1.0.0" && git push
docker build -t quanghuy2307/spatial-tool:1.0.0 .
docker push quanghuy2307/spatial-tool:1.0.0
docker run --rm -it -v D:\data-main\sources\tool-custome\datatest:/data quanghuy2307/spatial-tool:1.0.0 bash

extract_mbtiles -o data/merged.mbtiles -i data/NC-48_1.mbtiles data/NC-48_2.mbtiles data/NC-48_3.mbtiles data/NC-48_4.mbtiles -ms merge -ovr -w 8 -ei -r lanczos -c -mi -ti -bz 1000

download_elevation_tiles -b 96,4,120,28 -w 8 -o srmt
