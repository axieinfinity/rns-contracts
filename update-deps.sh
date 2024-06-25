#!/bin/bash

# Set the path to the dependencies folder
DEPENDENCIES_FOLDER="./dependencies"

# Check if the dependencies folder exists
if [ ! -d "$DEPENDENCIES_FOLDER" ]; then
  echo "Dependencies folder does not exist: $DEPENDENCIES_FOLDER"
  exit 1
fi

# Change directory to the dependencies folder
cd "$DEPENDENCIES_FOLDER" || exit 1

# Iterate through each subdirectory in the dependencies folder
for dir in */; do
  if [ -d "$dir" ]; then
    echo "Updating dependencies in: $dir"
    cd "$dir" || exit 1

    # Check if soldeer.lock exists
    if [ ! -f "soldeer.lock" ]; then
      echo "soldeer.lock does not exist in: $dir"
      echo "Skipping update for: $dir"
      cd ..
      continue
    fi

    # Run soldeer update
    forge soldeer update

    # Return to the dependencies folder
    cd ..
  fi
done

# Return to the original directory
cd ..

echo "All dependencies updated."
