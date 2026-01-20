#!/usr/bin/env python3
"""
Generate Windows application icons from SVG
Creates icons with black background and white logo in various sizes
"""

from PIL import Image, ImageDraw
import cairosvg
import io
import os

# Icon sizes needed for Windows applications
ICON_SIZES = [16, 32, 48, 64, 128, 256, 512]

# Paths
SVG_PATH = "/Volumes/Disk/TSNUG自研系统备份/VPN-Code/app/pixi_vpn/win-logo.svg"
OUTPUT_DIR = "/Volumes/Disk/TSNUG自研系统备份/VPN-Code/app/pixi_vpn/windows_icons"

def read_svg_and_modify(svg_path):
    """Read SVG and modify it to have white fill instead of black"""
    with open(svg_path, 'r') as f:
        svg_content = f.read()
    
    # Replace black fill with white
    svg_content = svg_content.replace('fill="#000000"', 'fill="#FFFFFF"')
    
    return svg_content

def generate_icon(svg_content, size, output_path):
    """Generate a single icon with black background and white logo"""
    # Convert SVG to PNG with transparency
    png_data = cairosvg.svg2png(
        bytestring=svg_content.encode('utf-8'),
        output_width=size,
        output_height=size
    )
    
    # Open the PNG
    logo = Image.open(io.BytesIO(png_data)).convert('RGBA')
    
    # Create a new image with black background
    icon = Image.new('RGBA', (size, size), (0, 0, 0, 255))
    
    # Paste the logo on top
    icon.paste(logo, (0, 0), logo)
    
    # Convert to RGB (remove alpha channel)
    icon_rgb = Image.new('RGB', (size, size), (0, 0, 0))
    icon_rgb.paste(icon, (0, 0))
    
    # Save
    icon_rgb.save(output_path, 'PNG')
    print(f"Generated: {output_path}")

def generate_ico_file(png_files, output_path):
    """Generate a single .ico file containing all sizes"""
    images = []
    for png_file in png_files:
        img = Image.open(png_file)
        images.append(img)
    
    # Save as ICO
    images[0].save(
        output_path,
        format='ICO',
        sizes=[(img.width, img.height) for img in images]
    )
    print(f"Generated ICO: {output_path}")

def main():
    # Create output directory
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    # Read and modify SVG
    print("Reading SVG file...")
    svg_content = read_svg_and_modify(SVG_PATH)
    
    # Generate icons
    png_files = []
    for size in ICON_SIZES:
        output_path = os.path.join(OUTPUT_DIR, f"icon_{size}x{size}.png")
        generate_icon(svg_content, size, output_path)
        png_files.append(output_path)
    
    # Generate .ico file
    ico_path = os.path.join(OUTPUT_DIR, "app_icon.ico")
    generate_ico_file(png_files, ico_path)
    
    print(f"\n✅ All icons generated successfully in: {OUTPUT_DIR}")
    print(f"\nGenerated files:")
    print(f"  - {len(ICON_SIZES)} PNG files (16x16 to 512x512)")
    print(f"  - 1 ICO file (app_icon.ico) containing all sizes")

if __name__ == "__main__":
    main()
