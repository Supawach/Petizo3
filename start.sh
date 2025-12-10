#!/bin/sh
# Startup script for Railway deployment (OCR DISABLED - insufficient disk space)
# OCR features will be unavailable but the app will run normally

echo "Starting Petizo server (OCR disabled)..."

# Set Python packages path in Volume
export PYTHON_PACKAGES="/app/petizo/data/python_packages"

# Add Volume packages to PYTHONPATH
export PYTHONPATH="$PYTHON_PACKAGES:$PYTHONPATH"

# Debug: Show Python path to verify packages are accessible
echo "PYTHON_PACKAGES: $PYTHON_PACKAGES"
python3 -c "import sys; print('Python sys.path:'); [print('   -', p) for p in sys.path[:5]]" 2>/dev/null || echo "Warning: Could not get Python path"

# Set environment variables for EasyOCR and OpenCV
export EASYOCR_MODULE_PATH="/app/petizo/data/easyocr_models"
export OPENCV_IO_MAX_IMAGE_PIXELS=1000000000
export PYTHONUNBUFFERED=1

# Set LD_LIBRARY_PATH for libstdc++.so.6
export LD_LIBRARY_PATH="/root/.nix-profile/lib:${LD_LIBRARY_PATH:-}"

# Force PyTorch to use CPU only (no CUDA)
export CUDA_VISIBLE_DEVICES=""

# Check if Python packages are installed
INSTALL_MARKER="/app/petizo/data/.installed"
INSTALL_VERSION="v26"  # v26: OCR disabled to save disk space

# Clean up old installations
echo "Cleaning old Python packages and pip cache..."
rm -rf "$PYTHON_PACKAGES"
rm -rf /app/petizo/data/tmp
rm -rf /root/.cache/pip
rm -f "$INSTALL_MARKER"
echo "Cleanup complete (packages + pip cache)"

# Create necessary directories in Volume AFTER cleanup
mkdir -p /app/petizo/data/easyocr_models
mkdir -p "$PYTHON_PACKAGES"

# Use Volume temp directory to avoid cross-device link errors
export TMPDIR="/app/petizo/data/tmp"
mkdir -p "$TMPDIR" || echo "Warning: Could not create tmp directory"

# Mark as installed (OCR disabled, no packages to install)
echo "Skipping OCR package installation (OCR features disabled due to disk space constraints)"
echo "   If you need OCR, please upgrade to a larger Railway plan"
echo "$INSTALL_VERSION" > "$INSTALL_MARKER"
echo "Installation marker created (OCR disabled)"

# Initialize database if it doesn't exist
if [ ! -f "./data/petizo.db" ]; then
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Initializing database..."
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  node scripts/setup/init-database.js
  echo "Database initialized successfully"
else
  echo "Database already exists, skipping initialization"
fi

# Start the Node.js server
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Starting Node.js server (without OCR support)..."
echo "Note: OCR features (/api/scan-vaccine) will return errors"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
exec node server.js
