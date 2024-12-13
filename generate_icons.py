import os
from PIL import Image, ImageDraw, ImageFont, ImageEnhance, ImageFilter, ImageChops
import math
from PIL.ImageColor import getrgb
import random

# Create icons directory if it doesn't exist
os.makedirs("ToDoList/Assets.xcassets/AppIcon.appiconset", exist_ok=True)

# Define icon sizes with their exact filenames
sizes = [
    (40, "Icon-40.png"),
    (60, "Icon-60.png"),
    (58, "Icon-58.png"),
    (87, "Icon-87.png"),
    (80, "Icon-80.png"),
    (120, "Icon-120.png"),
    (180, "Icon-180.png"),
    (1024, "Icon-1024.png")
]

def add_noise_texture(image, intensity=10):
    noise = Image.new('RGBA', image.size, (0, 0, 0, 0))
    pixels = noise.load()
    
    for x in range(noise.width):
        for y in range(noise.height):
            if random.random() > 0.5:  # Only add noise to some pixels
                alpha = random.randint(0, intensity)
                pixels[x, y] = (255, 255, 255, alpha)
    
    return Image.alpha_composite(image, noise)

def create_glass_highlight(size, radius, opacity=30):
    highlight = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(highlight)
    
    # Create a diagonal gradient for the glass effect
    for y in range(size):
        alpha = int(opacity * (1 - y/size))
        draw.line([(0, y), (size, y)], fill=(255, 255, 255, alpha))
    
    # Create mask for rounded corners
    mask = Image.new('L', (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle([0, 0, size-1, size-1], radius=radius, fill=255)
    
    # Apply mask
    highlight.putalpha(ImageChops.multiply(highlight.split()[3], mask))
    return highlight

def create_gradient(size, colors):
    gradient = Image.new('RGBA', (size, size), color=(0, 0, 0, 0))
    draw = ImageDraw.Draw(gradient)
    
    num_colors = len(colors)
    segment_height = size / (num_colors - 1)
    
    for i in range(num_colors - 1):
        start_color = colors[i]
        end_color = colors[i + 1]
        start_y = int(i * segment_height)
        end_y = int((i + 1) * segment_height)
        
        for y in range(start_y, end_y):
            progress = (y - start_y) / (end_y - start_y)
            # Add sine wave to create more natural transition
            progress = (math.sin(progress * math.pi - math.pi/2) + 1) / 2
            
            r = int(start_color[0] + (end_color[0] - start_color[0]) * progress)
            g = int(start_color[1] + (end_color[1] - start_color[1]) * progress)
            b = int(start_color[2] + (end_color[2] - start_color[2]) * progress)
            
            draw.line([(0, y), (size, y)], fill=(r, g, b))
    
    return gradient

def add_outer_glow(image, glow_color, blur_radius=3):
    alpha = image.split()[3]
    glow_mask = alpha.filter(ImageFilter.GaussianBlur(blur_radius))
    
    glow_layers = []
    for i in range(4):  # Increased number of glow layers
        glow = Image.new('RGBA', image.size, 
                        (glow_color[0], glow_color[1], glow_color[2], 
                         int(glow_color[3] * (1 - i*0.2))))
        glow.putalpha(glow_mask)
        glow_layers.append(glow)
    
    result = glow_layers[0]
    for layer in glow_layers[1:]:
        result = Image.alpha_composite(result, layer)
    
    return Image.alpha_composite(result, image)

def create_rounded_rectangle_with_effects(size, radius, base_color):
    image = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    mask = Image.new('L', (size, size), 0)
    
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle([0, 0, size-1, size-1], radius=radius, fill=255)
    
    # Create more sophisticated gradient with multiple color stops
    colors = [
        (41, 121, 255),  # Bright blue
        (0, 122, 255),   # Apple blue
        (0, 91, 219),    # Medium blue
        (0, 66, 165)     # Deep blue
    ]
    gradient = create_gradient(size, colors)
    gradient.putalpha(mask)
    
    # Create glass effect
    glass = create_glass_highlight(size, radius, opacity=40)
    
    # Create shadow effects
    shadow = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    
    # Multiple shadow layers for depth
    shadow_layers = [
        (4, int(size/1.5), size-5, size-4),
        (6, int(size/1.3), size-7, size-6),
        (8, int(size/1.2), size-9, size-8)
    ]
    
    for x1, y1, x2, y2 in shadow_layers:
        if y1 < y2:  # Ensure valid coordinates
            shadow_draw.rounded_rectangle([x1, y1, x2, y2], 
                                    radius=radius, 
                                    fill=(0, 0, 0, 30))
    
    # Edge highlight for more depth
    edge_highlight = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    edge_draw = ImageDraw.Draw(edge_highlight)
    edge_draw.rounded_rectangle([1, 1, size-2, size-2], 
                              radius=radius, 
                              fill=(255, 255, 255, 15))
    
    # Combine all layers
    image = Image.alpha_composite(image, gradient)
    image = Image.alpha_composite(image, shadow)
    image = Image.alpha_composite(image, edge_highlight)
    image = Image.alpha_composite(image, glass)
    
    # Add subtle noise texture
    image = add_noise_texture(image, intensity=3)
    
    # Add sophisticated outer glow
    image = add_outer_glow(image, (41, 121, 255, 130))
    
    return image

def create_icon(size):
    if size < 20:
        size = 20
        
    img = Image.new('RGBA', (size, size), color=(0, 0, 0, 0))
    icon = create_rounded_rectangle_with_effects(size, radius=size * 0.23, base_color='#007AFF')
    img = Image.alpha_composite(img, icon)
    draw = ImageDraw.Draw(img)
    
    # Optimize text size and position
    font_size = max(int(size * 0.22), 1)  # Slightly larger text
    
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", size=font_size)
    except:
        font = ImageFont.load_default()
    
    text = "ToDoList"
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    
    # Adjust text position slightly higher
    x = (size - text_width) / 2
    y = (size - text_height) / 2 - (size * 0.01)
    
    # Enhanced text shadow with more layers
    shadow_offsets = [(1.2, 1.2), (1.8, 1.8), (2.4, 2.4), (3.0, 3.0)]
    shadow_alphas = [60, 45, 30, 15]
    
    for offset, alpha in zip(shadow_offsets, shadow_alphas):
        offset_x = max(1, int(size * offset[0] * 0.01))
        offset_y = max(1, int(size * offset[1] * 0.01))
        draw.text((x + offset_x, y + offset_y), 
                 text, 
                 font=font, 
                 fill=(0, 0, 0, alpha))
    
    # Draw main text with enhanced clarity
    draw.text((x, y), text, font=font, fill=(255, 255, 255, 255))
    
    # Apply sophisticated post-processing
    glow = img.filter(ImageFilter.GaussianBlur(1.2))
    img = Image.alpha_composite(glow, img)
    
    # Fine-tune contrast and brightness
    enhancer = ImageEnhance.Contrast(img)
    img = enhancer.enhance(1.2)
    
    enhancer = ImageEnhance.Brightness(img)
    img = enhancer.enhance(1.08)
    
    return img

# Generate icons for all sizes
for size, filename in sizes:
    print(f"Generating {filename}...")
    icon = create_icon(size)
    icon.save(f"ToDoList/Assets.xcassets/AppIcon.appiconset/{filename}", "PNG")

print("Icon generation complete!")
