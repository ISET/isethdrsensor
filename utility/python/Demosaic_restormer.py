# import numpy as np
import cv2
import pyexr
import onnxruntime as ort
import os
import numpy as np

os.environ["OPENCV_IO_ENABLE_OPENEXR"] = "1"

def demosaic(model_path, input_path, output_path):
    def pad_image(img, target_height, target_width):
        height, width, channels = img.shape
        pad_height = (target_height - height % target_height) % target_height
        pad_width = (target_width - width % target_width) % target_width
        return np.pad(img, ((0, pad_height), (0, pad_width), (0, 0)), mode='reflect') 

    def crop_and_infer(img, target_height, target_width, original_height, original_width, output_channels):
        padded_img = pad_image(img, target_height, target_width)
        padded_height, padded_width, _ = padded_img.shape
        output_image = np.zeros((original_height, original_width, output_channels), dtype=np.float32)
        ort_sess = ort.InferenceSession(model_path)

        for i in range(0, padded_height, target_height):
            for j in range(0, padded_width, target_width):
                # Determine the segment size, considering boundaries
                segment_height = min(target_height, padded_height - i)
                segment_width = min(target_width, padded_width - j)

                # Crop the segment
                crop_img = padded_img[i:i + segment_height, j:j + segment_width]
                crop_img = np.transpose(crop_img, (2, 0, 1))
                crop_img = np.expand_dims(crop_img, axis=0)
                restored = ort_sess.run(None, {'input': crop_img})
                restored = np.transpose(restored[0], (0, 2, 3, 1))[0, :segment_height, :segment_width, :]

                end_i = min(i + target_height, original_height)
                end_j = min(j + target_width, original_width)

                # Place the restored segment back into the output image
                output_image[i:i + segment_height, j:j + segment_width] = restored[:min(segment_height, end_i - i), :min(segment_width, end_j - j)]

        return output_image

    img = pyexr.read(input_path).astype(np.float32)
    img[np.isnan(img)] = 0  # Handle NaNs if present
    original_height, original_width, channels = img.shape

    # Check if the input is RGB or RGBW
    if channels == 3:
        print("INFO: Input image is RGB")
        output_channels = 3
    elif channels == 4:
        print("INFO: Input image is RGBW")
        output_channels = 4
    else:
        raise ValueError("Unsupported number of channels. Expected 3 (RGB) or 4 (RGBW).")

    processed_img = crop_and_infer(img, 512, 512, original_height, original_width, output_channels)
    if channels ==3:
        cv2.imwrite(output_path, cv2.cvtColor(processed_img, cv2.COLOR_RGB2BGR), [cv2.IMWRITE_EXR_TYPE, cv2.IMWRITE_EXR_TYPE_FLOAT])
    elif channels ==4:
        cv2.imwrite(output_path, processed_img, [cv2.IMWRITE_EXR_TYPE, cv2.IMWRITE_EXR_TYPE_FLOAT])
        
    print("INFO: Demosaicing is successfully completed.")

# Example usage
# demosaic('/Users/zhenyi/git_repo/dev/isethdrsensor/networks/NNDemosaicRGB.onnx', 
#          "/Users/zhenyi/git_repo/dev/isethdrsensor/local/exr/20-May-2024/10H23S-rgb-1.00.exr", 
#          '/Users/zhenyi/git_repo/dev/isethdrsensor/local/exr/20-May-2024/10H23S-rgb-1.00-ip.exr')
