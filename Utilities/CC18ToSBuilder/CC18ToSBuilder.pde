

import java.util.Collections;
import java.util.Comparator;

static final String INSTRUCTIONS = 
  "This Builder will automatically find surfaces that have been colored pink in SketchUp.\n" +
  "Use LEFT and RIGHT or CLICK to navigate to each strip.\n" +
  "Use UP and DOWN to change the id of the strip.  Conflicts will show in red.\n" +
  "Use L to load the ArtCabin.json file, and S to save it.";

// This is the very specific pink used to denote surfaces which
// will host LEDs.
static final int SURFACE_COLOR = -1069827;

// Model to load
static final String INPUT_FILE = "../../Data/ArtCabin.obj";

// Filename to write to (set to null to not write a file)
static final String OUTPUT_FILE = "../../Data/ArtCabin.json";

// The short edge of the surface is approximately this size.
static final float SURFACE_SHORT_SIZE = 1;
static final float SURFACE_SHORT_TOLERANCE = 0.1;

// Length of the surface and LED strip in inches.
static final float SURFACE_LENGTH = 39.5;
static final float LEDS_LENGTH = 39.5;
static final float SURFACE_LED_LERP = (1.0 - (LEDS_LENGTH / SURFACE_LENGTH)) / 2.0;

// Number of LEDs per m
static final int LEDS_DENSITY = 60;
static final int LEDS_PER_STRIP = 60;

// Number of ports per controller. The controllers we're using only support 4 strips
// but since Moonpaper doesn't support paths we're cheating.
// Chaining 4, 4, 4, 1 (distkit.rowsPerPacket prevents any other split)
static final int CONTROLLER_PORTS = 13; 

static final int FONT_SIZE = 16;

PShape model;
PShape child;

ArrayList<Strip> strips = new ArrayList<Strip>();
int activeStrip = -1;
PFont font;

public void setup() {
  size(1280, 720, P3D);

  model = loadShape(INPUT_FILE);
  invertShape(model);  

  println(INSTRUCTIONS);

  ArrayList<PShape> shapes = findMarkedShapes();
  
  int id = 0;
  for (PShape shape : shapes) {
    PVector[] sides = findShortSides(shape);
    PVector[] stripVectors = calcStripLocation(sides);
    Strip strip = new Strip(stripVectors[0], stripVectors[1], id++, LEDS_PER_STRIP, shapes.size());
    strips.add(strip);
  }
  
  font = createFont("Arial Bold.ttf", FONT_SIZE);
}

public void sortStripsById(ArrayList<Strip> strips) {
  Collections.sort(strips, new Comparator<Strip>() {
    @Override
      public int compare(Strip left, Strip right) {
      return new Integer(left.id).compareTo(right.id);
    }
  }
  );
}

public void save() {
  ArrayList<Strip> copy = new ArrayList<Strip>(strips);
  JSONArray array = new JSONArray();

  sortStripsById(copy);

  for (int i=0; i<copy.size(); i++) {
    Strip strip = copy.get(i);
    array.setJSONObject(i, getJSONObject(strip));
  }

  saveJSONArray(array, OUTPUT_FILE);
  println("Wrote " + OUTPUT_FILE + ".");
}

public void load() {
  JSONArray array = loadJSONArray(OUTPUT_FILE);

  int idx;
  for (int i=0; i<strips.size(); i++) {
    JSONObject o = array.getJSONObject(i);
    idx = o.isNull("index") ? i : o.getInt("index");
    Strip strip = strips.get(idx);
    strip.id = o.getInt("id");

    boolean inverted = o.getBoolean("inverted");
    if (inverted != strip.isInverted)
      strip.invert();
  }

  findDuplicateIds();
  println("Loaded " + OUTPUT_FILE + ".");
}

public JSONObject getJSONObject(Strip strip) {
  JSONObject result = new JSONObject();

  result.setInt("index", strip.idx);
  result.setInt("id", strip.id);
  result.setInt("density", LEDS_DENSITY);
  result.setInt("numberOfLights", LEDS_PER_STRIP);
  result.setBoolean("inverted", strip.isInverted);
  result.setInt("controller", strip.id / CONTROLLER_PORTS);
  result.setInt("port", strip.id % CONTROLLER_PORTS); 

  JSONArray start = new JSONArray();
  start.setFloat(0, strip.a.x);
  start.setFloat(1, strip.a.y);
  start.setFloat(2, strip.a.z);
  result.setJSONArray("startPoint", start);

  JSONArray end = new JSONArray();
  end.setFloat(0, strip.b.x);
  end.setFloat(1, strip.b.y);
  end.setFloat(2, strip.b.z);
  result.setJSONArray("endPoint", end);

  return result;
}

public int offset(int num, int ofs, int size) {
  num += ofs;
  if (num > size) num = 0;
  else if (num < 0) num = size - 1;

  return num;
}

public ArrayList<PShape> findMarkedShapes() {
  ArrayList<PShape> shapes = new ArrayList<PShape>();

  for (int i=0; i<model.getChildCount(); i++) {
    child = model.getChild(i);
    if (child.getFill(0) == SURFACE_COLOR) {
      shapes.add(child);
    }
  }

  println("Found " + shapes.size() + " shapes.");

  return shapes;
}

// Processing's coordinate system is "left-handed", whereas 
// SketchUp is "right-handed".  We should invert all three
// axis, but either Processing or SketchUp has the Z axis
// backwards.
public void invertShape(PShape shape) {
  for (int i=0; i<shape.getChildCount(); i++) {
    PShape child = shape.getChild(i);
    for (int j=0; j<child.getVertexCount(); j++) {
      PVector v = child.getVertex(j);
      v.y = -v.y;
      v.x = -v.x;

      child.setVertex(j, v);
    }
  }
}

public PVector[] findShortSides(PShape shape) {
  PVector[] result = new PVector[4];
  int ridx = 0;

  for (int i=0; i<shape.getVertexCount(); i++) {
    int j = offset(i, 1, shape.getVertexCount()-1);
    PVector a = shape.getVertex(i);
    PVector b = shape.getVertex(j);
    float d = a.dist(b);

    if (d > SURFACE_SHORT_SIZE-SURFACE_SHORT_TOLERANCE &&
      d < SURFACE_SHORT_SIZE+SURFACE_SHORT_TOLERANCE) 
    {
      if (ridx >= result.length) {
        println("Invalid shape, too manny short sides.");
        return null;
      }
      result[ridx] = a;
      result[ridx+1] = b;
      ridx += 2;
    }
  }

  if (ridx < result.length) {
    println("Invalid shape, not enough short sides.");
    return null;
  }

  return result;
}

public PVector[] calcStripLocation(PVector[] sides) {
  PVector[] result = new PVector[2];

  PVector a = PVector.lerp(sides[0], sides[1], 0.5);
  PVector b = PVector.lerp(sides[2], sides[3], 0.5);
  PVector la = PVector.lerp(a, b, SURFACE_LED_LERP);
  PVector lb = PVector.lerp(b, a, SURFACE_LED_LERP);

  if (la.x < lb.x || (la.x == lb.x && la.y < lb.y)) {
    result[0] = la;
    result[1] = lb;
  } else {
    result[0] = lb;
    result[1] = la;
  }

  return result;
}

public void activateStrip(int i) {
  if (activeStrip >= 0) {
    strips.get(activeStrip).isHighlighted = false;
  }

  strips.get(i).isHighlighted = true;
  activeStrip = i;
}

public void activateStripDelta(int i) {
  if (activeStrip + i > strips.size() - 1) {
    activateStrip(0);
  } else if (activeStrip + i < 0) {
    activateStrip(strips.size() - 1);
  } else {
    activateStrip(activeStrip + i);
  }
}

public void invertActiveStrip() {
  if (activeStrip > -1)
    strips.get(activeStrip).invert();
}

public void findDuplicateIds() {
  HashMap<Integer, Strip> dups = new HashMap<Integer, Strip>();

  for (Strip strip : strips) {
    if (dups.containsKey(strip.id)) {
      strip.isDuplicate = true;
      dups.get(strip.id).isDuplicate = true;
    } else {
      strip.isDuplicate = false;
      dups.put(strip.id, strip);
    }
  }
}

public void setStripIdDelta(int delta) {
  if (activeStrip < 0)
    return;

  Strip strip = strips.get(activeStrip);
  if (strip.id + delta < 0) 
    strip.id = strips.size() - 1;
  else if (strip.id + delta > strips.size() - 1)
    strip.id = 0;
  else
    strip.id += delta;

  findDuplicateIds();
}

public void keyPressed() {
  if (keyCode == LEFT)
    activateStripDelta(-1);
  else if (keyCode == RIGHT)
    activateStripDelta(1);
  else if (keyCode == UP)
    setStripIdDelta(1);
  else if (keyCode == DOWN)
    setStripIdDelta(-1);
  else if (key == 'i' || key == 'I')
    invertActiveStrip();
  else if (key == 's' || key == 'S')
    save();
  else if (key == 'l' || key == 'L')
    load();
}

public void mousePressed() {
   loadPixels();
   color col = pixels[mouseY * width + mouseX];
   
   for (Strip s : strips) {
     if (s.col == col)
       activateStrip(s.idx);
   }
}

public void draw() {
  background(50);

  pushStyle();
  pushMatrix();
  
  translate(775,500,575);
  rotateX(PI/10);
  shape(model);
  noStroke();

  for (int i=0; i<strips.size(); i++) {
      strips.get(i).draw();
  }

  popMatrix();
  popStyle();
  
  textFont(font);
  for (int i=0; i<strips.size(); i++) {
    Strip s = strips.get(i);
    
    if (s.isHighlighted) {
      fill(255);
    }
    else if (s.isDuplicate) {
      fill(255,0,0);
    }
    else {
      fill(0,127,127);
    }
    text(s.idx + "=" + s.id, 10, i*FONT_SIZE+20);  
  }
}
