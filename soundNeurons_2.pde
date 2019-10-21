//Sound_Neurons.

// Creative coding project that draws a neuron forest based on input music.
// Neuron growth and branching is based on the amplitude and music tone.
// To use it, simply run this code on Processing framework. Needs Sound package
// to run.

//Greatly inspired by work by Asher Salomon (http://www.ashersalomon.com/)
// Designed and coded by Victor M. Saenger, 2019.
// saenger.v at gmail.com

// Improvements by Marc Freixes 2019:

// 1. Parametrized music harmony.
// 2. Added initial pace maker.
// 3. Added json configuration files.
// 4. Improved color coding.
// 5. General improvements to code flow.


//Import libraries and initialize variables
import processing.sound.*;
Amplitude amp;
AudioIn in;
SoundFile file;
int timer;
JSONObject conf;
Table colorTable;
Table chordTable;
Table beatTable;
String chord="";
int chord_t = -1;
int beat_t = -1;
int chord_rowId=0;
int beat_rowId=0;
int chord_nRow=0;
int beat_nRow=0;
int manualTrigger=1;
int randomColors=1;
int colorH=1;
int mIni=0;

// Name of song
// String songName = "The Hobbit: An Unexpected Journey";
// String song="LOTR3";

String songName = "soundNeurons from Claire de Lune, Debussy";
String song="CLAUDE_DEBUSSY_CLAIRE_DE_LUNE_SHORTER";



// Initialize sound neuron class
class soundNeuron {
  //Initialize variables
  PVector location;
  PVector velocity;
  float axonDiameter;
  color neuronColor;
  soundNeuron() {
    float margin=conf.getFloat("location_marg");
    //Define drawing location with certain margin
    location = new PVector(random(margin*width,(1-margin)*width), random(margin*height,(1-margin)*height));//Starting point
    // Initiazlie a 3d Pvector
    velocity = new PVector(0, 0, 0);//third dimension adds growth in third plane (check line 21)
    //axon Diameter based on amplitude
    axonDiameter = map(amp.analyze(),conf.getFloat("axonDiam_Amin"),conf.getFloat("axonDiam_Amax"),conf.getFloat("axonDiam_min"),conf.getFloat("axonDiam_max"));
    //Initialize neruon color
    neuronColor = color(0, 0, 0);
  }
  //Call soundNeuron Class
  soundNeuron(soundNeuron parent) {
    //Set location and velocity
    location = parent.location.get();
    velocity = parent.velocity.get();
    //Set area based on radial rule
    float area = PI*sq(parent.axonDiameter/2);
    //update area. Controls neruon spread.
    float newDiam = sqrt(area/2/PI)*conf.getFloat("neuronSpread");//neuronSpread from 1.5 to 2.2
    axonDiameter = newDiam;
    parent.axonDiameter = newDiam;
    neuronColor=parent.neuronColor;
  }
  //Update function
  void update() {
    //Set given threshold to redraw
    if (axonDiameter>0.5) {
      location.add(velocity);
      //Grow randomly in three dimentions. Third dimention adds more clusterness.
      PVector bump = new PVector(random(-1, 1), random(-1, 1), random(-1, 1));//third dimension adds growth in third plane
      bump.mult(conf.getFloat("neuronBump"));//0.1 for straight motor neurons, higher values for reticulate sommas.
      velocity.add(bump);
      //velocity.normalize();//unchttp://www.ashersalomon.com/omment for linear cell growth speed

      //neuron reach
      if (random(0, 1)<conf.getFloat("neuronReach")) {
        paths = (soundNeuron[]) append(paths, new soundNeuron(this));
      }
    }
  }
  void setColor(color c){
    neuronColor=c;
  }
}
soundNeuron[] paths;

//setup
void setup() {
  // fullScreen();
  size(1760, 990);
  frameRate(50);//neuron growth speed
  background(0);
  ellipseMode(CENTER);
  //fill(random(20,240),random(20,240),random(20,240),100);//random(0,255),random(0,255),random(0,255)
  noStroke();
  smooth();
  colorMode(HSB, 12, 100, 100);

  // LOAD FILES
  // load configuration file
  conf = loadJSONObject(song + ".json");
  // load sound file
  file = new SoundFile(this, song + ".wav");
  // load correspondance between chord and color
  colorTable = loadTable("chord2color.csv", "header");
  // load chords from CNNChordRecognition
  try{
    chordTable = loadTable(song + "_chord.csv","tsv");
    chord_t = round(chordTable.getFloat(0,0)*1000);
    chord_nRow=chordTable.getRowCount();
    randomColors=1;
  }catch(Exception e) {
    e.printStackTrace();
  }

  // load beats
  try{
    beatTable = loadTable(song + "_manual_beats2.txt", "tsv");
    beat_t = round(beatTable.getFloat(0,0)*1000);
    beat_nRow=beatTable.getRowCount();
    manualTrigger=0;
  }catch(Exception e) {
    e.printStackTrace();
  }

  // audio analysis
  amp = new Amplitude(this);
  in = new AudioIn(this, 0);
  in.start();
  amp.input(file);

  // init neuron
  paths = new soundNeuron[1];
  paths[0] = new soundNeuron();

  // play the audio
  file.play();
}

void draw() {

  if (mIni==0)
  {
    mIni=millis();
    textFont(createFont("Mono", 11));     // STEP 3 Specify font to be used
    text(songName,width-250,height-10);
  }
  //println(millis()-mIni + " " + beat_t + " " + chord_t);

  // read chord
  if (randomColors>0){
    colorH=round(random(1,12));
  }
  else{
    if (millis()-mIni+conf.getFloat("chord_pretime")>=chord_t && chord_rowId<chord_nRow)
    {
      chord = chordTable.getString(chord_rowId,2);
      //println("[" + chord_t + "] chord:" + chord);
      TableRow result = colorTable.findRow(chord, "chord");
      if (result!=null)
      {
        colorH = result.getInt("h");
      }
      chord_rowId++;
      if (chord_rowId<chord_nRow)
      {
        chord_t = round(chordTable.getFloat(chord_rowId,0)*1000);
      }
    }
  }
  // read beat
  if (manualTrigger<1){
    if (millis()-mIni+conf.getFloat("beat_pretime")>=beat_t && beat_rowId<beat_nRow)
    {
      int beat=beatTable.getInt(beat_rowId,2);
      println("[" + beat_t + "] beat:" + beat + " chord: " + chord);
      //int beat =1;
      //println("[" + beat_t + "] chord: " + chord);
      if (beat==1)
      {
        color bg = color(colorH, conf.getFloat("saturation"), conf.getFloat("brigthness"));
        reset_neurons(bg);
      }
      beat_rowId++;
      if (beat_rowId<beat_nRow)
      {
        beat_t = round(beatTable.getFloat(beat_rowId,0)*1000);
      }
    }
  }

  //println(amp.analyze());

  // frameRate proportional to the audio amplitude   [frameRate(map(amp.analyze(),0.015,0.9,15,144));]
  frameRate(map(amp.analyze(),conf.getFloat("frameRate_Amin"),conf.getFloat("frameRate_Amax"),conf.getFloat("frameRate_min"),conf.getFloat("frameRate_max")));

  // Update the neurons
  for (int i=0;i<paths.length;i++) {
    PVector loc = paths[i].location;
    float diam = paths[i].axonDiameter;
    fill(paths[i].neuronColor);
    ellipse(loc.x, loc.y, diam, diam);
    //fill(255,50);//extra transparency
    paths[i].update();
  }
}
//Reset neruons
 void reset_neurons(color bg) {
   paths[0] = new soundNeuron();
   paths[0].setColor(bg);
   timer = millis();
}
