/*
 * Emergence Visualizer Revisited for Aesthetics project
 *
 * An array of particles is updated to reflect the waveform of a particlar sound file.
 * Emerging properties of the system are visible as it exectues.
 *
 * Creative Code / Aesthetics
 * Dillon Cutaiar
 * 10/15/17
 */
/***************************************SETUP***************************************/

// Import sound library
import ddf.minim.analysis.*;
import ddf.minim.*;
import peasy.*;


// Setting up various Miniim things
Minim minim;
AudioPlayer song;
FFT fft;
AudioMetaData meta;

// Set up Camera
PeasyCam camera;


// The name of the file to play
// Change the name to change the track (remember file extension)
String soundfile = "tracks/" + "rain.mp3";

// The buffer size to traverse the song with
static final int BUF_SIZE = 256;

// The amplitude of the wave
int amp = 520;

// variable color of stroke (not used)
float lCol;
float rCol;
float mCol;

// Distance to draw lines within and a factor to control it
float thresh = 0;
float threshFac = 520;

// An array of particles to draw
Particle[] particles = new Particle[BUF_SIZE];

// An origin point
PVector origin;

// Booleans to control playback and visualization
boolean recording = false;
boolean drawBG = true;
boolean update = true;
boolean drawElements = true;
boolean drawLines = true;

void setup() {
  background(0);
  size(1920, 1080, P3D);

  //Set up camera
  camera = new PeasyCam(this, 0, 0, 0, 1000);

  // Set origin
  origin = new PVector(0, 0, 0);//new PVector(width/2, height/2);

  // Create minim object
  minim = new Minim(this);

  // Initialize array
  for (int i = 0; i < BUF_SIZE; i ++) {
    particles[i] = new Particle();
  }

  // this loads song from the data folder, plays it, and gets metadata
  song = minim.loadFile(soundfile, BUF_SIZE);
  song.play();
  meta = song.getMetaData();
  // create an FFT object that has a time-domain buffer 
  // the same size as songs sample buffer
  // note that this needs to be a power of two 
  // and that it means the size of the spectrum will be half as large.
  fft = new FFT(song.bufferSize(), song.sampleRate());
  
  
}


/***************************************ANIMATION LOOP***************************************/

float xt;
float yt;
float zt;
void draw() {
  if (drawBG) background(0);
  printMetaData();
  showAxis();


  //Main loop through buffer
  for (int i = 0; i < song.bufferSize(); i+= 1) {

    // Update fields based on buffer info
    if (update) {

      // FFT on the song
      fft.forward(song.mix);

      // Update particle position and size
      xt = origin.x+song.left.get(i)*amp;
      yt = origin.y+song.right.get(i)*amp;
      zt = origin.z+ fft.getBand(i)* amp/10;//noise(song.mix.get(i))*amp;//noise((xt+yt)/2);
      //println (zt);
      particles[i].update(3, xt, yt, zt);

      // Unused color stuff
      //lCol = map(song.left.get(i), -.5, .5, 100, 255);
      //rCol = map(song.right.get(i), -.5, .5, 100, 255);
      //mCol = map(song.mix.get(i), -.5, .5, 100, 255);
      //println("left: " + lCol);
      //println("right: " +rCol);

      // Update the distance threshhold according to frequency
      thresh = fft.getBand(i)*threshFac;

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
        strokeWeight(5);
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


/***************************************CLASSES AND FUNCTIONS***************************************/

/*
 * Particle class.
 * Baisically a fancy ellispe.
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
  text("File Name: " + meta.fileName(), 5, y);
  text("Length (in milliseconds): " + meta.length(), 5, y+=yi);
  text("Title: " + meta.title(), 5, y+=yi);
  text("Author: " + meta.author(), 5, y+=yi); 
  text("Album: " + meta.album(), 5, y+=yi);
  text("Date: " + meta.date(), 5, y+=yi);
  text("Comment: " + meta.comment(), 5, y+=yi);
  text("Track: " + meta.track(), 5, y+=yi);
  text("Genre: " + meta.genre(), 5, y+=yi);
  text("Copyright: " + meta.copyright(), 5, y+=yi);
  text("Disc: " + meta.disc(), 5, y+=yi);
  text("Composer: " + meta.composer(), 5, y+=yi);
  text("Orchestra: " + meta.orchestra(), 5, y+=yi);
  text("Publisher: " + meta.publisher(), 5, y+=yi);
  text("Encoded: " + meta.encoded(), 5, y+=yi);
  text("z/x: Amplitude: " + amp, 5, y+=yi);
  text("a/s: Position: " + song.position(), 5, y+=yi);
  text("q/w: Distance Threshhold: " + threshFac, 5, y+=yi);
  text("e: Toggle elements: " + drawElements, 5, y+=yi);
  text("d: Toggle lines: " + drawLines, 5, y+=yi);
  text("c: Toggle background: " + drawBG, 5, y+=yi);
  text("Spacebar: Toggle playback: " + song.isPlaying(), 5, y+=yi);
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
  if (key == ' ' && song.isPlaying()) {
    song.pause();
    update = false;
  } else if (key == ' ') {
    song.play(); 
    update = true;
  }

  // Adjust amplitude
  if (key == 'x') amp += 100;
  if (key == 'z') amp -= 100;

  // Adjust playback
  if ( key == 's' ) song.skip(1000);
  if ( key == 'a' ) song.skip(-1000);

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
    if (frameRate == 10){
      frameRate(60);
    } else {
      frameRate(10);
    }
  }
  
}

void showAxis() {
  stroke(255);
  line(0, 0, 0, width, 0, 0); //x
  line(0, 0, 0, 0, height, 0); //y
  line(0, 0, 0, 0, 0, width); //z
  line(0, 0, 0, -width, 0, 0); //-x
  line(0, 0, 0, 0, -height, 0); //-y
  line(0, 0, 0, 0, 0, -width); //-z
}
