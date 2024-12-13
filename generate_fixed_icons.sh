#!/bin/bash

# 确保目标目录存在
mkdir -p "ToDoList/Assets.xcassets/AppIcon.appiconset"

# 定义所需的图标尺寸
declare -a sizes=(
    "40x40@2x:80"
    "60x60@3x:180"
    "58x58@2x:116"
    "87x87@3x:261"
    "80x80@2x:160"
    "120x120@3x:360"
    "120x120@2x:240"
    "180x180@3x:540"
    "1024x1024@1x:1024"
)

# 使用 sips 调整图片大小（macOS 内置工具）
for size in "${sizes[@]}"; do
    IFS=: read name pixels <<< "${size}"
    echo "生成 $name.png..."
    cp "icon_template.png" "ToDoList/Assets.xcassets/AppIcon.appiconset/$name.png"
    sips -Z $pixels "ToDoList/Assets.xcassets/AppIcon.appiconset/$name.png" >/dev/null 2>&1
done

echo "图标生成完成！"
