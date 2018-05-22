void createSequence() {  
  int fpm = fps * 60;  // Frames-per-minute

  StructurePixelMap allStructures = new StructurePixelMap(pixelMap);

  mp = new Moonpaper(this);
  Cel cel0 = mp.createCel(width, height);


  // Start of sequence
  mp.seq(new ClearCels());
  mp.seq(new PushCel(cel0, pixelMap));
  mp.seq(new PatchSet(cel0.getTransparency(), 0.0));

  // Fade in cel
  mp.seq(new PatchSet(cel0.getTransparency(), 0.0));
  mp.seq(new Line(5 * fps, cel0.getTransparency(), 255));

  // Test
  TestPattern test = new TestPattern(pixelMap, allStructures);
  mp.seq(new PatchSet(test.transparency, 255.0));
  mp.seq(new PushCel(cel0, test));
  mp.seq(new Wait(5 * fpm));


  // Drop
  //Drop drop = new Drop(pixelMap, allStructures);
  //mp.seq(new PatchSet(drop.transparency, 255.0));
  //mp.seq(new PushCel(cel0, drop));
  //mp.seq(new Wait(5 * fpm));


  //Syphon syphon = new Syphon(pixelMap, allStructures);
  //mp.seq(new PatchSet(syphon.transparency, 255.0));
  //mp.seq(new PushCel(cel0, syphon));
  //mp.seq(new Wait(5 * fpm));

}
