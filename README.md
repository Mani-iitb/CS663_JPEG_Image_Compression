# Image Compression Algorithms from Scratch

This repository contains a comprehensive set of image compression algorithms implemented from scratch in matlab, with a major focus on the **JPEG compression algorithm**. The project explores the performance, efficiency, and quality of compression for both grayscale and color images. Additional techniques like **Bitplane Slicing** and **PCA + JPEG Hybrid** compression have also been implemented and evaluated.

## Features

- Complete implementation of **JPEG compression** for grayscale and color images.
- Support for **Differential Pulse-Code Modulation (DPCM)** and **Huffman Encoding**.
- Bitplane slicing-based compression.
- Experimental hybrid compression using PCA and JPEG.
- Evaluation metrics: **Compression Ratio**, **RMSE**, **Bits Per Pixel (BPP)**.
- Graphs and plots comparing quality and compression efficiency across varying Q values.

---

## JPEG Algorithm Overview

### Encoding Steps

1. **Preprocessing**:
   - Zero-padding of grayscale image to form perfect 8×8 blocks.

2. **DCT & Quantization**:
   - DCT applied to each block.
   - Quantization matrix scaled using `50/Q`.

3. **Zig-Zag + RLE + DPCM**:
   - Zig-zag scan per block.
   - DC values encoded using DPCM.
   - AC values encoded with RLE.

4. **Huffman Coding**:
   - Frequency calculation of encoded values.
   - Huffman tables generated for AC and DC components.
   - Metadata and compressed bitstream written to file.

### Decoding Steps

1. Read metadata and Huffman tables.
2. Huffman decode AC and DC streams.
3. Perform de-zigzag, inverse DPCM.
4. Inverse quantization and inverse DCT.
5. Reconstruct the image block-wise.

---

## Color Image Compression

1. Convert RGB to YCbCr.
2. Apply grayscale JPEG compression independently to each Y, Cb, Cr layer.
3. Store compressed streams and metadata.
4. Decode and reconstruct each layer, then convert YCbCr back to RGB.

---

## Datasets Used

- **Grayscale Images**: 20 unrelated images from Kaggle, named `image_01` to `image_20`.
- **Color Images**: 17 diverse fox images from Kaggle, named `img01` to `img17`.

---

## Performance Evaluation

### Quality Metrics:
- **Root Mean Square Error (RMSE)**
- **Bits Per Pixel (BPP)**

### Graphs:
- **RMSE vs BPP** for multiple Q values.
- **Average RMSE** across images for each Q.
- **Average Compression Ratio** vs Q.

---

## Additional Compression Techniques

### Bitplane Slicing Compression
- 4 MSBs extracted and compressed using DPCM + Huffman coding.
- High compression, but higher RMSE.

### PCA + JPEG Hybrid
- 8×8 patches undergo PCA.
- Eigen coefficients compressed with JPEG.
- Decompression shows visible block artifacts; used for experimentation.

---

## Sample Results

| Q | Grayscale Reconstruction | Color Reconstruction |
|---|--------------------------|-----------------------|
| 5 | High compression, blurry | Same                 |
| 55| Balanced                 | Balanced             |
| 85| Low compression, high quality | Same         |

---

## Technologies Used

- Language: **Matlab**
- Image format: Grayscale & RGB
- File I/O: Custom binary file formats with headers for metadata

---

## Future Improvements

- Implement JPEG2000 or WebP-like wavelet-based compression.
- Add GUI for compression demo.
- Integrate multithreaded block processing for speedup.

---

## Author

**Manivannan**  
M.Tech - Computer Science, IIT Bombay
