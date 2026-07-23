from PIL import Image, ImageDraw, ImageChops

def main():
    img_path = r"c:\wetio\assets\images\logo_wetio-1760033405023.png"
    out_path = r"c:\wetio\assets\images\logo_circle.png"
    
    try:
        img = Image.open(img_path).convert("RGBA")
        
        # Determine the background color from the top-left pixel
        bg_color = img.getpixel((0, 0))
        # If it's fully transparent, let's treat white as bg for the diff
        if bg_color[3] == 0:
            bg_color = (255, 255, 255, 0)
            
        # Create a background image to find difference
        bg = Image.new('RGBA', img.size, bg_color)
        diff = ImageChops.difference(img, bg)
        bbox = diff.getbbox()
        
        if bbox:
            img_cropped = img.crop(bbox)
            w_crop, h_crop = img_cropped.size
            max_dim = max(w_crop, h_crop)
            
            # The user wants it a bit larger, meaning less padding
            # Let's add only 15% padding relative to the max dimension
            diameter = int(max_dim * 1.15)
            
            # Create a square base with the original background color
            # If the original had a transparent bg, let's just use white for the circle
            circle_bg = bg_color if bg_color[3] > 0 else (255, 255, 255, 255)
            base = Image.new('RGBA', (diameter, diameter), circle_bg)
            
            paste_x = (diameter - w_crop) // 2
            paste_y = (diameter - h_crop) // 2
            
            # Paste using alpha channel as mask if present
            base.paste(img_cropped, (paste_x, paste_y), img_cropped)
            
            # Apply circular mask
            mask = Image.new('L', (diameter, diameter), 0)
            draw = ImageDraw.Draw(mask)
            draw.ellipse((0, 0, diameter, diameter), fill=255)
            
            base.putalpha(mask)
            base.save(out_path, "PNG")
            print("Successfully created logo_circle.png")
        else:
            print("Bounding box not found, image might be blank.")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == '__main__':
    main()
