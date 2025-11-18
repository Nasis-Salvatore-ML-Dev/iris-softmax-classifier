import os
from pathlib import Path
import yaml

ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = ROOT / "data"
ARTIFACTS_DIR = ROOT / "artifacts"
ARTIFACTS_DIR.mkdir(parents=True, exist_ok=True)

IRIS_CSV = DATA_DIR / "iris.csv"

MODEL_PATH = os.getenv(
    "MODEL_PATH",
    str(ARTIFACTS_DIR / "model.pkl")   # Default local model
)
# NOTE: cast to str because joblib.load expects a string path
# ============================================

# YAML config loading (unchanged)
CONFIG_YAML = ROOT / "src" / "config.yaml"

if CONFIG_YAML.exists():
    with open(CONFIG_YAML, "r") as f:
        cfg = yaml.safe_load(f)
    RANDOM_STATE = cfg["data"]["random_state"]
    TEST_SIZE = cfg["data"]["test_size"]
    TARGET_NAMES = cfg["model"].get(
        "target_names", ["setosa", "versicolor", "virginica"]
    )
else:
    RANDOM_STATE = 42
    TEST_SIZE = 0.2
    TARGET_NAMES = ["setosa", "versicolor", "virginica"]
