#!/bin/bash
# fix_linting.sh - Safe linting fixes for macOS

echo "🔧 Applying safe linting fixes..."

# ==================== FIX NEWLINES & WHITESPACE ====================

# Fix W292 (no newline) and W391 (blank line at end) - using Perl for macOS compatibility
echo "Fixing file endings..."
perl -i -pe 'chomp if eof' app/__init__.py        # Remove extra blank lines, keep newline
perl -i -pe 'chomp if eof' src/__init__.py
perl -i -pe 'chomp if eof' src/train.py
perl -i -pe 'chomp if eof' src/tune.py
perl -i -pe 'chomp if eof' tests/__init__.py
perl -i -pe 'chomp if eof' tests/test_predictions.py

# Ensure proper single newline at end of each file
for file in app/__init__.py src/__init__.py src/train.py src/tune.py tests/__init__.py tests/test_predictions.py; do
    if [ -f "$file" ]; then
        # Read file, remove trailing whitespace, ensure exactly one newline at end
        perl -i -pe 's/\s+$//;' "$file"
        perl -i -pe 'eof && do{chomp; print "$_\n"; exit}' "$file"
    fi
done

# ==================== FIX SPECIFIC FILES ====================

# Fix app/main.py E302 - add blank line before function (line 46)
echo "Fixing app/main.py formatting..."
perl -i -pe 'if ($. == 46) { print "\n" }' app/main.py

# Fix src/train.py specific issues
echo "Fixing src/train.py..."
# Remove whitespace-only lines (W293)
perl -i -ne 'print if !/^\s*$/' src/train.py
# Fix comment spacing (E261)
perl -i -pe 's/print\(f"CV accuracy: \{[^}]+\} ± \{[^}]+\}"\) #/print(f"CV accuracy: {mean_acc:.4f} ± {std_acc:.4f}")  #/' src/train.py
perl -i -pe 's/print\(f"Test accuracy: \{[^}]+\}"\) #/print(f"Test accuracy: {acc:.4f}")  #/' src/train.py

# Fix src/tune.py specific issues
echo "Fixing src/tune.py..."
# Remove unused import (F401) - ONLY remove the specific RANDOM_STATE import line
perl -i -ne 'print unless /from src.config import RANDOM_STATE/' src/tune.py
# Remove trailing whitespace (W291)
perl -i -pe 's/\s+$//' src/tune.py
# Remove whitespace-only lines (W293)
perl -i -ne 'print if !/^\s*$/' src/tune.py

# Fix tests/test_predictions.py
echo "Fixing tests/test_predictions.py..."
# Remove trailing whitespace
perl -i -pe 's/\s+$//' tests/test_predictions.py
# Remove whitespace-only lines
perl -i -ne 'print if !/^\s*$/' tests/test_predictions.py

# ==================== FINAL FORMATTING ====================

echo "Applying final formatting with black..."
python -m black app/ src/ tests/

echo "✅ All fixes applied!"
echo "📋 Run 'make lint' to verify the fixes"