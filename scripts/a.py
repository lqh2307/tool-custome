#!/usr/bin/env python3
import os
import io
import math
import sqlite3
import argparse
import tempfile
from pathlib import Path
from multiprocessing import Pool, cpu_count

import rasterio
import numpy as np
import mercantile

from PIL import Image
from rasterio.warp import calculate_default_transform, reproject, Resampling, transform_bounds
from rasterio.windows import from_bounds


def init_mbtiles(path):
    conn = sqlite3.connect(path)
    cur = conn.cursor()

    cur.executescript("""
    CREATE TABLE IF NOT EXISTS metadata (name TEXT, value TEXT);
    CREATE TABLE IF NOT EXISTS tiles (
        zoom_level INTEGER,
        tile_column INTEGER,
        tile_row INTEGER,
        tile_data BLOB
    );
    CREATE UNIQUE INDEX IF NOT EXISTS tile_index
    ON tiles (zoom_level, tile_column, tile_row);
    """)

    conn.commit()
    return conn


def write_metadata(conn, meta):
    cur = conn.cursor()
    cur.execute("DELETE FROM metadata")
    for k, v in meta.items():
        cur.execute("INSERT INTO metadata (name, value) VALUES (?, ?)", (k, str(v)))
    conn.commit()


def get_max_zoom(resolution):
    initial_resolution = 2 * math.pi * 6378137 / 256
    return int(round(math.log(initial_resolution / resolution, 2)))


def expand_palette(band, cmap):
    h, w = band.shape
    rgba = np.zeros((h, w, 4), dtype=np.uint8)

    for k, v in cmap.items():
        mask = band == k
        rgba[mask] = v

    return rgba


def read_rgba(ds, window, fallback_palette=None):
    count = ds.count

    if count == 1:
        band = ds.read(1, window=window)

        cmap = None
        try:
            cmap = ds.colormap(1)
        except:
            pass

        if cmap:
            return expand_palette(band, cmap)
        elif fallback_palette:
            return expand_palette(band, fallback_palette)
        else:
            return np.stack([band, band, band, np.full_like(band, 255)], axis=-1)

    else:
        data = ds.read([1, 2, 3], window=window)
        data = np.moveaxis(data, 0, -1)

        if count >= 4:
            alpha = ds.read(4, window=window)
        else:
            alpha = np.full(data.shape[:2], 255, dtype=np.uint8)

        return np.dstack([data, alpha])


def reproject_to_tempfile(src_path):
    src = rasterio.open(src_path)

    fallback_palette = None
    if src.count == 1:
        try:
            fallback_palette = src.colormap(1)
        except:
            pass

    transform, width, height = calculate_default_transform(
        src.crs, "EPSG:3857", src.width, src.height, *src.bounds
    )

    kwargs = src.meta.copy()
    kwargs.update({
        "crs": "EPSG:3857",
        "transform": transform,
        "width": width,
        "height": height
    })

    tmp = tempfile.NamedTemporaryFile(suffix=".tif", delete=False)
    tmp.close()

    with rasterio.open(tmp.name, "w", **kwargs) as dst:
        for i in range(1, src.count + 1):
            reproject(
                source=rasterio.band(src, i),
                destination=rasterio.band(dst, i),
                src_transform=src.transform,
                src_crs=src.crs,
                dst_transform=transform,
                dst_crs="EPSG:3857",
                resampling=Resampling.nearest
            )

    return tmp.name, fallback_palette


def render_tile(args):
    tif_path, fallback_palette, t, tile_size = args

    with rasterio.open(tif_path) as ds:
        bbox_ll = mercantile.bounds(t)

        minx, miny, maxx, maxy = transform_bounds(
            "EPSG:4326", ds.crs,
            bbox_ll.west, bbox_ll.south,
            bbox_ll.east, bbox_ll.north
        )

        window = from_bounds(minx, miny, maxx, maxy, ds.transform)

        try:
            rgba = read_rgba(ds, window, fallback_palette)
        except:
            return None

        if rgba.size == 0:
            return None

        img = Image.fromarray(rgba, mode="RGBA")
        img = img.resize((tile_size, tile_size), Image.NEAREST)

        buf = io.BytesIO()
        img.save(buf, format="PNG", optimize=True)

        tms_y = (2 ** t.z - 1) - t.y

        return (t.z, t.x, tms_y, buf.getvalue())


def main(input_tif, output_mbtiles, tile_size=256, workers=None):
    print("Reprojecting to EPSG:3857...")
    temp_tif, fallback_palette = reproject_to_tempfile(input_tif)

    with rasterio.open(temp_tif) as ds:
        res = ds.res[0]
        maxzoom = get_max_zoom(res)
        print("Auto maxzoom:", maxzoom)

        min_lon, min_lat, max_lon, max_lat = transform_bounds(
            ds.crs, "EPSG:4326",
            ds.bounds.left, ds.bounds.bottom,
            ds.bounds.right, ds.bounds.top
        )

    tiles = list(mercantile.tiles(min_lon, min_lat, max_lon, max_lat, maxzoom))
    print("Total tiles:", len(tiles))

    conn = init_mbtiles(output_mbtiles)
    cur = conn.cursor()

    args = [(temp_tif, fallback_palette, t, tile_size) for t in tiles]

    if not workers:
        workers = max(1, cpu_count() - 1)

    print("Workers:", workers)

    inserted = 0

    with Pool(workers) as pool:
        for result in pool.imap_unordered(render_tile, args, chunksize=50):
            if not result:
                continue

            z, x, y, data = result

            cur.execute(
                "INSERT OR REPLACE INTO tiles (zoom_level, tile_column, tile_row, tile_data) VALUES (?, ?, ?, ?)",
                (z, x, y, data)
            )

            inserted += 1
            if inserted % 200 == 0:
                print("Inserted:", inserted)

    meta = {
        "name": Path(input_tif).stem,
        "format": "png",
        "minzoom": maxzoom,
        "maxzoom": maxzoom,
        "bounds": f"{min_lon},{min_lat},{max_lon},{max_lat}",
        "type": "overlay",
        "version": "1.0"
    }

    write_metadata(conn, meta)
    conn.close()

    os.remove(temp_tif)

    print("DONE")
    print("Inserted tiles:", inserted)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("input")
    parser.add_argument("output")
    parser.add_argument("--workers", type=int, default=None)
    args = parser.parse_args()

    main(args.input, args.output, workers=args.workers)
