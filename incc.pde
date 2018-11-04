import java.util.Collections;
import java.io.*;
PrintStream output;
PrintWriter numOutput;
int puntos = 0;

/* Declarations */

int expLength = 4;

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
  }

  void render() {
    image(img, 0, 0);
  }
  
  @Override
  public String toString(){
    return expNumber + "\t" + id + "\t" + rule + "\t" + complexity + "\t" + classification + "\t" + classified + "\t" + correct + "\t" + time;
  }
}

class Experiment {
  final Rule rule;
  final Complexity complexity;
  final boolean isTimeBounded;
  final Trial[] trials;
  int currentTrialIndex;

  Experiment(Rule rule, Complexity complexity, boolean isTimeBounded, Trial[] trials) {
    this.rule = rule;
    this.complexity = complexity;
    this.isTimeBounded = isTimeBounded;
    this.trials = trials;
    this.currentTrialIndex = 0;
  }

  void advanceToNextTrial() {
    if (finishedAllTrials()) {
      throw new IllegalStateException("Already finised trials for experiment " + toString());
    }

    currentTrialIndex++;
  }

  Trial getCurrentTrial() {
    if (finishedAllTrials()) {
      throw new IllegalStateException("Already finised trials for experiment " + toString());
    }

    return trials[currentTrialIndex];
  }

  boolean finishedAllTrials() {
    return currentTrialIndex >= trials.length;
  }

  @Override
    public String toString() {
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
    if (!name.contains("png")) continue;
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

Trial[] generateTrials(Rule rule, Complexity complexity, int numTrials) {
  Trial[] trials = new Trial[numTrials];

  int i = 0; //<>//
  for (Trial trial : allTrials) {
    if (i >= numTrials) break;
    if (trial.complexity == complexity && trial.rule == rule) {
      trials[i] = trial;
      i++;
    }
  }

  return trials;
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
  Experiment firstExperiment = generateRandomExperiment();
  Experiment secondExperiment = generateComplimentaryExperiment(firstExperiment);

  return new Experiment[]{firstExperiment, secondExperiment};
}

Experiment currentExperiment() {
  return experiments[currentExperimentIndex];
}

void drawTerms() {
  background(100);
  textAlign(CENTER);
  textSize(24);
  text("¡Tocá la tecla ENTER para comenzar!", width/2, height/2);

  if (keyCode == ENTER) {
    hasUserAcceptedTerms = true;
  }
}

void updateExperiment() {
  Experiment currentExperiment = currentExperiment();
  
  try{
    output.println("\n" + currentExperiment.getCurrentTrial().toString());
    println("Succesfully written data.");
    //output.flush();
  } catch(Exception e){
    println("There was an error while writing to the data file");
  }
  
  currentExperiment.advanceToNextTrial();

  if (currentExperiment.finishedAllTrials()) {
    currentExperimentIndex++;
    println("Moving to Experiment number " + String.valueOf(currentExperimentIndex));

    if (currentExperimentIndex >= experiments.length) {
      println("Finishing experiments");
      hasFinishedExperiments = true;
      try{
        //output.flush();
        output.close();
        println("Succesfully closed data file.");
      }catch(Exception e){
        println("There was an error closing the data file.");
      }
    }
  }
}

void drawExperiment() {
  if (hasFinishedExperiments) return;

  Experiment currentExperiment = currentExperiment();
  currentExperiment.getCurrentTrial().render();

  if (currentExperiment.isTimeBounded) {
    if (timer == 0L) {
      // Haven't initialized timer 
      timer = millis();
    }

    if (millis() - timer >= 2000) {
      updateExperiment();
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
  text("¡Gracias por completar los experimentos!\nTu puntaje fue de " + puntos + "\nTocá la tecla ENTER para salir.", width/2, height/2);

  if (keyCode == ENTER) {
    exit();
  }
}

/* Logic */

boolean hasUserAcceptedTerms = false;
boolean hasFinishedExperiments = false;
boolean interScreen = false;
boolean correct = false;
int currentExperimentIndex = 0;
long timer = 0L;
Experiment[] experiments;
ArrayList<Trial> allTrials;
int expNumber;

void setup() {
  //fullScreen();
  size(600, 600);
  
  background(100);
  frameRate(30);
  
  println("Starting to load files.");
  
  String[] lines = loadStrings("numExp.txt");
  expNumber = Integer.parseInt(lines[0]);
  numOutput = createWriter("numExp.txt");
  numOutput.println((expNumber+1)+"");
  numOutput.flush();
  numOutput.close();
  
  try{
    output = new PrintStream(new FileOutputStream(new File(sketchPath() + "/data.txt"), true));
    String[] lines2 = loadStrings("data.txt");
    println("Succesfully loaded data file.");
    if(lines2.length==0){
      output.println("n\tid\trule\tcmplx\tclass\tdone\tcorrect\ttime(ms)");
      //output.flush();
      println("Succesfully written head data.");
  }
  } catch(Exception e){
    println("There was an error opening the data file.");
  }
  
  
  allTrials = generateAllTrials();
  experiments = generateExperimentSet();

  println("Experiment #1 is " + experiments[0].toString());
  println("Experiment #2 is " + experiments[1].toString());
  
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
    text("ERROR :(", width/2, height/2);
  }

  if (timer == 0L) {
    // Haven't initialized timer 
    timer = millis();
  }

  if (millis() - timer >= 1000) {
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
  } else {
    drawExperiment();
  }
}

void keyReleased() {
  if (!hasUserAcceptedTerms || hasFinishedExperiments || interScreen) return;

  if (keyCode == LEFT || keyCode == RIGHT) {
    Classification userClassification = keyCode == LEFT ? Classification.CLASS_A : Classification.CLASS_B;
    
    correct = currentExperiment().getCurrentTrial().classification == userClassification;
    currentExperiment().getCurrentTrial().classified = true;
    currentExperiment().getCurrentTrial().correct = correct;
    currentExperiment().getCurrentTrial().time = millis() - timer;
    println(correct ? "correct!" : "wrong!");
    
    if(correct){
      puntos++;
    }
    
    interScreen = true;
    timer = millis();
    updateExperiment();
  }
}
