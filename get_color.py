#!/usr/bin/env python3
import sys
from collections import Counter
try:
    from PIL import Image
except ImportError:
    print("Error: Pillow is required. Run: pip3 install Pillow")
    sys.exit(1)

def get_pastel_color(image_path):
    try:
        img = Image.open(image_path).convert("RGBA")
    except Exception as e:
        print(f"Error opening image: {e}")
        sys.exit(1)
        
    colors = []
    DARK_THRESHOLD = 40 
    
    try:
        pixel_data = img.get_flattened_data()
    except AttributeError:
        pixel_data = img.getdata()
    for r, g, b, a in pixel_data:
        # Ignore transparent and dark pixels
        if a < 128:
            continue
        if r < DARK_THRESHOLD and g < DARK_THRESHOLD and b < DARK_THRESHOLD:
            continue
            
        colors.append((r, g, b))
        
    if not colors:
        return "#FFFFFF" 
        
    # Extract the most common color
    most_common_color = Counter(colors).most_common(1)[0][0]
    r, g, b = most_common_color
    
    # --- APPLY PASTEL TONE ---
    # PASTEL_FACTOR: 0.0 = original color, 1.0 = pure white.
    # 0.4 adds a slight touch of white to soften the color.
    PASTEL_FACTOR = 0.4
    
    r = int(r + (255 - r) * PASTEL_FACTOR)
    g = int(g + (255 - g) * PASTEL_FACTOR)
    b = int(b + (255 - b) * PASTEL_FACTOR)
    
    # Format as uppercase hex (e.g. #FDFD96)
    return f"#{r:02X}{g:02X}{b:02X}"

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 get_color.py <path_to_image>")
        sys.exit(1)
        
    image_path = sys.argv[1]

    print(get_pastel_color(image_path))
