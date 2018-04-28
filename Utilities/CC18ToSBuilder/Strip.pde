public class Strip {
  PVector a;
  PVector b;
  int idx;    // Original position based on sorting by Y,X,Z
  int id;     // Position updated by user
  float leds;
  boolean isHighlighted;
  boolean isDuplicate;
  boolean isInverted;
  color col;

  public Strip(PVector a, PVector b, int idx, int leds, int total) {
    this.a = a;
    this.b = b;
    this.id = this.idx = idx;
    this.leds = leds;
    this.isHighlighted = false;
    this.isDuplicate = false;
    this.isInverted = false;
    
    pushStyle();
    colorMode(HSB);
    this.col = color(int((idx+1.0)/(total+1)*256), 255, 127);
    popStyle();
  }

  public void draw() {
    PVector v;

    pushStyle();
    pushMatrix();
    translate(a.x, a.y, a.z);
    fill(255);
    if (isHighlighted)
      box(10);
    else
      box(3);
    popMatrix();
    popStyle();

    pushStyle();
    pushMatrix();
    translate(b.x, b.y, b.z);
    fill(0);
    if (isHighlighted)
      box(10);
    else
      box(3);
    popMatrix();
    popStyle();

    pushMatrix();
    pushStyle();

    
    popStyle();
    popMatrix();

    pushStyle();
    colorMode(HSB);

    for (int i=0; i<leds; i++) {
      if (isHighlighted)
        fill(0, 192, 255);
      else
        fill(col);

      v = PVector.lerp(a, b, i/(leds-1));
      pushMatrix();  
      translate(v.x, v.y, v.z);
      box(2);
      popMatrix();
    }

    popStyle();
    

  }

  public int compareTo(Strip that) {
    int result = new Float(int(this.a.z/10)).compareTo(float(int(that.a.z/10)));

    if (result != 0)
      return result;

    result = new Float(this.a.y).compareTo(that.a.y);

    if (result != 0)
      return result;

    result = new Float(this.a.x).compareTo(that.b.x);

    return result;
  }

  public void invert() {
    this.isInverted = !this.isInverted;
    PVector tmp = this.a;
    this.a = this.b;
    this.b = tmp;
  }
} 
