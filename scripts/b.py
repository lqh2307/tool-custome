from multiprocessing import Pool
import rasterio
from rasterio.windows import Window
from rasterio.enums import Resampling
from rasterio.warp import calculate_default_transform, reproject
import numpy as np
import os
import tempfile


def palette_to_rgba_worker(args):
    window, data, lut = args

    return window, lut[data].transpose(2, 0, 1)


def expand_palette_to_rgba(src, dst_path, compression=True, workers=4):
    profile = src.profile.copy()
    profile.update({
        "count": 4,
        "dtype": "uint8",
        "photometric": "RGB",
        "interleave": "pixel"
    })

    if compression:
        profile.update(
            compress="LZW",
            predictor=2,
        )

    # ===== Build LUT once =====
    lut = np.zeros((256, 4), dtype=np.uint8)
    for k, v in src.colormap(1).items():
        if len(v) == 3:
            lut[k] = (*v, 255)
        else:
            lut[k] = v

    block_h, block_w = src.block_shapes[0]

    def task_gen():
        for y in range(0, src.height, block_h):
            h = min(block_h, src.height - y)

            for x in range(0, src.width, block_w):
                window = Window(x, y, min(block_w, src.width - x), h)

                yield (window, src.read(1, window=window), lut)

    with rasterio.open(dst_path, "w", **profile) as dst:

        # ========= SINGLE =========
        if workers == 1:
            for data in task_gen():
                window, rgba = palette_to_rgba_worker(data)

                dst.write(rgba, window=window)

        # ========= MULTI =========
        else:
            with Pool(workers) as pool:
                for window, rgba in pool.imap_unordered(palette_to_rgba_worker, task_gen()):
                    dst.write(rgba, window=window)

    return dst_path



def reproject_streaming(src_path, dst_path, dst_crs="EPSG:3857"):
    with rasterio.open(src_path) as src:
        transform, width, height = calculate_default_transform(
            src.crs, dst_crs, src.width, src.height, *src.bounds
        )

        profile = src.profile.copy()
        profile.update({
            "crs": dst_crs,
            "transform": transform,
            "width": width,
            "height": height
        })

        with rasterio.open(dst_path, "w", **profile) as dst:
            for b in range(1, src.count + 1):
                reproject(
                    source=rasterio.band(src, b),
                    destination=rasterio.band(dst, b),
                    src_transform=src.transform,
                    src_crs=src.crs,
                    dst_transform=transform,
                    dst_crs=dst_crs,
                    resampling=Resampling.nearest
                )


def convert_geotiff(src_path, dst_path, dst_crs="EPSG:3857"):
    with rasterio.open(src_path) as src:
        if src.colorinterp[0].name == "palette" and src.colormap(1) is not None:
            print("Detected palette raster → expanding to RGBA first")

            with tempfile.NamedTemporaryFile(suffix=".tif", delete=False) as tmp:
                tmp_path = tmp.name

            expand_palette_to_rgba(src, tmp_path, True)
            reproject_streaming(tmp_path, dst_path, dst_crs)

            os.remove(tmp_path)
        else:
            print("Normal raster → direct reprojection")
            reproject_streaming(src_path, dst_path, dst_crs)


if __name__ == "__main__":
    src = "datatest/NC-48_2.tif"
    dst = "datatest/NC-48_2_3857_rgba.tif"

    convert_geotiff(src, dst)
