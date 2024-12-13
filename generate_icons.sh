#!/bin/bash

# Create icons directory if it doesn't exist
mkdir -p "ToDoList/Assets.xcassets/AppIcon.appiconset"

# Create a temporary PNG file with solid blue background
convert -size 1024x1024 xc:'#007AFF' temp_icon.png

# Add text using sips (not supported directly, we'll need to use Xcode's asset catalog)
mv temp_icon.png "ToDoList/Assets.xcassets/AppIcon.appiconset/1024x1024@1x.png"

# Define icon sizes and generate them from the base icon
sizes=(
    "40x40@2x:80"
    "60x60@3x:180"
    "58x58@2x:116"
    "87x87@3x:261"
    "80x80@2x:160"
    "120x120@3x:360"
    "120x120@2x:240"
    "180x180@3x:540"
)

for size in "${sizes[@]}"; do
    IFS=: read name pixels <<< "${size}"
    echo "Generating $name.png..."
    cp "ToDoList/Assets.xcassets/AppIcon.appiconset/1024x1024@1x.png" "ToDoList/Assets.xcassets/AppIcon.appiconset/$name.png"
    sips -Z $pixels "ToDoList/Assets.xcassets/AppIcon.appiconset/$name.png" >/dev/null 2>&1
done

echo "Icon generation complete!"
