class Syphon extends DisplayableLEDs {
  float top = 100000;
  float bot = -100000;
  float left = 100000;
  float right = -100000;
  int width;
  int height;
  PImage img;

  Syphon(PixelMap pixelMap, Structure structure) {
    super(pixelMap, structure);
    findDimensions();
  }
  
  void findDimensions() {
    // Find top an bottom of the structure
    for (LED led : leds) {
      top = min(top, led.position.y);
      bot = max(bot, led.position.y);
      left = min(left, led.position.x);
      right = max(right, led.position.x);  
    }
    
    this.width = int(abs(right - left) * 10) + 1;
    this.height = int(abs(bot - top) * 10) + 1;
    
    img = createImage(this.width, this.height, ARGB);
    println("top="+top+" left="+left+ " bot="+bot+" right="+right);
    println("width="+this.width+" height="+this.height+" aspect="+(1.0*this.width/this.height));
  }
  
  void update() {
    if (syphonBuffer != null) {
      img.copy(syphonBuffer, 0, 0, syphonBuffer.width, syphonBuffer.height, 0, 0, this.width, this.height);
      img.loadPixels();
      
      color c;
      float r,g,b;
      for (LED led : leds) {
        int x = int((led.position.x - left) * 10);
        int y = int((led.position.y - top) * 10);
        c = img.pixels[y * this.width + x];
        r = red(c) / 4;
        g = green(c) / 4;
        b = blue(c) / 4;
        
        led.c = color(r,g,b);  
      }
    }
    
    super.update();
  }
}
