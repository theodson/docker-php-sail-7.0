#!/bin/bash
# Test script to verify ImageMagick and PHP Imagick extension functionality
# This script should be run inside the Docker container or used to test an image
#
# Usage: 
#   ./tests/test-imagick.sh                    # Run tests locally (if in container)
#   ./tests/test-imagick.sh <image_name>       # Run tests against a Docker image

set -euo pipefail

IMAGE="${1:-}"
FAILED=0

run_test() {
    local name="$1"
    local cmd="$2"
    echo -n "Testing: $name... "
    if eval "$cmd" > /dev/null 2>&1; then
        echo "✓ PASS"
        return 0
    else
        echo "✗ FAIL"
        return 1
    fi
}

run_test_output() {
    local name="$1"
    local cmd="$2"
    echo "Testing: $name..."
    eval "$cmd" 2>&1 | head -20 || true
    echo ""
}

if [ -n "$IMAGE" ]; then
    # Run tests inside the specified Docker image
    echo "=========================================="
    echo "Testing ImageMagick in Docker image: $IMAGE"
    echo "=========================================="
    echo ""
    
    echo "=== System Architecture ==="
    docker run --rm "$IMAGE" uname -m
    echo ""
    
    echo "=== ImageMagick CLI Version ==="
    docker run --rm "$IMAGE" convert -version || echo "convert not found"
    echo ""
    
    echo "=== ImageMagick CLI Delegates ==="
    docker run --rm "$IMAGE" sh -c "convert -list delegate 2>/dev/null | head -30" || echo "No delegates"
    echo ""
    
    echo "=== ImageMagick CLI PNG Support ==="
    docker run --rm "$IMAGE" sh -c "convert -list format | grep -i png" || echo "No PNG format support"
    echo ""
    
    echo "=== PHP Imagick Extension ==="
    docker run --rm "$IMAGE" php -m | grep -i imagick || echo "Imagick extension not loaded"
    echo ""
    
    echo "=== PHP Imagick Version ==="
    docker run --rm "$IMAGE" php -r "echo 'Imagick version: ' . phpversion('imagick') . PHP_EOL;" 2>&1 || echo "Failed to get version"
    echo ""
    
    echo "=== PHP Imagick Supported Formats Count ==="
    docker run --rm "$IMAGE" php -r "\$i = new Imagick(); \$formats = \$i->queryFormats(); echo 'Supported formats: ' . count(\$formats) . PHP_EOL;" 2>&1 || echo "Failed to query formats"
    echo ""
    
    echo "=== PHP Imagick PNG Format Check ==="
    docker run --rm "$IMAGE" php -r "\$i = new Imagick(); \$formats = \$i->queryFormats('PNG'); echo 'PNG formats: ' . implode(', ', \$formats) . PHP_EOL; echo 'PNG supported: ' . (in_array('PNG', \$formats) ? 'YES' : 'NO') . PHP_EOL;" 2>&1 || echo "Failed"
    echo ""
    
    echo "=== imagick.so file info ==="
    docker run --rm "$IMAGE" sh -c "find /usr -name 'imagick.so' -exec file {} \;" 2>/dev/null || echo "imagick.so not found"
    echo ""
    
    echo "=== ImageMagick configure.xml ==="
    docker run --rm "$IMAGE" sh -c "cat /usr/lib/*/ImageMagick-*/config-*/configure.xml 2>/dev/null | head -20" || echo "configure.xml not found"
    echo ""
    
    echo "=== Linked libraries for imagick.so ==="
    docker run --rm "$IMAGE" sh -c "find /usr -name 'imagick.so' -exec ldd {} \; 2>/dev/null | head -30" || echo "Could not check"
    echo ""
    
    echo "=== PNG Read Test ==="
    docker run --rm "$IMAGE" php -r "
try {
    \$img = new Imagick();
    \$img->newImage(100, 100, new ImagickPixel('red'));
    \$img->setImageFormat('png');
    \$blob = \$img->getImageBlob();
    echo 'PNG write: OK (' . strlen(\$blob) . ' bytes)' . PHP_EOL;
    
    \$img2 = new Imagick();
    \$img2->readImageBlob(\$blob);
    echo 'PNG read: OK' . PHP_EOL;
} catch (Exception \$e) {
    echo 'ERROR: ' . \$e->getMessage() . PHP_EOL;
    exit(1);
}
" 2>&1
    echo ""
    
    echo "=========================================="
    echo "Test Complete"
    echo "=========================================="
else
    # Run tests directly (assuming we're inside the container)
    echo "=========================================="
    echo "Testing ImageMagick (running locally)"
    echo "=========================================="
    echo ""
    
    echo "=== System Architecture ==="
    uname -m
    echo ""
    
    echo "=== ImageMagick CLI Version ==="
    convert -version || echo "convert not found"
    echo ""
    
    echo "=== PHP Imagick Supported Formats Count ==="
    php -r "\$i = new Imagick(); \$formats = \$i->queryFormats(); echo 'Supported formats: ' . count(\$formats) . PHP_EOL;" 2>&1 || echo "Failed"
    echo ""
    
    echo "=== PHP Imagick PNG Check ==="
    php -r "\$i = new Imagick(); echo in_array('PNG', \$i->queryFormats('PNG')) ? 'PNG: OK' : 'PNG: MISSING'; echo PHP_EOL;" 2>&1 || echo "Failed"
fi
