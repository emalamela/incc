import java.util.Collections;
import java.io.*;
import processing.sound.*;

PrintStream output;
//PrintWriter numOutput;

SoundFile right;
SoundFile wrong;

/* Declarations */

int expLength = 16;

ArrayList<Trial> tutorialTrials;

enum Rule {
  B_35, ASHBY
}

enum Complexity {
  SIMPLE, COMPLEX
}

enum Classification {
  CLASS_A, CLASS_B
}

class Trial {
  int id;
  PImage img;
  Rule rule;
  Complexity complexity;
  Classification classification;
  boolean classified;
  boolean correct;
  float time;

  Trial(int id, PImage img, Rule rule, Complexity complexity, Classification classification) {
    this.id = id;
    this.img = img;
    this.rule = rule;
    this.complexity = complexity;
    this.classification = classification;
    this.classified = false;
    this.correct = false;
    this.time = 0f;
    
    
    float scale = height/img.height;
    scale *= 0.8;
    img.resize((int)(scale*img.width), (int)(scale*img.height));
  }
  
  void render() {
    background(255);
    image(img, width/2 - img.width/2, height/2 - img.height/2);
  }
  
  @Override
  public String toString(){
    return id + "\t" + rule + "\t" + complexity + "\t" + classification + "\t" + classified + "\t" + correct + "\t" + time;
  }
}

class ConfidenceBar {
  float y;
  
  float bar_x;
  float bar_width;
  float bar_height;
  
  float circle_x;
  float circle_r;
  
  float confidence;
  
  boolean move;
  
  ConfidenceBar(){
    y = height/2;
    
    bar_x = width/2;
    circle_x = width/2;
    
    bar_width = width*0.6;
    bar_height = 20;
    
    circle_r = 20;
    
    move = false;
    
    confidence = 0;
  }
  
  void update(){
    if(mousePressed){
      if(mouseX - circle_x < circle_r && mouseY - y < circle_r){
        move = true;
      }
    } else{
      move = false;
    }
    
    if(move){
      moveCircle(mouseX - pmouseX);
    }
  }
  
  void render(){
    background(150);
    
    strokeWeight(2);
    
    stroke(0);
    fill(100, 100, 255);
    rect(bar_x - bar_width/2, y - bar_height/2, bar_width, bar_height);
    
    stroke(0, 0, 100);
    fill(0, 0, 200);
    ellipse(circle_x, y, circle_r*2, circle_r*2);
    
    //textMode(CENTER);
    textAlign(CENTER, CENTER);
    textSize(24);
    fill(0);
    text("Marcá en la barra cuán seguro\nestás de tus últimas decisiones", width/2, 100);
    text("Apretá enter cuando estés\nconforme con tu respuesta", width/2, height - 100);
    
    textSize(16);
    text("Nada\nseguro", bar_x - bar_width/2 - 40, y);
    text("Totalmente\nseguro", bar_x + bar_width/2 + 50, y);
  }
  
  void moveCircle(float amount){
    circle_x = circle_x + amount;
    if(circle_x > bar_x + bar_width/2){
      circle_x = bar_x + bar_width/2;
      move = false;
    } else if(circle_x < bar_x - bar_width/2){
      circle_x = bar_x - bar_width/2;
      move = false;
    }
  }
  
  float getConfidence(){
    return confidence;
    
  }
  
  void setConfidence(){
    float offset = bar_x - bar_width/2;
    confidence = (circle_x - offset)/bar_width;
  }
}



class Experiment {
  final Rule rule;
  final Complexity complexity;
  final boolean isTimeBounded;
  final Trial[] trials;
  int currentTrialIndex;
  boolean startedTrials;
  int points;
  final ConfidenceBar[] confidenceBars;
  int currentBar;
  
  boolean isTutorial;
  
  Experiment(Rule rule, Complexity complexity, boolean isTimeBounded, Trial[] trials) {
    this.rule = rule;
    this.complexity = complexity;
    this.isTimeBounded = isTimeBounded;
    this.trials = trials;
    this.currentTrialIndex = 0;
    this.startedTrials = false;
    this.points = 0;
    this.confidenceBars = generateBars();
    currentBar = 0;
    isTutorial = false;
  }
  
  Experiment(){
    this.rule = null;
    this.complexity = null;
    this.isTimeBounded = false;
    
    this.trials = new Trial[tutorialTrials.size()];
    for(int i = 0; i < tutorialTrials.size(); i++){
      trials[i] = tutorialTrials.get(i);
    }
    
    this.currentTrialIndex = 0;
    this.startedTrials = false;
    this.points = 0;
    this.confidenceBars = generateBars();
    currentBar = 0;
    
    this.isTutorial = true;
  }

  ConfidenceBar[] generateBars(){
    ConfidenceBar[] confidenceBars = new ConfidenceBar[4];
    
    for (int i = 0; i < 4; i++) {
      confidenceBars[i] = new ConfidenceBar();
    }

    return confidenceBars;
  }
  
  ConfidenceBar getCurrentBar() {
    return confidenceBars[currentBar];
  }
  
  void advanceToNextTrial(boolean correct) {
    if (finishedAllTrials()) {
      throw new IllegalStateException("Already finised trials for experiment " + toString());
    }
    
    points += correct ? 1 : 0;
    
    if (finishedAllTrials()) {
      throw new IllegalStateException("Already finised trials for experiment " + toString());
    }
    println("Trial " + currentExperiment().currentTrialIndex + " % " + expLength/4 +" = " + currentExperiment().currentTrialIndex % (expLength/4));
    currentTrialIndex++;
  }

  Trial getCurrentTrial() {
    if (finishedAllTrials()) {
      printStackTrace(new IllegalStateException("Already finised trials for experiment " + toString()));
    }
    
    if (!startedTrials) {
      printStackTrace(new IllegalStateException("Haven't started trials for experiment " + toString()));
    }
    
    return trials[currentTrialIndex];
  }
  
  String data() {
    int bar = 0;
    if(currentBar > 0){
      bar = currentBar - 1;
    }
    
    return getCurrentTrial().toString() + "\t" + confidenceBars[bar].getConfidence();
  }

  boolean finishedAllTrials() {
    return currentTrialIndex >= trials.length;
  }
  
  String getInstructions() {
    if (startedTrials) {
      throw new IllegalStateException("Already shown instructions for experiment " + toString());
    }
    
    String instructions = 
        "Te vamos a mostrar un set de imágenes\n" + 
        "que vas a tener que categorizar en 1 de 2 categorías:\n" + 
        "Categoría A o Categoría B.\n" + 
        "Para elegir la categoría A tenés que tocar la FLECHA IZQUIERDA y\n" + 
        "Para la categoría B tenés que tocar la FLECHA DERECHA\n" + 
        "Luego de cada respuesta te indicaremos si es CORRECTA o INCORRECTA.\n\n";
        
    if (isTimeBounded) {
      instructions += 
          "Vas a tener solo " + millisPerBoundedExperiment / 1000 + " SEGUNDOS por imagen para responder!\n\n";
    } else {
      instructions += 
          "Tenés tiempo ilimitado para responder!\n\n";
    }
    
    instructions +=
        "Leé bien las instrucciones y después tocá ENTER para comenzar!";
    
    return instructions;
  }
  
  void startTrials() {
    if (startedTrials) {
      throw new IllegalStateException("Trials already started");
    }
    timer = millis();
    startedTrials = true;
  }

  @Override
  public String toString() {
    if(isTutorial){
      return "Tutorial Experiment.";
    }
    
    return "Experiment(rule=" + rule.toString() + 
      ", complexity=" + complexity.toString() + 
      ", isTimeBounded=" + String.valueOf(isTimeBounded) + 
      ", trials=Trial[" + String.valueOf(trials.length) + "]" +
      ", currentTrialIndex = " + String.valueOf(currentTrialIndex) + 
      ")";
  }
}

String[] listFileNames(String dir) {
  File file = new File(dir);
 //<>// //<>//
  if (file.isDirectory()) {
    String names[] = file.list();
    return names;
  } else {
    // If it's not a directory
    return null;
  }
}

ArrayList<Trial> generateAllTrials() { // el nombre del archivo debe tener el formato "problem1_simple_1_classA.png"
  String[] imgList = listFileNames(sketchPath() + "/data");
  ArrayList<Trial> allTrials = new ArrayList<Trial>();
  int i = 0;
  for (String name : imgList) {
    //println(name);
    if (!name.contains("png") || name.contains("tutorial")) continue;
    name = name.substring(0, name.lastIndexOf("."));
    //println(name);

    String[] parts = name.split("_");
    //for (String part : parts) println(part);
    String imgRule = parts[0];
    String imgComplexity = parts[1];
    String imgClass = parts[2];
    //String imgNum = parts[3];
    PImage img = loadImage(name + ".png");

    allTrials.add(new Trial(i,
      img,
      imgRule.equals("problem1") ? Rule.B_35 : Rule.ASHBY, 
      imgComplexity.equals("simple") ? Complexity.SIMPLE : Complexity.COMPLEX, 
      imgClass.equals("classA") ? Classification.CLASS_A : Classification.CLASS_B)
    );
    i++;
  }
  Collections.shuffle(allTrials);
  return allTrials;
}


ArrayList<Trial> generateTutorialTrials(){ //completar este método
  String[] imgList = listFileNames(sketchPath() + "/data");
  ArrayList<Trial> tutorialTrials = new ArrayList<Trial>();
  int i = 0;
  for (String name : imgList) {
    //println(name);
    if (!name.contains("png") || !name.contains("tutorial")) continue;
    name = name.substring(0, name.lastIndexOf("."));
    //println(name);

    String[] parts = name.split("_");
    //for (String part : parts) println(part);
    String imgClass = parts[1];
    //String imgNum = parts[3];
    println("loading image for file " + name);
    PImage img = loadImage(name + ".png");

    tutorialTrials.add(new Trial(i,
      img,
      null, 
      null, 
      imgClass.equals("classA") ? Classification.CLASS_A : Classification.CLASS_B));
    i++;
  }
  Collections.shuffle(tutorialTrials); 

  return tutorialTrials;
}

Trial[] generateTrials(Rule rule, Complexity complexity, int numTrials) {
  Trial[] trials = new Trial[numTrials];

  int i = 0; //<>// //<>//
  for (Trial trial : allTrials) {
    if (i >= numTrials) break;
    if (trial.complexity == complexity && trial.rule == rule) {
      trials[i] = trial;
      i++;
    }
  }

  return trials;
}

Experiment generateTutorialExperiment() {
  return new Experiment();
}

Experiment generateRandomExperiment() {
  Rule randomRule = Rule.values()[int(random(Rule.values().length))];
  Complexity randomComplexity = Complexity.values()[int(random(Complexity.values().length))];
  boolean isTimeBounded = random(1) > 0.5f;

  return new Experiment(randomRule, randomComplexity, isTimeBounded, generateTrials(randomRule, randomComplexity, expLength));
}

Experiment generateComplimentaryExperiment(Experiment otherExperiment) {
  Rule complimentaryRule = otherExperiment.rule == Rule.B_35 ? Rule.ASHBY : Rule.B_35;
  Complexity complimentaryComplexity = otherExperiment.complexity == Complexity.SIMPLE ? Complexity.COMPLEX : Complexity.SIMPLE;
  boolean isTimeBounded = !otherExperiment.isTimeBounded;

  return new Experiment(complimentaryRule, complimentaryComplexity, isTimeBounded, generateTrials(complimentaryRule, complimentaryComplexity, expLength));
}

Experiment[] generateExperimentSet() {
  Experiment tutorial = generateTutorialExperiment();
  Experiment firstExperiment = generateRandomExperiment();
  Experiment secondExperiment = generateComplimentaryExperiment(firstExperiment);

  return new Experiment[]{tutorial, firstExperiment, secondExperiment};
}

String[] generateGeneralInstructions() {
  String greetingInstruction = "Hola!\n" +
                               "Bienvenido al Experimento.\n\n\n" + 
                               "Para avanzar tocá la tecla ENTER.";
  String exercisesInstruction = "A continuación se le presenteran una serie de 2 ejercicios.\n" + 
                                "Te pedimos que leas atentamente las instrucciones\nantes de comenzar con cada uno de ellos.\n\n\n"+
                                "Para avanzar tocá la tecla ENTER.";
  return new String[]{greetingInstruction, exercisesInstruction};
}

Experiment currentExperiment() {
  if (currentExperimentIndex < 0 || currentExperimentIndex > experiments.length) {
    throw new IndexOutOfBoundsException("currentExperimentIndex is out of bounds!");
  }
  
  return experiments[currentExperimentIndex];
}

String currentGeneralInstruction() {
  if (currentGeneralInstructionIndex < 0 || currentGeneralInstructionIndex > generalInstructions.length) {
    throw new IndexOutOfBoundsException("currentGeneralInstructionIndex is out of bounds!");
  }
  
  return generalInstructions[currentGeneralInstructionIndex];
}

void drawTerms() {
  fill(255, 255, 255);
  background(100);
  textAlign(CENTER, CENTER);
  textSize(24);
  text(currentGeneralInstruction(), width/2, height/2);
}

void updateExperiment(boolean answeredCorrectly) {
  Experiment currentExperiment = currentExperiment();
  
  try{
    output.println("\n" + currentExperiment.data());
    //println("Succesfully written data.");
    //output.flush();
  } catch(Exception e){
    println("There was an error while writing to the data file");
  }
  
  if (currentExperiment.currentTrialIndex % (expLength/4) == expLength/4 - 1){
    showConfidenceBar = true;
  }
  
  if(answeredCorrectly){
    correctInARow++;
  } else {
    correctInARow = 0;
  }
  
  currentExperiment.advanceToNextTrial(answeredCorrectly);
  
  checkIfFinished();

}

void checkIfFinished(){
  
  if ((currentExperiment().finishedAllTrials() || correctInARow >= 8) && !showConfidenceBar) {
    println("changing experiment index");
    currentExperimentIndex++;
    correctInARow = 0;
    println("Moving to Experiment number " + String.valueOf(currentExperimentIndex));

    if (currentExperimentIndex >= experiments.length) {
      println("Finishing experiments");
      hasFinishedExperiments = true;
      try{
        //output.flush();
        //println("Succesfully closed data file.");
      }catch(Exception e){
        println("There was an error closing the data file.");
      }
    }
    
    
  }
}

void drawExperiment() {
  if (hasFinishedExperiments) return; 

  Experiment currentExperiment = currentExperiment();
  
  if (!currentExperiment.startedTrials) {
    fill(255, 255, 255);
    background(100);
    textAlign(CENTER, CENTER);
    textSize(24);
    String instructionsTitle = "EJERCICIO " + (currentExperimentIndex + 1) + "\n\n";
    text(instructionsTitle + currentExperiment.getInstructions(), width/2, height/2);
    return;
  }
  
  currentExperiment.getCurrentTrial().render();

  if (currentExperiment.isTimeBounded) {
    if (timer == 0L) {
      // Haven't initialized timer 
      timer = millis();
    }

    if (millis() - timer >= millisPerBoundedExperiment) {
      updateExperiment(false);
      timer = millis();
    } else {
      fill(0, 0, 200);
      noStroke();
      float w = map(millis() - timer, 0, 2000, width, 0);
      rect(0, 0, w, 25);
    }
  }
}

void drawFinishedExperiments() {
  background(100);
  fill(0, 0, 0);
  textAlign(CENTER, CENTER);
  textSize(24);
  int totalPoints = 0;
  for (Experiment experiment : experiments) totalPoints += experiment.points;
  
  text("¡Gracias por completar los experimentos!\nTu puntaje fue de " + totalPoints + "\nTocá la tecla ENTER para salir.", width/2, height/2);
}

/* Logic */

boolean hasUserAcceptedTerms = false;
boolean hasFinishedExperiments = false;
boolean interScreen = false;
boolean correct = false;
int currentGeneralInstructionIndex = 0;
boolean showConfidenceBar = false;
int currentExperimentIndex = 0;
long timer = 0L;
long millisPerBoundedExperiment = 2000; 
String[] generalInstructions;
Experiment[] experiments;
ArrayList<Trial> allTrials;
//int expNumber;


boolean lastRight = false;
int correctInARow = 0;

void setup() {
  //fullScreen();
  size(600, 600);
  
  background(100);
  frameRate(30);
  
  println("Starting to load files.");
  
  /*String[] lines = loadStrings("numExp.txt");
  expNumber = Integer.parseInt(lines[0]);
  numOutput = createWriter("numExp.txt");
  numOutput.println((expNumber+1)+"");
  numOutput.flush();
  numOutput.close();*/
  
  try{
    output = new PrintStream(new FileOutputStream(new File(sketchPath() + "/data.txt"), true));
    String[] lines2 = loadStrings("data.txt");
    println("Succesfully loaded data file.");
    if(lines2.length==0){
      output.println("img\trule\tcmplx\tclass\tdone\tcorrect\tt(ms)\tconf");
      //output.flush();
      println("Succesfully written head data.");
    } else {
      output.println("##\t##\t##\t##\t##\t##\t##\t##");
    }
  } catch(Exception e){
    println("There was an error opening the data file.");
  }
  
  println("Generating tutorial trials");
  tutorialTrials = generateTutorialTrials();
  println("Generated tutorial trials");
  
  allTrials = generateAllTrials();
  experiments = generateExperimentSet();
  generalInstructions = generateGeneralInstructions();

  println("Experiment #1 is " + experiments[0].toString());
  println("Experiment #2 is " + experiments[1].toString());
  
  right = new SoundFile(this, "data/correct.wav");
  wrong = new SoundFile(this, "data/wrong.wav");
  
  frame.requestFocus();
}

void drawInterScreen() {
  fill(0, 0, 0);
  textAlign(CENTER);
  textSize(40);
  
  if (correct) {
    background(0, 200, 0);
    text("¡CORRECTO! +1", width/2, height/2);
  } else {
    background(200, 0, 0);
    text("INCORRECTO :(", width/2, height/2);
  }

  if (timer == 0L) {
    // Haven't initialized timer 
    timer = millis();
  }

  if (millis() - timer >= 2000) {
    interScreen = false;
    timer = millis();
  }
}

void draw() {
  if (!hasUserAcceptedTerms) {
    drawTerms();
  } else if (interScreen) {
    drawInterScreen();
  } else if (hasFinishedExperiments) {
    drawFinishedExperiments();
  } else if (showConfidenceBar) {
    currentExperiment().getCurrentBar().update();
    currentExperiment().getCurrentBar().render();
  } else {
    drawExperiment();
  }
}

void finish(){
    output.println("##\t##\t##\t##\t##\t##\t##\t##");
    output.close();
    exit();
}

void keyReleased() {
  if(keyCode == ESC){
    finish();
  }
  
  if (interScreen) return;

  if (hasFinishedExperiments) {
    if (keyCode == ENTER) {
      finish();
    }
    return;
  }

  if (!hasUserAcceptedTerms) {
    handleGeneralInstructionKeyReleased();
  } else {
    handleExperimentKeyReleased();
  }
}

void handleGeneralInstructionKeyReleased() {
  if (keyCode == ENTER) {
    currentGeneralInstructionIndex++;
    
    hasUserAcceptedTerms = currentGeneralInstructionIndex >= generalInstructions.length;
  }
}

void handleExperimentKeyReleased() {
  Experiment currentExperiment = currentExperiment();
  
  if (!currentExperiment.startedTrials) {
    if (keyCode == ENTER) {
      currentExperiment.startTrials();
    }
    return;
  }

  if (showConfidenceBar) {
    if (keyCode == ENTER) {
      currentExperiment.getCurrentBar().setConfidence();
      currentExperiment.currentBar++;
      showConfidenceBar = false;
      checkIfFinished();
      timer = millis();
    }
    return;
  }
  
  if (keyCode == LEFT || keyCode == RIGHT) {
    Classification userClassification = keyCode == LEFT ? Classification.CLASS_A : Classification.CLASS_B;
    
    Trial currentTrial = currentExperiment.getCurrentTrial();
    correct = currentTrial.classification == userClassification;
    currentTrial.classified = true;
    currentTrial.correct = correct;
    currentTrial.time = millis() - timer;
    //println(correct ? "correct!" : "wrong!");
    
    if(correct){
      right.play();
    } else {
      wrong.play();
    }
    
    interScreen = true;
    timer = millis();
    updateExperiment(correct);
    return;
  }
}