# ---------------------------------------------------------------------------
# MODEL
# ---------------------------------------------------------------------------
MODEL_ID = "microsoft/trocr-base-printed"
# Other options:
#   "microsoft/trocr-large-printed"     → more accurate, but noticeably slower
#   "microsoft/trocr-base-handwritten"  → use this for handwritten text
#   "./my_finetuned_trocr"              → point to your own fine-tuned checkpoint

# ---------------------------------------------------------------------------
# PREPROCESSING
# ---------------------------------------------------------------------------

# Images narrower than this get upscaled before OCR — small images read poorly
UPSCALE_MIN_WIDTH = 1200

# Gamma correction kicks in when the image is too dark or too bright.
# These are average-brightness thresholds (0–255).
GAMMA_VERY_DARK = 85    # below this → brighten hard   (gamma 0.5)
GAMMA_DARK      = 127   # below this → brighten gently (gamma 0.75)
GAMMA_BRIGHT    = 180   # above this → darken slightly (gamma 1.5)

# If the image is still dark after gamma correction, we invert it.
# This handles light text on dark backgrounds.
INVERT_THRESHOLD = 100

# Denoising strength — turn this up if you're getting speckly images,
# but it will slow things down a bit.
DENOISE_H = 10

# ---------------------------------------------------------------------------
# REGION DETECTION
# ---------------------------------------------------------------------------

# How wide the horizontal dilation kernel is.
# Wider → more characters get merged into one region per line.
# Narrower → words stay more separate.
H_KERNEL_WIDTH = 15

# Contours taller than this fraction of the image height get thrown out.
# Keeps us from treating a full-image background blob as a text region.
MAX_LINE_HEIGHT_RATIO = 0.15

# Minimum size for a region to be kept — anything smaller is probably noise.
MIN_REGION_W = 20
MIN_REGION_H = 8

# ---------------------------------------------------------------------------
# LINE MERGING
# ---------------------------------------------------------------------------

# How much two regions need to overlap vertically to be considered the same line.
# Lower (e.g. 0.3) → merge more aggressively.
# Higher (e.g. 0.7) → keep lines more separate.
VERTICAL_OVERLAP_THRESH = 0.5

# ---------------------------------------------------------------------------
# RECOGNITION (TrOCR)
# ---------------------------------------------------------------------------

# Wider beam search = more accurate, but slower. 4 is a good middle ground.
NUM_BEAMS = 4

# Max tokens to generate per crop. 64 handles most single lines comfortably.
MAX_NEW_TOKENS = 64

# Crops smaller than this in either dimension get skipped entirely.
# Too-small crops tend to produce hallucinated text.
MIN_CROP_PX = 20

# Confidence cutoff — results below this are thrown away.
# This is a mean log-probability, so lower = less confident.
# Tighten to -0.5 to reject more (fewer hallucinations).
# Loosen to -1.5 to accept more (catches faint or short text).
MIN_CONFIDENCE = -1.0