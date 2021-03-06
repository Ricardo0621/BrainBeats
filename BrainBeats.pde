// Ricardo Diaz: CS Student at Universidad del Valle (Colombia), Camaleón Research Group  //<>//
// CreativeCommons-Sharealike
// BrainBeats:
// Uses brainwave measurements sent from a NeuroSky EEG device (MindWave) to determine 
// which pattern (from an array) to loop. Sends out MIDI CC values based
// on the MindSet's Attention & Meditation values and displays brainwave measurement on screen

// Special thanks to Collin Cunningham for providing the base code for this project
// you can find more of his work here: http://www.collinmel.com/
// Working on Processing 3.3.7
// Required Libraries: 
// proMIDI: https://github.com/dearmash/Processing/tree/master/libraries/promidi
// MindSetProcessing : http://jorgecardoso.eu/processing/MindSetProcessing/
// Required Devices:
// NeuroSky MindWave: https://store.neurosky.com/ 
// Pc with BlueTooth connectivity: Currently working on Lenovo G40-30, Win 8.1

/** Processing custom library */
import processing.serial.*;
/** proMIDI library */
import promidi.*;
/** MindSetProcessing library */
import pt.citar.diablu.processing.mindset.*;

//import org.junit.Assert*;
/** MindWave variables change serialPort for the serial port using the EEG device, something like COM5 on Windows or /dev/ttys0 on linux */
/** Use always the output com port -> MindWave Mobile 'Dev A' */
MindSet mindset;
Serial serialPortArduino6;
Serial serialPortArduino9;
Serial serialPortArduino10;
String serialPort = "COM3";
/** Use these to scale frequency levels to something more usable */
float thetaFactor = 1000.0;
float alphaFactor = 1000.0;
float deltaFactor = 1000.0;
float betaFactor = 500.0;
float gammaFactor = 500.0;
int thetaVal, alphaVal, betaVal, gammaVal, attVal, medVal, deltaVal, highAlphaVal, midGammaVal, attOut, medOut = 0;
// MIDI VARIABLES
int tempo = 145;
// these 2 variables define the controller #s which we'll send out over MIDI
int attCC = 8;
int medCC = 9;
// These are that MIDI notes that I have setup with each instrument in my DAW
int G4 = 67;
int B4 = 71;
int D5 = 74;
int G5Flat = 78;
int G2 = 43;
int D3 = 50;
int G3 = 55;
// curious, should control note's duration, no luck with it myself, ymmv
int noteLength = 1;
// raw values
int raw_delta, raw_theta, raw_alpha, raw_beta, raw_gamma, raw_high_alpha, raw_mid_gamma = 0;
PFont fuente;
// more MIDI parts
Sequencer sequencer;
Song song;
Track g4Track, b4Track, d5Track, g5FlatTrack, g2Track, d3Track, g3Track;
Controller attController, medController;
MidiOut midiOut;
// Widgets
SampleWidget attentionWidget;
SampleWidget meditationWidget;
SampleWidget signalWidget;

SampleWidget deltaWidget;
SampleWidget thetaWidget;
SampleWidget lowAlphaWidget;
SampleWidget highAlphaWidget;
SampleWidget lowBetaWidget;
SampleWidget highBetaWidget;
SampleWidget lowGammaWidget;
SampleWidget midGammaWidget;

void setup() {
  size(1366, 768);
  smooth(4);
  background(255);
  fullScreen();
  fuente = createFont("", 13);
  textAlign(LEFT);
  textFont(fuente);
  attentionWidget = new SampleWidget(100, false, 100);
  meditationWidget = new SampleWidget(100, false, 100);
  signalWidget = new SampleWidget(50, false, 200);

  deltaWidget = new SampleWidget(200, true, 0);
  thetaWidget = new SampleWidget(200, true, 0);
  lowAlphaWidget = new SampleWidget(200, true, 0);
  highAlphaWidget = new SampleWidget(200, true, 0);
  lowBetaWidget = new SampleWidget(200, true, 0);
  highBetaWidget = new SampleWidget(200, true, 0);
  lowGammaWidget = new SampleWidget(200, true, 0);
  midGammaWidget = new SampleWidget(200, true, 0);

  // MIDI Setup
  // initializes all the components of our proMIDI sequencer
  sequencer = new Sequencer();
  // Use this method to get instance of MidiIO. It makes sure that only one
  // instance of MidiIO is initialized. You have to give this method a reference
  // to
  // your applet, to let promidi communicate with it.
  MidiIO midiIO = MidiIO.getInstance();
  // Muestra los dispositivos MIDI disponibles en el equipo
  midiIO.printDevices();
  midiIO.closeOutput(1);
  // Abre un Midiout usando el primer dispositivo y el primer canal
  midiOut = midiIO.getMidiOut(0, 2);
  // Se definen los parametros inic.mnW5iales de atencion y meditacion
  // Controller Class -> representa un controlador MIDI
  // Tiene un numero y un valor se pueden recibir valores de midi ins y enviarlos
  // a midi outs
  attController = new Controller(attCC, 100);
  medController = new Controller(medCC, 100);
  // A song is a data structure containing musical information
  // that can be played back by the proMIDI sequencer object. Specifically, the
  // song contains timing information and one or more tracks. Each track consists
  // of a
  // series of MIDI events (such as note-ons, note-offs, program changes, and
  // meta-events).
  song = new Song("beat", tempo);
  // A track handles all midiEvents of a song for a certain midiout. You can
  // directly
  // add Events like Notes or ControllerChanges to it or also work with patterns.
  g4Track = new Track("g4", midiOut);
  // Establece el tiempo de duracion de duracion de una nota: 8-> corcheas
  g4Track.setQuantization(Q._1_8);
  b4Track = new Track("b4", midiOut);
  b4Track.setQuantization(Q._1_8);
  d5Track = new Track("d5", midiOut);
  d5Track.setQuantization(Q._1_8);
  g5FlatTrack = new Track("g5Flat", midiOut);
  g5FlatTrack.setQuantization(Q._1_8);
  g2Track = new Track("g2", midiOut);
  g2Track.setQuantization(Q._1_8);
  d3Track = new Track("d3", midiOut);
  d3Track.setQuantization(Q._1_8);
  g3Track = new Track("g3", midiOut);
  g3Track.setQuantization(Q._1_8);
  song.addTrack(g4Track);
  song.addTrack(b4Track);
  song.addTrack(d5Track);
  song.addTrack(g5FlatTrack);
  song.addTrack(g2Track);
  song.addTrack(d3Track);
  song.addTrack(g3Track);
  sequencer.setSong(song);
  // Sets the startpoint of the loop the sequencer should play
  sequencer.setLoopStartPoint(0);
  // Sets the endpoint of the loop the sequencer should play
  sequencer.setLoopEndPoint(512);
  // Sets how often the loop of the sequencer has to be played.
  sequencer.setLoopCount(-1);

  // MINDSET SETUP
  // display the list of avaible serial ports for your convenience
  // println(Serial.list());
  // println("");

  // start a connection to the mindset
  mindset = new MindSet(this, serialPort);
  serialPortArduino6 = new Serial(this, "COM8", 9600);
  serialPortArduino9 = new Serial(this, "COM9", 9600);
  serialPortArduino10 = new Serial(this, "COM10", 9600);
}

void pasoDeMensajes() {
  // Los niveles de attención y meditación estan entre 0-127 para el manejo de
  // datos MIDI
  // 0: Yellow. 1: Orange. 2: Red. 3: Dark Pink. 4: Cyan. 5: Blue. 6: Indigo. 7:
  // Blue Violet. 8: Green. 9: Chocolate
  // (0-60)(60-90)(90-110)(110-127)
  // (0-20)(20-40)(40-60)
  if (attVal >= 0 && attVal <= 20) {
    serialPortArduino6.write('A');
    serialPortArduino6.write('D');
  }
  if (attVal >= 21 && attVal <= 40) {
    serialPortArduino6.write('B');
    serialPortArduino6.write('C');
  }
  if (attVal >= 41 && attVal <= 60) {
    serialPortArduino6.write('C');
    serialPortArduino6.write('D');
  }
  if (attVal >= 61 && attVal <= 90) {
    serialPortArduino6.write('1');
    serialPortArduino6.write('2');
  }
  if (attVal >= 91 && attVal <= 110) {
    serialPortArduino6.write('2');
    serialPortArduino6.write('1');
  }
  if (attVal >= 111) {
    serialPortArduino6.write('3');
    serialPortArduino6.write('0');
  }
  if (medVal >= 0 && medVal <= 20) {
    serialPortArduino9.write('E');
    serialPortArduino9.write('A');
  }
  if (medVal >= 21 && medVal <= 40) {
    serialPortArduino9.write('B');
    serialPortArduino9.write('F');
  }
  if (medVal >= 41 && medVal <= 60) {
    serialPortArduino9.write('4');
    serialPortArduino9.write('7');
  }
  if (medVal >= 61 && medVal <= 90) {
    serialPortArduino9.write('5');
    serialPortArduino9.write('6');
  }
  if (medVal >= 91 && medVal <= 110) {
    serialPortArduino9.write('6');
    serialPortArduino9.write('5');
  }
  if (medVal >= 111) {
    serialPortArduino9.write('7');
    serialPortArduino9.write('4');
  }
  if ((attVal >= 21 && attVal <= 40) && (medVal >= 21 && medVal <= 40)) {
    serialPortArduino10.write('D');
    serialPortArduino10.write('7');
  }
  if ((attVal >= 21 && attVal <= 40) && (medVal >= 61 && medVal <= 90)) {
    serialPortArduino10.write('F');
    serialPortArduino10.write('3');
  }
  if ((attVal >= 21 && attVal <= 40) && (medVal >= 91 && medVal <= 110)) {
    serialPortArduino10.write('5');
    serialPortArduino10.write('B');
  }
  if ((attVal >= 21 && attVal <= 40) && (medVal >= 111)) {
    serialPortArduino10.write('A');
    serialPortArduino10.write('8');
  }
  if ((attVal >= 21 && attVal <= 40) && (medVal >= 91 && medVal <= 110)) {
    serialPortArduino10.write('F');
    serialPortArduino10.write('3');
  }
  if ((attVal >= 41 && attVal <= 60) && (medVal >= 21 && medVal <= 40)) {
    serialPortArduino10.write('D');
    serialPortArduino10.write('2');
  }
  if ((attVal >= 41 && attVal <= 60) && (medVal >= 41 && medVal <= 60)) {
    serialPortArduino10.write('B');
    serialPortArduino10.write('3');
  }
  if ((attVal >= 41 && attVal <= 60) && (medVal >= 61 && medVal <= 90)) {
    serialPortArduino10.write('3');
    serialPortArduino10.write('9');
  }
  if ((attVal >= 61 && attVal <= 90) && (medVal >= 61 && medVal <= 90)) {
    serialPortArduino10.write('A');
    serialPortArduino10.write('F');
  }
  if ((attVal >= 91 && attVal <= 110) && (medVal >= 91 && medVal <= 110)) {
    serialPortArduino10.write('B');
    serialPortArduino10.write('5');
  }
  if (attVal >= 111 && medVal >= 111) {
    serialPortArduino10.write('s');
    serialPortArduino10.write('b');
  }
  println("Attention: " + attVal + " Relaxation: " + medVal);
  serialPortArduino6.clear();
  serialPortArduino9.clear();
  serialPortArduino10.clear();
}

// simple instructions text
void draw() { 

  //fill(0, 102, 153);
  //text("Attention Level", 10, 15);
  //attentionWidget.draw(10, 10+20, 200, 150, 255, 35, 55); //Rojo Claro

  //text("Meditation Level", 10, 200);
  //meditationWidget.draw(10, 200+20, 200, 150, 44, 86, 255); //Azul Claro

  //text("Signal quality", 10, height-10-20-100);
  //signalWidget.draw(10, height-100-10, 200, 100, 255, 255, 255); //Blanco

  //int h = height/10;
  //text("Delta:", width/2-80, 10+h/2);
  //text("< 4 Hz", width/2-80, 10+ (h-60) + h/2);
  //deltaWidget.draw(width/2, 10, width/2, h, 12, 200, 255); //Casi Cyan

  //text("Theta:", width/2-80, 10+(h+10) + h/2);
  //text("4Hz - 7Hz", width/2-80, 10+(h+25) + h/2);
  //thetaWidget.draw(width/2, 10+(h+10), width/2, height/10, 175, 70, 255); //Morado

  //text("Low alpha:", width/2-80, 10+(h+10)*2 + h/2);
  //text("8Hz - 10Hz ", width/2-80, 10+(h+17)*2 + h/2);
  //lowAlphaWidget.draw(width/2, 10+(h+10)*2, width/2, height/10, 255, 142, 255); //Rosado Claro

  //text("High alpha:", width/2-80, 10+(h+10)*3 + h/2);
  //text("10Hz – 12 Hz", width/2-80, 10+(h+15)*3 + h/2);
  //highAlphaWidget.draw(width/2, 10+(h+10)*3, width/2, height/10, 255, 0, 255); //Rosado Oscuro

  //text("Low beta:", width/2-80, 10+(h+10)*4 + h/2);
  //text("12Hz - 15Hz", width/2-80, 10+(h+13)*4 + h/2);
  //lowBetaWidget.draw(width/2, 10+(h+10)*4, width/2, height/10, 255, 77, 77); //Rojo Claro

  //text("High beta:", width/2-80, 10+(h+10)*5 + h/2);
  //text("21Hz - 30Hz", width/2-80, 10+(h+13)*5 + h/2);
  //highBetaWidget.draw(width/2, 10+(h+10)*5, width/2, height/10, 255, 0, 0); //Rojo 

  //text("Low gamma:", width/2-80, 10+(h+10)*6 + h/2);
  //text("30Hz - 60Hz", width/2-80, 10+(h+12)*6 + h/2);
  //lowGammaWidget.draw(width/2, 10+(h+10)*6, width/2, height/10, 255, 125, 78); //Naranja Claro     

  //text("Mid gamma:", width/2-80, 10+(h+10)*7 + h/2);
  //text("60Hz - 80Hz", width/2-80, 10+(h+12)*7 + h/2);
  //midGammaWidget.draw(width/2, 10+(h+10)*7, width/2, height/10, 255, 68, 0); //Naranja Oscuro
  //deltaVal, highAlphaVal, midGammaVal, thetaVal, alphaVal, betaVal, gammaVal
  float time = millis()/1000.;
  randomSeed(9999); //Semilla para el elemento random lo que hace que los puntos se desplazen. COn 1 los puntos son gigantes
  //randomSeed(1200);
  int cc = deltaVal; //Cantidad de puntos de pintura. Gamma, Alpha, Theta, Delta
  //println(cc);
  //int cc = 120;
  //deltaVal y gammaVal -> Caóticos
  //alphaVal y highAlphaVal -> Normal
  //Faltan hacer más pruebas con diferentes combinaciones de ondas
  int div = gammaVal; //High gamma, High Alpha, Beta, Gamma
  //int div = 24; //Afecta el tamaño de los puntos, entre mas pequeño el valor más grandes los puntos
  float ss = width*1./div; //Divide el ancho de la pantalla entre div
  stroke(0, 50); //Dibuja bordes en cada circulo. Hace el efecto de generar cada circulo a la vez. El primero argumento es el color el RGB, el segundo es la opacidad, a mayor opacidad más bordeado el circulo
  //noStroke(); //Desabilita dibujar bordes
  for (int i = 0; i < cc; i++) {
    float x = int(random(div+1))*ss;
    float y = int(random(div+1))*ss;
    float desplazamiento = time*random(0.1, 1)*60*(int(random(2))*2-1); //Puede ser negativo
    if (random(1) > 0.5) {
      x += desplazamiento;
      if (x < -ss) x = width*ss*2-(abs(x)%(width+ss));
      if (x > width+ss) x = (x%(width+ss))-ss;
    } else {
      y += desplazamiento;
      if (y < -ss) y = height*ss*2-(abs(y)%(height+ss));
      if (y > height+ss) y = (y%(height+ss))-ss;
    }
    float s = ss*random(1)*(1-cos(time*random(1))*random(1)); //Efecto ola
    float c = random(colors.length)+time*random(-1, 1);
    if (c < 0) c = abs(c);
    fill(getColor(c), random(attVal, medVal)); //Llena el circulo de un color y una opacidad
    ellipse(x, y, s, s); //Hace una elipse de alto-ancho s
    //arc(attVal, medVal, alphaVal , highAlphaVal, 0, PI+QUARTER_PI, CHORD);
  }
}

int colors[] = {#fbff05, #ffa305, #ff054c, #ff05c1, #680885, #0e0b57, #4287f5, #0ba9e3, #11a63b, #043b31, #ffffff};
int seed = int(random(999999));

int getColor(float v) {
  v = v%(colors.length);
  int c1 = colors[int(v%colors.length)];
  int c2 = colors[int((v+1)%colors.length)];
  //Calcula un color entre dos colores con un incremento específico. 
  //El último parámetro es la cantidad a interpolar entre los dos primeros colores
  return lerpColor(c1, c2, v%1);
}

void keyPressed() {
  if (key == 's')
    saveImage();
  if (key == 'e')
    exit();
}

void saveImage() {
  String timestamp = year() + nf(month(), 2) + nf(day(), 2) + "-" + nf(hour(), 2) + nf(minute(), 2) + nf(second(), 2);
  println("Guardando imagen ... ");
  save("Capturas/" + timestamp + ".png");
  println("Imagen guardada exitosamente");
}

void exit() {
  println("Exiting");
  mindset.quit();
  serialPortArduino6.write('x');
  serialPortArduino6.stop();
  serialPortArduino9.write('x');
  serialPortArduino9.stop();
  serialPortArduino10.write('x');
  serialPortArduino10.stop();
  super.exit();
}

// mouse control for starting/stopping the sequencer
void mousePressed() {
  if (mouseButton == LEFT) {
    sequencer.start();
    println("sequencer is running");
  } else if (mouseButton == RIGHT) {
    sequencer.stop();
    println("sequencer has stopped");
  }
}

// We don't use these in the program, but they triggered an error when undefined
// sooo ...
public void poorSignalEvent(int sig) {
  // println(sig);
  signalWidget.add(200 - sig);
}

public void blinkEvent(int binkStrength) {
}

public void rawEvent(int rawEvents[]) {
}

// Here we get the MindSet's estimation of the user's attention level
public void attentionEvent(int attentionLevel) {

  // println("Attention: " + attentionLevel);
  // and convert it to a value between 0-127 for MIDI
  attVal = round(attentionLevel * 1.27);
  attentionWidget.add(attentionLevel);
}

// And here we get the MindSet's estimation of the user's meditation level
public void meditationEvent(int meditationLevel) {

  // println("Meditation: " + meditationLevel);
  // and convert it to a value between 0-127 for MIDI
  medVal = round(meditationLevel * 1.27);
  meditationWidget.add(meditationLevel);
}

// Here we get individual frequency levels from the MindSet
public void eegEvent(int delta, int theta, int low_alpha, int high_alpha, int low_beta, int high_beta, int low_gamma, 
  int mid_gamma) {
  // Valores en Bruto
  raw_delta = delta;
  raw_theta = theta;
  raw_alpha = (low_alpha + high_alpha) / 2;
  raw_beta = (low_beta + high_beta) / 2;
  raw_gamma = (low_gamma + mid_gamma) / 2;
  raw_high_alpha = high_alpha;
  raw_mid_gamma = mid_gamma;
  // Valores con los que se puede trabajar
  deltaVal = convertVal(delta, thetaFactor);
  highAlphaVal = convertVal(high_alpha, alphaFactor);
  midGammaVal = convertVal(mid_gamma, gammaFactor);
  thetaVal = convertVal(theta, thetaFactor);
  alphaVal = convertVal((low_alpha + high_alpha) / 2, alphaFactor);
  betaVal = convertVal((low_beta + high_beta) / 2, betaFactor);
  gammaVal = convertVal((low_gamma + mid_gamma) / 2, gammaFactor);
  // Añadiendo valores al widget
  deltaWidget.add(delta);
  thetaWidget.add(theta);
  lowAlphaWidget.add(low_alpha);
  highAlphaWidget.add(high_alpha);
  lowBetaWidget.add(low_beta);
  highBetaWidget.add(high_beta);
  lowGammaWidget.add(low_gamma);
  midGammaWidget.add(mid_gamma);
  resetPatterns();
}

// This function keeps a value from going negative and then scales it down using
// 'factor' value
int convertVal(float val, float factor) {

  if (val < 0.0) {
    val = 0.0;
  }
  int outVal = round(val / factor);
  return outVal;
}

public void creatingMusic(String note) {
  int cuantization = 0;
  int noteValue = 0;
  int pattMax = notePatt.length - 1;
  // send attention & meditation values as MIDI CC messages
  // Se usan los niveles de atención y relajación para cambiar el sonido general
  // del beat
  medController = new Controller(medCC, medVal);
  midiOut.sendController(medController);

  attController = new Controller(attCC, attVal);
  midiOut.sendController(attController);
  // pasoDeMensajes();
  // this could be much more elegant (& shorter), but it works //Se aisgna cada
  // onda a un instrumento de percusion
  // thetaVal -> G4
  // alphaVal -> B4
  // betaVal -> D5
  // gammaVal -> G5Flat
  // Cada nivel de frecuencia determina que patron de la lista se reproduce
  if (note.equals("g4")) {
    song.removeTrack(g4Track);
    g4Track = new Track(note, midiOut);
    g4Track.setQuantization(Q._1_8);
    cuantization = constrain(thetaVal, 0, pattMax);
    noteValue = G4;
    // println("C value (Theta): " + cuantization + "|" + "Theta: " + thetaVal + "|"
    // + raw_theta );
    for (int i = (notePatt[cuantization].length - 1); i >= 0; i--) {
      // The tick is the position of an event in a sequence, is the unit of time
      int tick = notePatt[cuantization][i];
      // Añade un nuevo evento. Note: nota, velocidad, duracion
      g4Track.addEvent(new Note(noteValue, 100, noteLength), tick);
    }
    song.addTrack(g4Track);
  } else if (note.equals("b4")) {
    song.removeTrack(b4Track);
    b4Track = new Track("b4", midiOut);
    b4Track.setQuantization(Q._1_8);
    cuantization = constrain(alphaVal, 0, pattMax);
    noteValue = B4;
    // println("C value (Alpha): " + cuantization + "|" + "Alpha " + alphaVal + "|"
    // + raw_alpha);
    for (int i = (notePatt[cuantization].length - 1); i >= 0; i--) {
      // The tick is the position of an event in a sequence, is the unit of time
      int tick = notePatt[cuantization][i];
      // Añade un nuevo evento. Note: nota, velocidad, duracion
      b4Track.addEvent(new Note(noteValue, 100, noteLength), tick);
    }
    song.addTrack(b4Track);
  } else if (note.equals("d5")) {
    song.removeTrack(d5Track);
    d5Track = new Track("d5", midiOut);
    d5Track.setQuantization(Q._1_8);
    cuantization = constrain(betaVal, 0, pattMax);
    noteValue = D5;
    // println("C value (Beta): " + cuantization + "|" + "Beta " + betaVal + "|" +
    // raw_beta);
    for (int i = (notePatt[cuantization].length - 1); i >= 0; i--) {
      // The tick is the position of an event in a sequence, is the unit of time
      int tick = notePatt[cuantization][i];
      // Añade un nuevo evento. Note: nota, velocidad, duracion
      d5Track.addEvent(new Note(noteValue, 100, noteLength), tick);
    }
    song.addTrack(d5Track);
  } else if (note.equals("g5Flat")) {
    song.removeTrack(g5FlatTrack);
    g5FlatTrack = new Track("g5Flat", midiOut);
    g5FlatTrack.setQuantization(Q._1_8);
    cuantization = constrain(gammaVal, 0, pattMax);
    noteValue = G5Flat;
    // println("C value (G5Flat): " + cuantization + "|" + "Gamma " + gammaVal + "|"
    // + raw_gamma);
    for (int i = (notePatt[cuantization].length - 1); i >= 0; i--) {
      // The tick is the position of an event in a sequence, is the unit of time
      int tick = notePatt[cuantization][i];
      // Añade un nuevo evento. Note: nota, velocidad, duracion
      g5FlatTrack.addEvent(new Note(noteValue, 100, noteLength), tick);
    }
    song.addTrack(g5FlatTrack);
  } else if (note.equals("g2")) {
    song.removeTrack(g2Track);
    g2Track = new Track("g2", midiOut);
    g2Track.setQuantization(Q._1_8);
    cuantization = constrain(deltaVal, 0, pattMax);
    noteValue = G2;
    // println("C value (Delta): " + cuantization + "|" + "Delta " + deltaVal + "|"
    // + raw_delta);
    for (int i = (notePatt[cuantization].length - 1); i >= 0; i--) {
      // The tick is the position of an event in a sequence, is the unit of time
      int tick = notePatt[cuantization][i];
      // Añade un nuevo evento. Note: nota, velocidad, duracion
      g2Track.addEvent(new Note(noteValue, 100, noteLength), tick);
    }
    song.addTrack(g2Track);
  } else if (note.equals("d3")) {
    song.removeTrack(d3Track);
    d3Track = new Track("d3", midiOut);
    d3Track.setQuantization(Q._1_8);
    cuantization = constrain(highAlphaVal, 0, pattMax);
    noteValue = D3;
    // println("C value (HighAplha): " + cuantization + "|" + "HighAplha " +
    // highAlphaVal + "|" + raw_high_alpha);
    for (int i = (notePatt[cuantization].length - 1); i >= 0; i--) {
      // The tick is the position of an event in a sequence, is the unit of time
      int tick = notePatt[cuantization][i];
      // Añade un nuevo evento. Note: nota, velocidad, duracion
      d3Track.addEvent(new Note(noteValue, 100, noteLength), tick);
    }
    song.addTrack(d3Track);
  } else if (note.equals("g3")) {
    song.removeTrack(g3Track);
    g3Track = new Track("g3", midiOut);
    g3Track.setQuantization(Q._1_8);
    cuantization = constrain(midGammaVal, 0, pattMax);
    noteValue = G3;
    // println("C value (MidGamma): " + cuantization + "|" + "MidGamma " +
    // midGammaVal + "|" + raw_mid_gamma);
    for (int i = (notePatt[cuantization].length - 1); i >= 0; i--) {
      // The tick is the position of an event in a sequence, is the unit of time
      int tick = notePatt[cuantization][i];
      // Añade un nuevo evento. Note: nota, velocidad, duracion
      g3Track.addEvent(new Note(noteValue, 100, noteLength), tick);
    }
    song.addTrack(g3Track);
  }
}

// This function uses the values we received from the MindSet to select a note
// pattern from our array
// ... and then it adds that pattern to the proMIDI library's built in sequencer
// (which is really cool!)
void resetPatterns() {
  creatingMusic("g4");
  creatingMusic("b4");
  creatingMusic("d5");
  creatingMusic("g5Flat");
  creatingMusic("g2");
  creatingMusic("d3");
  creatingMusic("g3");
  pasoDeMensajes();
}

// hey look - an array of pattern arrays (a multidimensional array) - COOL!
// These are the note locations/patterns we choose from for each percussion
// instrument
// (we put this @ the bottom just because it's really long & gets in the way)
// Patrones que funcionan como secuenciaas de notas.
// Cada numero determina la ocurrencia una nota dentro de una escala

int notePatt[][] = { 
  { 2 }, 
  { 3 }, 
  { 4 }, 
  { 5 }, 
  { 6 }, 
  { 7 }, 
  { 0, 2 }, 
  { 1, 3 }, 
  { 2, 5 }, 
  { 3, 5 }, 
  { 2, 7 }, 
  { 4, 5 }, 
  { 2, 4 }, 
  { 3, 4 }, 
  { 2, 5 }, 
  { 0, 4, 7 }, 
  { 1, 3, 7 }, 
  { 1, 5, 6 }, 
  { 1, 3, 7 }, 
  { 2, 4, 6 }, 
  { 2, 5, 7 }, 
  { 2, 2, 6 }, 
  { 5, 4, 7 }, 
  { 0, 2, 4, 6 }, 
  { 0, 2, 5, 6 }, 
  { 0, 1, 2, 6 }, 
  { 1, 2, 5, 6 }, 
  { 1, 2, 6, 6 }, 
  { 1, 4, 5, 7 }, 
  { 2, 2, 5, 7 }, 
  { 2, 3, 5, 7 }, 
  { 2, 3, 6, 7 }, 
  { 3, 4, 5, 7 }, 
  { 0, 6, 4, 1, 6 }, 
  { 0, 1, 2, 4, 6 }, 
  { 0, 2, 3, 4, 6 }, 
  { 1, 3, 4, 5, 6 }, 
  { 1, 3, 4, 5, 7 }, 
  { 2, 3, 4, 5, 6 }, 
  { 2, 3, 4, 5, 7 }, 
  { 3, 4, 5, 6, 7 }, 
  { 1, 2, 3, 4, 5, 6 }, 
  { 1, 2, 3, 4, 5, 7 }, 
  { 0, 2, 3, 4, 5, 7 }, 
  { 0, 1, 2, 3, 4, 5 }, 
  { 2, 3, 4, 5, 6, 7 }, 
  { 0, 3, 4, 5, 6, 7 }, 
  { 0, 1, 4, 5, 6, 7 }, 
  { 0, 1, 2, 3, 4, 5, 6 }, 
  { 0, 1, 2, 3, 4, 5, 6 }, 
  { 0, 1, 2, 4, 4, 5, 7 }, 
  { 0, 1, 2, 1, 4, 6, 7 }, 
  { 0, 1, 5, 3, 1, 6, 7 }, 
  { 0, 1, 2, 4, 4, 6, 7 }, 
  { 0, 1, 3, 4, 5, 6, 7 }, 
  { 0, 2, 3, 4, 5, 6, 7 }, 
  { 1, 2, 3, 3, 5, 6, 7 }, 
  { 1, 2, 3, 4, 5, 6, 7 }, 
  { 0, 1, 2, 3, 4, 5, 6, 7 }, // these were duplicated to fill out the list & drumfills in playback
  { 0, 2, 2, 3, 4, 5, 6, 7 }, 
  { 0, 1, 5, 3, 4, 5, 6, 7 }, 
  { 0, 1, 2, 3, 4, 5, 6, 7 }, 
  { 0, 1, 2, 3, 4, 5, 6, 7 }, 
  { 0, 1, 2, 3, 4, 5, 6, 7 }, 
  { 0, 1, 2, 3, 4, 5, 6, 7 }, 
  { 0, 1, 2, 3, 4, 5, 6, 7 }, 
  { 0, 1, 2, 3, 4, 5, 6, 7 }, 
  { 0, 1, 2, 3, 4, 5, 6, 7 }, 
};
