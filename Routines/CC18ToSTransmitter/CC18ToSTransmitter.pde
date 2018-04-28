import codeanticode.syphon.*;

import hypermedia.net.*;
import moonpaper.*;
import moonpaper.opcodes.*;

// If set to "localhost" or "127.0.0.1", it will increment the port.
// Otherwise it will incrment the IP.
//public static final String START_HOST = "10.0.1.114";
public static final String START_HOST = "localhost";
public static final int START_PORT = 6454;

// Turn on frame capture
boolean captureFrames = false;
String captureFolder = "./frames/";

// Broadcast
ArtNetMulticast multicast;

// Set FrameRate
int fps = 60;        // Frames-per-second

public static final String CABIN_JSON = "../../Data/ArtCabin.json";

// PixelMap and Structures
Structure cabin;
PixelMap pixelMap;  // PixelMap is the master canvas which all animations will draw to
Moonpaper mp;

void verifySize() {
  if (width != pixelMap.pg.width || height != pixelMap.pg.height) {
    println("Set size() in setup to this:");
    println("  size(" + pixelMap.pg.width + ", " + pixelMap.pg.height + ", P2D);");
    exit();
  }
}

void setupPixelMap() {
  // Setup Virtual LED Installation  
  pixelMap = new PixelMap();  // Create 2D PixelMap from strips

  // Create teatro structure
  cabin = new Structure(pixelMap, CABIN_JSON);

  // Once all structures are loaded, finalize the pixelMap
  pixelMap.finalize();
  verifySize();
}

PImage syphonBuffer;
SyphonClient syphonClient;

void setup() {
  size(60, 39, P3D);
  
  syphonClient = new SyphonClient(this);
  
  frameRate(fps);
  
  // Load in structures and create master PixelMap
  setupPixelMap();

  // Setup Broadcasting
  if (START_HOST == "localhost" || START_HOST == "127.0.0.1") 
    multicast = new ArtNetMulticast(pixelMap, cabin.strips, START_PORT, START_HOST);
  else
    multicast = new ArtNetMulticast(pixelMap, cabin.strips, START_HOST, START_PORT);
    
  multicast.setListen(false);
  multicast.setRowsPerPacket(4);
  multicast.setPG(g);
  multicast.setup();

  // Create sequence
  createSequence();
  
  syphonBuffer = loadImage("test.png");
}

void draw() {
  background(0);

  if (syphonClient.newFrame()) {
    syphonBuffer = syphonClient.getImage(syphonBuffer, true);
  }
  
  // Update and display animation
  mp.update();
  mp.display();

  // Capture frame
  if (captureFrames) {
    saveFrame(captureFolder + "f########.png");
  }

  // Broadcast to simulator
  multicast.update();
}
