
from PIL import Image, ImageDraw

def create_hanger_icon():
    # Size 96x96 (suitable for xxhdpi or higher)
    size = 96
    image = Image.new("RGBA", (size, size), (255, 255, 255, 0))
    draw = ImageDraw.Draw(image)
    
    # Draw a simplified hanger silhouette in white
    # Top hook
    draw.arc([38, 10, 58, 30], 180, 0, fill=(255, 255, 255, 255), width=4)
    draw.line([58, 20, 58, 25], fill=(255, 255, 255, 255), width=4)
    
    # Body of the hanger
    # Triangle-ish shape
    # Points: top, bottom-left, bottom-right
    top = (48, 30)
    bottom_left = (10, 70)
    bottom_right = (86, 70)
    
    draw.line([top[0], top[1], bottom_left[0], bottom_left[1]], fill=(255, 255, 255, 255), width=5)
    draw.line([top[0], top[1], bottom_right[0], bottom_right[1]], fill=(255, 255, 255, 255), width=5)
    draw.line([bottom_left[0], bottom_left[1], bottom_right[0], bottom_right[1]], fill=(255, 255, 255, 255), width=5)
    
    # Save the icon
    image.save("ic_notification_fixed.png")
    print("Fixed icon generated successfully.")

if __name__ == "__main__":
    create_hanger_icon()
