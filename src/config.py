# src/config.py
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = ROOT / "data"
ARTIFACTS_DIR = ROOT / "artifacts"
ARTIFACTS_DIR.mkdir(parents=True, exist_ok=True)

IRIS_CSV = DATA_DIR / "iris.csv"
MODEL_PATH = ARTIFACTS_DIR / "tuned_model.pkl"  # <------ needs be changed with the tuned model if test is passed!!!!

# Try loading from YAML if available
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
    # Fallback defaults
    RANDOM_STATE = 42
    TEST_SIZE = 0.2
    TARGET_NAMES = ["setosa", "versicolor", "virginica"]
