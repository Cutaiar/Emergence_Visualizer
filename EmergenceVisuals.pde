/*
 * Emergence Visualizer revisited for Aesthetics project.
 *
 * Now called Emergence Visuals. 
 * 
 * An array of particles is updated to reflect the samples of a particlar sound file.
 * Emerging properties of the system are visible as it exectues.
 *
 * Creative Code / Aesthetics
 * Dillon Cutaiar
 * 4/13/19
 */

//--------------- Imports ---------------------------

import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.effects.*;
import ddf.minim.signals.*;
import ddf.minim.spi.*;
import ddf.minim.ugens.*;
import peasy.*;

//--------------- Globals ---------------------------

Minim minim;
FilePlayer filePlayer;
AudioOutput out;
TickRate rateControl;
AudioMetaData meta;

PeasyCam camera;

// The size of every buffer
static final int BUFFER_SIZE = 512;

// The time in milliseconds for the camera to reset
static final int CAMERA_RESET_TIME = 200;

// The angle cameraSpin function calls should rotate the camera each frame
// 0.005 - 0.05 is good
static final float CAMERA_ROTATE_SPEED = 0.007;

// The length of the axis
static final int AXIS_LENGTH = 100;

// The amplitude of the wave
int amp = 520;

// The size of the z thickness
int z_thickness = 75;

// Distance to draw lines within and a factor to control it
float line_thresh = 35;

// An array of particles to draw
Particle[] particles;

// An origin point
PVector origin;

// Booleans to control playback and visualization
boolean recording = false;
boolean drawBG = true;
boolean update = true;
boolean drawElements = false;
boolean drawLines = true;
boolean isSlomo = false;
boolean isAxis = true;
boolean isShowingMetaData = true;
boolean isDoingCameraSpinX = false;
boolean isDoingCameraSpinY = false;
boolean isDoingCameraSpinZ = false;


// Temporary varaibles for x, y, and z updates to particles
float xt;
float yt;
float zt;
float zloc;

//--------------- Setup ---------------------------

void setup() {
    background(0);
    //size(1920, 1080, P3D);
    fullScreen(P3D);

    //Set up camera
    camera = new PeasyCam(this, 1000);
    camera.lookAt(0,0,0);

    // Set origin
    origin = new PVector(0, 0, 0);

    // Create minim object
    minim = new Minim(this);
    
    // Select an audio file
    selectInput("Select an audio file:", "fileSelected");
}

void fileSelected(File selection) {
    String audioFileName = selection.getAbsolutePath();                                   //loading the selected file
    filePlayer = new FilePlayer(minim.loadFileStream(audioFileName, BUFFER_SIZE, true)); //initialising the filePlayer object
    out = minim.getLineOut(2, BUFFER_SIZE);                                              //initialising the audioOut object, no out, no sound.
    meta = filePlayer.getMetaData();
    rateControl = new TickRate(1.f);                                                     //initialising the tickRate object
    filePlayer.patch(rateControl).patch(out);                                            //building the UGen chain, patching the player through the tickRate and into the out object
    rateControl.setInterpolation(true);                                                  //stops the audio from being "scratchy" lower speeds

    particles = new Particle[out.bufferSize()];                                          // Init particles
    for (int i = 0; i < out.bufferSize(); i ++) {
        particles[i] = new Particle();
    }

    filePlayer.play();                                                                   // Play!
}

//--------------- Main draw loop ---------------------------

void draw() {
    if (filePlayer == null) return;
    if (drawBG) background(0);
    if (isShowingMetaData) printMetaData();
    if (isAxis) showAxis(); 
    if (isDoingCameraSpinX) cameraSpinX();
    if (isDoingCameraSpinY) cameraSpinY();
    if (isDoingCameraSpinZ) cameraSpinZ();


    //Main loop through buffer
    for (int i = 0; i < out.bufferSize(); i+= 1) {

        // Update fields based on buffer info
        if (update) {

            // Update particle position and size
            xt = origin.x+out.left.get(i)*amp;
            yt = origin.y+out.right.get(i)*amp;
            zt = origin.z + calculateZ(1, i);
            zloc+=.1;
            particles[i].update(3, xt, yt, zt);


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
            if (a != b && a.loc.dist(b.loc) < line_thresh && drawLines) {
                pushStyle();
                strokeWeight(2);
                stroke(255, 60);
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
        return origin.z + (sin(zloc) + cos(zloc))*amp;
    case 1:
        return origin.z + (sin(zloc) + cos(zloc))*z_thickness;
    case 2:
        return amp/10;
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
void writeOutObj() {
    PrintWriter output = createWriter("testOut2.obj");
    int ac = 1;
    int bc = 1;
    String verts = "";
    String lines = "";
    for (Particle a : particles) {
        verts += "v " + (a.loc.x - origin.x) + " " + (a.loc.y - origin.y) + " " + a.loc.z + "\n";
        for (Particle b : particles) {
            if (a != b && a.loc.dist(b.loc) < line_thresh && drawLines) {
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
    text("Buffersize: " + out.bufferSize(), 5, y+=yi);
    
    text("/: Toggle this panel: " + isShowingMetaData, 5, y+=yi);
    text("z/x: Amplitude: " + amp, 5, y+=yi);
    text("a/s: Position: " + filePlayer.position(), 5, y+=yi);
    text("q/w: Distance Threshhold: " + line_thresh, 5, y+=yi);
    text("b/n: Z_Thickness: " + z_thickness, 5, y+=yi);
    text("e: Toggle elements: " + drawElements, 5, y+=yi);
    text("d: Toggle lines: " + drawLines, 5, y+=yi);
    text("c: Toggle background: " + drawBG, 5, y+=yi);
    text("t: Toggle axis: " + isAxis, 5, y+=yi);
    text("Spacebar: Toggle playback: " + filePlayer.isPlaying(), 5, y+=yi);
    text("p: Write out to file: ", 5, y+=yi);
    text("RIGHT: Do camera spin: " + isDoingCameraSpinX, 5, y+=yi);
    text("DOWN: Do camera spin: " + isDoingCameraSpinY, 5, y+=yi);
    text("UP: Do camera spin: " + isDoingCameraSpinZ, 5, y+=yi);
    text(".: Reset Camera", 5, y+=yi);

    text("Recording: " + recording, 5, y+=yi);
    text("Framerate: " + frameRate, 5, y+=yi);
    camera.endHUD();
}

/*
 * Allow control of the visualization with key presses
 */
void keyPressed() {

    // Toggle MetaDataPanel
    if (key == '/') {
        isShowingMetaData = !isShowingMetaData;
    }
    
    // Toggle automatic camera rotation
    if (keyCode == RIGHT) {
        isDoingCameraSpinX = !isDoingCameraSpinX;
    }
        // Toggle automatic camera rotation
    if (keyCode == DOWN) {
        isDoingCameraSpinY = !isDoingCameraSpinY;
    }
        // Toggle automatic camera rotation
    if (keyCode == UP) {
        isDoingCameraSpinZ = !isDoingCameraSpinZ;
    }
    
    if (key == '.') camera.reset(CAMERA_RESET_TIME);
    
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

    // Adjust Threshold for lines
    if (key == 'w') line_thresh += 15;
    if (key == 'q') line_thresh -= 15;
    
    // Adjust Threshold for lines
    if (key == 'n') z_thickness += 15;
    if (key == 'b') z_thickness -= 15;

    // Toggle Element draw
    if (key == 'e') {
        drawElements = !drawElements;
    }
    
    // Toggle Axis draw
    if (key == 't') {
        isAxis = !isAxis;
    }

    // Write out
    if (key == 'p') {
        writeOutObj();
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

void cameraSpinX() {
    camera.rotateX(CAMERA_ROTATE_SPEED);
}
void cameraSpinY() {
    camera.rotateY(CAMERA_ROTATE_SPEED);
}
void cameraSpinZ() {
    camera.rotateZ(CAMERA_ROTATE_SPEED);
}

void showAxis() {
    stroke(255);
    line(-AXIS_LENGTH, 0, 0, AXIS_LENGTH, 0, 0); //x
    line(0, -AXIS_LENGTH, 0, 0, AXIS_LENGTH, 0); //y
    line(0, 0, -AXIS_LENGTH, 0, 0, AXIS_LENGTH); //z
}
