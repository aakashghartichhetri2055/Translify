# Model
MODEL_ID = "microsoft/trocr-base-printed"

# Preprocessing
UPSCALE_MIN_WIDTH = 1200  # narrower images get upscaled

# Gamma thresholds (avg brightness 0-255)
GAMMA_VERY_DARK = 85   # gamma 0.5
GAMMA_DARK      = 127  # gamma 0.75
GAMMA_BRIGHT    = 180  # gamma 1.5

INVERT_THRESHOLD = 100  # only used when bgr is not passed to preprocess
DENOISE_H = 10          # higher = stronger denoise, slower

# Thresholding (must be odd block size)
ADAPTIVE_BLOCK_SIZE = 31  # larger tolerates gradients better
ADAPTIVE_C = 10           # higher rejects more noise, lower catches faint text

# Region detection
H_KERNEL_WIDTH = 25

MAX_LINE_HEIGHT_RATIO = 0.20  # drop contours taller than this fraction of image
MIN_REGION_W = 15
MIN_REGION_H = 8

# Line merging: vertical overlap as fraction of shorter region's height.
# 0.3 = aggressive, 0.7 = conservative
VERTICAL_OVERLAP_THRESH = 0.7

# Recognition (TrOCR)
NUM_BEAMS = 3        # wider = more accurate, slower
MAX_NEW_TOKENS = 64
MIN_CROP_PX = 15     # crops smaller than this get skipped

# Confidence cutoff (lower = less confident)
# -0.5 strict, -1.5 loose
MIN_CONFIDENCE = -1.0