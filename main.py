from itertools import product

import numpy as np
import typer
from PIL import Image
from pydantic import field_validator
from pydantic.dataclasses import dataclass


@dataclass
class Size:
    """
    A simple class to represent image size.
    """

    width: int
    height: int

    @field_validator("width", "height")
    @classmethod
    def one_or_more(cls, v):
        if v < 1:
            raise ValueError("Width and height must be one or more.")
        return v


def quantize_image_with_median(img: Image.Image, size: Size) -> Image.Image:
    """
    Quantize the image to the specified size using median color values.

    Args:
        img (PIL.Image.Image): The input image to be quantized.
        size (Size): The target size for quantization.
    Returns:
        PIL.Image.Image: The quantized image.
    """
    original_size = Size(*img.size)
    image_pixels = np.array(img)

    block_size = Size(
        width=original_size.width // size.width,
        height=original_size.height // size.height,
    )

    quantized = np.zeros(
        (size.width, size.height, image_pixels.shape[2]), dtype=image_pixels.dtype
    )
    for x, y in product(range(size.width), range(size.height)):
        x0 = x * block_size.width
        y0 = y * block_size.height

        # if the block is at the edge, ensure it includes all remaining pixels
        x1 = (x + 1) * block_size.width if x < size.width - 1 else original_size.width
        y1 = (
            (y + 1) * block_size.height if y < size.height - 1 else original_size.height
        )

        block = image_pixels[y0:y1, x0:x1]
        median_color = np.median(block.reshape(-1, 3), axis=0).astype(np.uint8)
        quantized[y, x] = median_color

    return Image.fromarray(quantized)


def main(input_path: str, output_path: str, width: int, height: int) -> None:
    """
    The main entry point for the image quantization script.

    Args:
        input_path (str): Path to the input image file.
        output_path (str): Path to save the quantized image.
        width (int): Target width for quantization.
        height (int): Target height for quantization.
    """
    converted_image = quantize_image_with_median(
        Image.open(input_path).convert("RGB"),
        Size(width=width, height=height),
    )
    converted_image.save(output_path)


if __name__ == "__main__":
    typer.run(main)
