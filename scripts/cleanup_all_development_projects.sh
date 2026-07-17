#!/bin/bash

# Target directory containing all projects
TARGET_DIR="/Users/mdsahil/development"

echo "=== Starting Dev Directory Cleanup ==="
echo "Target: $TARGET_DIR"
echo ""

# Record initial disk space
initial_space=$(df -m "$TARGET_DIR" | tail -1 | awk '{print $4}')

# Iterate through all subdirectories
for project in "$TARGET_DIR"/*; do
  if [ -d "$project" ]; then
    project_name=$(basename "$project")
    echo "Processing project: $project_name..."

    # Check for Flutter project
    if [ -f "$project/pubspec.yaml" ]; then
      echo "  -> Found Flutter project. Cleaning build caches..."
      
      # Fast deletion of build outputs
      if [ -d "$project/build" ]; then
        echo "     Removing build/"
        rm -rf "$project/build"
      fi
      if [ -d "$project/.dart_tool" ]; then
        echo "     Removing .dart_tool/"
        rm -rf "$project/.dart_tool"
      fi
      if [ -d "$project/ios/.symlinks" ]; then
        echo "     Removing ios/.symlinks/"
        rm -rf "$project/ios/.symlinks"
      fi
      if [ -d "$project/ios/Pods" ]; then
        echo "     Removing ios/Pods/"
        rm -rf "$project/ios/Pods"
      fi
      if [ -d "$project/android/.gradle" ]; then
        echo "     Removing android/.gradle/"
        rm -rf "$project/android/.gradle"
      fi
    fi

    # Check for Android / Gradle project (either directly or inside android/ folder)
    if [ -f "$project/build.gradle" ] || [ -f "$project/settings.gradle" ] || [ -d "$project/android" ]; then
      echo "  -> Found Android/Gradle config. Cleaning gradle builds..."
      
      if [ -d "$project/.gradle" ]; then
        echo "     Removing .gradle/"
        rm -rf "$project/.gradle"
      fi
      if [ -d "$project/build" ]; then
        echo "     Removing build/"
        rm -rf "$project/build"
      fi
      if [ -d "$project/app/build" ]; then
        echo "     Removing app/build/"
        rm -rf "$project/app/build"
      fi
      if [ -d "$project/android/.gradle" ]; then
        echo "     Removing android/.gradle/"
        rm -rf "$project/android/.gradle"
      fi
      if [ -d "$project/android/app/build" ]; then
        echo "     Removing android/app/build/"
        rm -rf "$project/android/app/build"
      fi
      if [ -d "$project/android/build" ]; then
        echo "     Removing android/build/"
        rm -rf "$project/android/build"
      fi
    fi
  fi
done

# Record final disk space
final_space=$(df -m "$TARGET_DIR" | tail -1 | awk '{print $4}')
freed_space=$((final_space - initial_space))

echo ""
echo "=== Cleanup Completed ==="
if [ $freed_space -ge 1024 ]; then
  freed_gb=$(echo "scale=2; $freed_space/1024" | bc)
  echo "Freed approximately: ${freed_gb} GB of disk space!"
else
  echo "Freed approximately: ${freed_space} MB of disk space!"
fi
echo "New available space: $(df -h "$TARGET_DIR" | tail -1 | awk '{print $4}')"
