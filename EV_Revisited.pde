/*
 * Emergence Visualizer revisited for Aesthetics project
 * 
 *
 * An array of particles is updated to reflect the waveform of a particlar sound file.
 * Emerging properties of the system are visible as it exectues.
 *
 * Creative Code / Aesthetics
 * Dillon Cutaiar
 * 4/13/19
 */
 
//--------------- Imports ---------------------------

// Import sound library
import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.effects.*;
import ddf.minim.signals.*;
import ddf.minim.spi.*;
import ddf.minim.ugens.*;
import peasy.*;

//--------------- Globals ---------------------------

Minim minim;
FFT fft;
FilePlayer filePlayer;
AudioOutput out;
TickRate rateControl;

PeasyCam camera;

// The amplitude of the wave
int amp = 520;

// Distance to draw lines within and a factor to control it
float thresh = 0;
float threshFac = 520;

float zloc;

// An array of particles to draw
Particle[] particles;

// An origin point
PVector origin;

// Booleans to control playback and visualization
boolean recording = false;
boolean drawBG = true;
boolean update = true;
boolean drawElements = true;
boolean drawLines = true;
boolean isSlomo = false;

// Temporary varaibles for x, y, and z updates to particles
float xt;
float yt;
float zt;

//--------------- Setup ---------------------------

void setup() {
  background(0);
  size(1920, 1080, P3D);
  //fullScreen(P3D);

  //Set up camera
  camera = new PeasyCam(this, 0, 0, 0, 1000);

  // Set origin
  origin = new PVector(0, 0, 0);//new PVector(width/2, height/2);

  // Create minim object
  minim = new Minim(this);
  selectInput("Select an audio file:", "fileSelected");
}

void fileSelected(File selection) {
  String audioFileName = selection.getAbsolutePath();               //loading the selected file
  filePlayer = new FilePlayer(minim.loadFileStream(audioFileName)); //initialising the filePlayer object
  out = minim.getLineOut();                                         //initialising the audioOut object, no out, no sound.
  fft = new FFT(out.bufferSize(), filePlayer.sampleRate());         //initialising the FFT object, setting the out buffersize to the selected file samplerate
  rateControl = new TickRate(1.f);                                  //initialising the tickRate object
  filePlayer.patch(rateControl).patch(out);                         //building the UGen chain, patching the player through the tickRate and into the out object
  rateControl.setInterpolation(true);                               //stops the audio from being "scratchy" lower speeds
  
  particles = new Particle[out.bufferSize()];
  for (int i = 0; i < out.bufferSize(); i ++) {
    particles[i] = new Particle();
  }
  
  filePlayer.play();
}

//--------------- Main draw loop ---------------------------

void draw() {
  if (filePlayer == null) return;
  if (drawBG) background(0);
  printMetaData();
  showAxis();

  //Main loop through buffer
  for (int i = 0; i < out.bufferSize(); i+= 1) {

    // Update fields based on buffer info
    if (update) {

      // FFT on the song
      fft.forward(out.mix);

      // Update particle position and size
      xt = origin.x+out.left.get(i)*amp;
      yt = origin.y+out.right.get(i)*amp;
      zt = origin.z + calculateZ(1, i);
      zloc+=.1;
      //println (zt);
      particles[i].update(3, xt, yt, zt);

      // Update the distance threshhold according to frequency
      //thresh = fft.getBand(i)*threshFac;
      thresh = 200;

      /*
      // Draw the elements (unused in this loop)
       if (drawElements) {
       particles[i].show();
       }
       for (Particle b : particles) {
       
       // Draw lines
       if (particles[i] != b && particles[i].loc.dist(b.loc) < thresh && drawLines) {
       pushStyle();
       stroke(255, 30);
       //stroke(mCol, lCol, rCol, 60);
       line(particles[i].loc.x, particles[i].loc.y, b.loc.x, b.loc.y);
       popStyle();
       }*/
    }
  }


  // A main loop through each particle (in relation to every other)
  for (Particle a : particles) {

    // Draw the elements
    if (drawElements) {
      a.show();
    }
    for (Particle b : particles) {

      // Draw lines
      if (a != b && a.loc.dist(b.loc) < thresh && drawLines) {
        pushStyle();
        strokeWeight(2);
        stroke(255, 60);
        //stroke(mCol, lCol, rCol, 60);
        line(a.loc.x, a.loc.y, a.loc.z, b.loc.x, b.loc.y, b.loc.z);
        popStyle();
      }
    }
  }

  // Allow rendering of the frames
  if (recording) {
    saveFrame("output/render_####.png");
  }
}

/**
 * Depending on mode, calculate the z coordinate of the particle
 */
float calculateZ(int mode, int i) {
  switch (mode) {
    case 0:
      return origin.z + (sin(zloc) + cos(zloc))*amp*fft.getBand(i);
    case 1:
      return origin.z + (sin(zloc) + cos(zloc))*amp;
    case 2:
      return fft.getBand(i)* amp/10;
    case 3:
      return noise(out.mix.get(i))*amp;
    default:
      return 0;
  }
}

//--------------- Particle Class ---------------------------

/*
 * Particle class
 */
class Particle {
  PVector loc;
  float size;

  Particle() {
    loc = new PVector(0, 0, 0);
    size = 0;
  }

  void update(float sizeIn, float xIn, float yIn, float zIn) {
    size = sizeIn;
    loc.x = xIn;
    loc.y = yIn;
    loc.z = zIn;
  }

  void show() {
    pushStyle();
    fill(255, 0, 0, 80);
    noStroke();
    //ellipse(loc.x, loc.y, size, size);
    pushMatrix();
    translate(loc.x, loc.y, loc.z);
    sphere(size);
    popMatrix();
    popStyle();
  }
}


//--------------- Helper functions ---------------------------

/*
 * Write current data out to a obj file
 */
void writeOut() {
  PrintWriter output = createWriter("testOut2.obj");
  int ac = 1;
  int bc = 1;
  String verts = "";
  String lines = "";
  for (Particle a : particles) {
    verts += "v " + (a.loc.x - origin.x) + " " + (a.loc.y - origin.y) + " " + a.loc.z + "\n";
    for (Particle b : particles) {
      if (a != b && a.loc.dist(b.loc) < thresh && drawLines) {
        lines += "l " + ac + " " + bc + "\n";
      }
      bc++;
    }
    ac++;
    bc = 1;
  }
  output.println(verts);
  output.println(lines);
  output.flush();
  output.close();
}

/*
 * Display important data for the user
 */
void printMetaData() {
  camera.beginHUD();
  int ys = 15;
  int yi = 15;
  int y = ys;
  stroke(255);
  //text("File Name: " + meta.fileName(), 5, y);
  //text("Length (in milliseconds): " + meta.length(), 5, y+=yi);
  //text("Title: " + meta.title(), 5, y+=yi);
  //text("Author: " + meta.author(), 5, y+=yi); 
  //text("Album: " + meta.album(), 5, y+=yi);
  //text("Date: " + meta.date(), 5, y+=yi);
  //text("Comment: " + meta.comment(), 5, y+=yi);
  //text("Track: " + meta.track(), 5, y+=yi);
  //text("Genre: " + meta.genre(), 5, y+=yi);
  //text("Copyright: " + meta.copyright(), 5, y+=yi);
  //text("Disc: " + meta.disc(), 5, y+=yi);
  //text("Composer: " + meta.composer(), 5, y+=yi);
  //text("Orchestra: " + meta.orchestra(), 5, y+=yi);
  //text("Publisher: " + meta.publisher(), 5, y+=yi);
  //text("Encoded: " + meta.encoded(), 5, y+=yi);
  text("z/x: Amplitude: " + amp, 5, y+=yi);
  //text("a/s: Position: " + out.position(), 5, y+=yi);
  text("q/w: Distance Threshhold: " + threshFac, 5, y+=yi);
  text("e: Toggle elements: " + drawElements, 5, y+=yi);
  text("d: Toggle lines: " + drawLines, 5, y+=yi);
  text("c: Toggle background: " + drawBG, 5, y+=yi);
  //text("Spacebar: Toggle playback: " + .isPlaying(), 5, y+=yi);
  text("p: Write out to file: ", 5, y+=yi);
  text("Recording: " + recording, 5, y+=yi);
  text("Framerate: " + frameRate, 5, y+=yi);
  camera.endHUD();
}

/*
 * Allow control of the visualization with key presses
 */
void keyPressed() {

  // Toggle playback
  if (key == ' ' && filePlayer.isPlaying()) {
    filePlayer.pause();
    update = false;
  } else if (key == ' ') {
    filePlayer.play(); 
    update = true;
  }

  // Adjust amplitude
  if (key == 'x') amp += 100;
  if (key == 'z') amp -= 100;

  // Adjust playback
  if ( key == 's' ) filePlayer.skip(1000);
  if ( key == 'a' ) filePlayer.skip(-1000);

  // Adjust Threshold factor for lines
  if (key == 'w') threshFac += 15;
  if (key == 'q') threshFac -= 15;

  // Toggle Element draw
  if (key == 'e') {
    drawElements = !drawElements;
  }

  // Write out
  if (key == 'p') {
    writeOut();
  }

  // Toggle Line draw
  if (key == 'd') {
    drawLines = !drawLines;
  }

  // Toggle BG draw
  if (key == 'c') {
    drawBG = !drawBG;
  }
  
  // Toggle slomo
  if (key == 'l') {
    toggleSlomo();
  }
  
}

void toggleSlomo() {
    filePlayer.unpatch(out);
    filePlayer.unpatch(rateControl);
    rateControl = (isSlomo) ? new TickRate(0.5) : new TickRate(1.f);
    filePlayer.patch(rateControl).patch(out);
  isSlomo = !isSlomo;
}

void showAxis() {
  int axisLength = 100;
  stroke(255);
  line(0, 0, 0, axisLength, 0, 0); //x
  line(0, 0, 0, 0, axisLength, 0); //y
  line(0, 0, 0, 0, 0, axisLength); //z
  line(0, 0, 0, -axisLength, 0, 0); //-x
  line(0, 0, 0, 0, -axisLength, 0); //-y
  line(0, 0, 0, 0, 0, -axisLength); //-z
}
