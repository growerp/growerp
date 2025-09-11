#!/bin/bash

# Gemini CLI wrapper script to handle memory issues
# This script sets appropriate Node.js memory limits and other optimizations

# Set Node.js memory limit (8GB)
export NODE_OPTIONS="--max-old-space-size=8192"

# Optional: Enable garbage collection optimizations
export NODE_OPTIONS="$NODE_OPTIONS --enable-source-maps --expose-gc"

# Optional: Reduce memory pressure warnings
export NODE_OPTIONS="$NODE_OPTIONS --no-warnings"

# Run the actual gemini CLI with all passed arguments
exec /usr/local/bin/gemini "$@"
