import sys
from pathlib import Path

# scripts/price_alerts/ has no __init__.py (it's a script directory, not a
# package) — insert it explicitly so `import alerts`, `import main`, etc.
# resolve regardless of the working directory pytest is invoked from.
sys.path.insert(0, str(Path(__file__).parent.parent))
