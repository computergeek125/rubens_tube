// Ruben's Tube Simulator, by Ryan Smith
// Loosely based on Get Line In, by Damien Di Fede
// Picture of flame modified from Wikimedia Comons (http://commons.wikimedia.org/wiki/File:Flame1.jpg)

import ddf.minim.*;

Minim minim;
AudioInput in;
int debug = 0; // The amout of advanced debugging info should be printed (0-2)
boolean mono = false; // If true, both channels will be mixed through the left "tube", and the right
                     //  "tube" will remain "unlit"
int appheight = 300; // The height in pixels that applet will be. Tubes are placed at the halfway mark and bottom
float sampRate = 96000.0; // Sample rate for Minim audio
float sos = 253; // Speed of sound in m/s.  In propane, this value is 253 m/s
float perflength = 100; // Length of the tube that is perforated, in cm.
                        // The actual length of the simulated tube has an extra bit on each end, set by the
                        //  "sidelength" variable below
                        // The sketch width is set by a ratio of 10px/cm
float perfdist = 1; // Distance between perforations, in cm. 1.27cm ~= 0.5"
float maxheight = 5; // Maximum height of the flames, in cm
float sidelength = 5; // Length of pipe on either side of the perforated part, in cm. This is where the
                      //  stands would go on a normal Ruben's Tube

// The following variables are set by the setup code, so do not set them
int appwidth; // Calculated needed width of applet
int numperf; // Calculated number of perforations to use
double idelay_sec; // Calculated initial audio delay for the first 10cm of the tube (in seconds)
double pdelay_sec_; // Calculated audio delay between each perforation (in seconds)
double[] pdelay_sec; // Calculated audio delay for each perforation (in seconds)
int idelay_samp;  // Calculated initial audio delay for the first 10cm of the tube (in samples)
int pdelay_samp_; // Calculated audio delay between each perforation (in samples)
int[] pdelay_samp; // Calculated audio delay for each perforation (in samples)
int buffer = 100; // Minumum multiple of 100 that is above the perforation count, +400 for extra buffer
PImage fire; // Picture of the flame to be used

void setup()
{
  appwidth = int((perflength*10)+sidelength*2*10);
  size(appwidth, appheight, P2D);
  frameRate(240);
  
  numperf = int(perflength / perfdist);
  println("Tube length: "+perflength+20);
  println("Number of perforations: "+numperf);
  println("Tube perforated every "+perfdist+" cm");
  println();
  
  // Calculate audio delays in seconds
  idelay_sec = (sidelength/100)/sos;
  pdelay_sec_ = (perfdist/100)/sos;
  pdelay_sec = new double[numperf];
  for (int i=0; i<pdelay_sec.length;i++) {
    pdelay_sec[i] = idelay_sec+(pdelay_sec_*i);
  }
  
  // Convert the audio delays from seconds to samples
  idelay_samp = int((float)(idelay_sec*sampRate));
  pdelay_samp_ = int((float)(pdelay_sec_*sampRate));
  pdelay_samp = new int[numperf];
  for (int i=0; i<pdelay_samp.length; i++) {
    pdelay_samp[i] = int((float)(pdelay_sec[i]*sampRate));
  }
  
  //enable Minim
  minim = new Minim(this);
  if (debug>=1) minim.debugOn();
  while (buffer<pdelay_samp[pdelay_samp.length-1]) buffer = buffer+100;
  buffer=buffer+400;
  in = minim.getLineIn(Minim.STEREO, buffer, sampRate);
  
  println("Minim running at "+in.getFormat().getSampleRate()+"Hz");
  println("Minim buffer size: "+in.bufferSize());
  println("Initial audio delay is "+idelay_sec+" seconds ("+idelay_samp+" samples)");
  println("Audio delay between each perforation is "+pdelay_sec_+" seconds ("+pdelay_samp_+" samples)");
  if (debug>=1) {
    println("Audio delay for each perforation: (seconds, samples)");
    for (int i=0; i<pdelay_samp.length; i++) {
      println("   "+i+":"+pdelay_sec[i]+", "+pdelay_samp[i]);
    }
  }
  fire = loadImage("Flame1.png");
}

void draw()
{
  background(0);
  stroke(40);
  for (int i=0; i<=perflength; i++) {
    line(sidelength*10+10*i,0,sidelength*10+10*i,height);
  }
  stroke(127);
  for (int i=0; i<=perflength/10; i++) {
    line(sidelength*10+100*i,0,sidelength*10+100*i,height);
    text(i*10+"cm",sidelength*10+5+100*i,20,50,20);
  }
  noStroke();
  fill(200);
  if (!mono) rect(0,(appheight/2)-20,width,20); // Draw the left/mono tube
  rect(0,appheight-20,width,20); // Draw the right tube
  if (mono) {
    for (int i=0; i<pdelay_samp.length; i++) { // Draw each flame for mix input
      double fheight_cm = 0;
      try {
        fheight_cm = (maxheight*in.mix.get(pdelay_samp[i]))+(maxheight/2);
      } catch (ArrayIndexOutOfBoundsException e) {
        println("ArrayIndexOutOfBoundsException on flame "+i);
      }
      if (fheight_cm<0) fheight_cm=0;
      int fheight_px = int((float)(fheight_cm*10));
      flame(sidelength*10+((perfdist*10)*i),(appheight)-20,10,fheight_px,fire);
      if (debug>=2) println(" Flame "+i+" height: "+fheight_cm+"cm, "+fheight_px+"px");
    }
  } else {
    for (int i=0; i<pdelay_samp.length; i++) { // Draw each flame for the left tube
      double fheight_cm = 0;
      try {
        fheight_cm = (maxheight*in.left.get(pdelay_samp[i]))+(maxheight/2);
      } catch (ArrayIndexOutOfBoundsException e) {
        println("ArrayIndexOutOfBoundsException on flame "+i+" left");
      }
      if (fheight_cm<0) fheight_cm=0;
      int fheight_px = int((float)(fheight_cm*10));
      flame(sidelength*10+((perfdist*10)*i),(appheight/2)-20,10,fheight_px,fire);
      if (debug>=2) println(" Flame "+i+" left height: "+fheight_cm+"cm, "+fheight_px+"px");
    }
    for (int i=0; i<pdelay_samp.length; i++) { // Draw each flame for the right tube
      double fheight_cm = 0;
      try {
        fheight_cm = (maxheight*in.right.get(pdelay_samp[i]))+(maxheight/2);
      } catch (ArrayIndexOutOfBoundsException e) {
        println("ArrayIndexOutOfBoundsException on flame "+i+" right");
      }
      if (fheight_cm<0) fheight_cm=0;
      int fheight_px = int((float)(fheight_cm*10));
      flame(sidelength*10+((perfdist*10)*i),appheight-20,10,fheight_px,fire);
      if (debug>=2) println(" Flame "+i+" right height: "+fheight_cm+"cm, "+fheight_px+"px");
    }
  }
  fill(127);
  text(frameRate+" fps",5,5,200,20);
}

void flame(float fx, float fy, float fwidth, float fheight, float bg) {
  // Draw flames as stacked ellipses
  ellipseMode(CORNER);
  fill(75,34,7);
  ellipse(fx,fy,fwidth,-fheight*1.2);
  fill(207,108,14);
  ellipse(fx,fy,fwidth,-fheight*1.1);
  fill(248,236,22);
  ellipse(fx,fy,fwidth,-fheight);
  fill(254,254,251);
  ellipse(fx,fy,fwidth,-fheight*0.7);
  fill(207,108,14);
  ellipse(fx,fy,fwidth,-fheight*0.5);
  fill(75,34,7);
  ellipse(fx,fy,fwidth,-fheight*0.4);
  fill(bg,bg,bg);
  ellipse(fx,fy,fwidth,-fheight*0.3);
}
void flame(float fx, float fy, float fwidth, float fheight, PImage img) {
  // Draw flames as images
  imageMode(CORNERS);
  try {
    image(img,fx,fy,fx+fwidth,fy-(fheight*1.2));
  } catch (java.lang.NullPointerException e) {
    if (debug>=1) println("The image file is missing or inaccessible, make sure the path is valid");
  }
}

void stop()
{
  // always close Minim audio classes when you are done with them
  in.close();
  minim.stop();
  
  super.stop();
}
