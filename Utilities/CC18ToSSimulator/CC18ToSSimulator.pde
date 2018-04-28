import codeanticode.syphon.*;

import hypermedia.net.*;
import moonpaper.*;
import moonpaper.opcodes.*;

import peasy.org.apache.commons.math.*;
import peasy.*;
import peasy.org.apache.commons.math.geometry.*;

public static final String CABIN_MODEL = "../../Data/ArtCabin.obj";
public static final String CABIN_JSON = "../../Data/ArtCabin.json";

//public static final String START_HOST = "10.0.1.114";
public static final String START_HOST = "localhost";
public static final int START_PORT = 6454;

float lightSize = 2;  // Size of LEDs

Strips strips;
PixelMap pixelMap;

PeasyCam g_pCamera;
PShape cabin_model;
ArtNetMulticast multicast;

PImage syphonBuffer = null;
SyphonClient syphonClient;

void drawPlane() {
  float corner = 10000;
  pushStyle();
  fill(64);  
  beginShape();
  vertex(corner, 0, corner);
  vertex(corner, 0, -corner);
  vertex(-corner, 0, -corner);
  vertex(-corner, 0, corner);
  endShape(CLOSE);
  popStyle();
}

void setup() {
  size(1280, 720, P3D);
  frameRate(60);
  
  syphonClient = new SyphonClient(this);

  g_pCamera = new PeasyCam(this, -100, -100, 0, 150);
  g_pCamera.setMinimumDistance(100);
  g_pCamera.setMaximumDistance(5000);
  g_pCamera.setWheelScale(1);
  //g_pCamera.setYawRotationMode();
  g_pCamera.rotateY(-PI/16);

  // Fix the front clipping plane
  float fov = PI/3.0;
  float cameraZ = (height/2.0) / tan(fov/2.0);
  perspective(fov, float(width)/float(height), cameraZ/1000.0, cameraZ*50.0);

  // Setup Virtual Installation  
  strips = new Strips();

  // Load cabin
  cabin_model = loadShape(CABIN_MODEL);
  invertShape(cabin_model);
  Strips tofsy_strips = new Strips();
  strips.loadFromJSON(CABIN_JSON);
  strips.addAll(tofsy_strips);

  // Generate PixelMap
  pixelMap = new PixelMap();
  pixelMap.addStrips(strips);
  pixelMap.finalize();

  // Receiver
  if (START_HOST == "localhost" || START_HOST == "127.0.0.1") 
    multicast = new ArtNetMulticast(pixelMap, strips, START_PORT, START_HOST);
  else
    multicast = new ArtNetMulticast(pixelMap, strips, START_HOST, START_PORT);
  multicast.setListen(true);
  multicast.setRowsPerPacket(4);
  multicast.setup();
  
}

void pixelMapToStrips(PixelMap pixelMap, Strips strips) {
  int rows = strips.size();
  PGraphics pg = pixelMap.pg;
  pg.loadPixels();

  for (int row = 0; row < rows; row++) {
    Strip strip = strips.get(row);
    ArrayList<LED> lights = strip.leds;
    int cols = strip.nLights;
    int rowOffset = row * pixelMap.columns;

    for (int col = 0; col < cols; col++) {
      LED led = lights.get(col);
      led.c = pg.pixels[rowOffset + col];
    }
  }
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

void draw() {
  background(32);
  
  if (syphonClient.newFrame()) {
    syphonBuffer = syphonClient.getImage(syphonBuffer, true);
  }
  
  pushMatrix();

  // Draw landscape and structure  
 // drawPlane();

  // Draw Cabin
  pushStyle();
  noStroke();
  pushMatrix();
  shape(cabin_model);


  
  popMatrix();
  
  multicast.draw();
  pixelMapToStrips(pixelMap, strips);
  
  for (Strip strip : strips) {
    for (LED led : strip.leds) {
      pushMatrix();
      PVector p = led.position;
      fill(led.c);
      translate(p.x, p.y, p.z);
      box(lightSize);
      popMatrix();
    }
  }
  
  popStyle();
  popMatrix();
  
  if (syphonBuffer != null) {
    pushStyle();
    pushMatrix();
    tint(255,255,255,128);
    translate(-180,-180,-15);
    textureMode(IMAGE);
    beginShape();
    texture(syphonBuffer);
    vertex(0, 0, 0, 0, 0);
    vertex(85, 0, 0, syphonBuffer.width, 0);
    vertex(85, 175, 0, syphonBuffer.width, syphonBuffer.height);
    vertex(0, 175, 0, 0, syphonBuffer.height);
    endShape();  
    popMatrix();
    popStyle();
 }
}
