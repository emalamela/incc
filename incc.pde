import java.util.Collections;
import java.io.*;
PrintStream output;
PrintWriter numOutput;

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
  boolean startedTrials;
  int points;

  Experiment(Rule rule, Complexity complexity, boolean isTimeBounded, Trial[] trials) {
    this.rule = rule;
    this.complexity = complexity;
    this.isTimeBounded = isTimeBounded;
    this.trials = trials;
    this.currentTrialIndex = 0;
    this.startedTrials = false;
    this.points = 0;
  }

  void advanceToNextTrial(boolean correct) {
    if (finishedAllTrials()) {
      throw new IllegalStateException("Already finised trials for experiment " + toString());
    }
    
    points += correct ? 1 : 0;
    currentTrialIndex++;
  }

  Trial getCurrentTrial() {
    if (finishedAllTrials()) {
      throw new IllegalStateException("Already finised trials for experiment " + toString());
    }
    
    if (!startedTrials) {
      throw new IllegalStateException("Haven't started trials for experiment " + toString());
    }
    
    return trials[currentTrialIndex];
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
    
    startedTrials = true;
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
 //<>//
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

String[] generateGeneralInstructions() {
  String greetingInstruction = "Hola!\n" +
                               "Bienvenido al Experimento.\n\n\n" + 
                               "Para avanzar tocá la tecla ENTER.";
  String exercisesInstruction = "A continuación se le presenteran una serie de 2 ejercicios.\n" + 
                                "Te pedimos que leas atentamente las instrucciones antes de comenzar con cada uno de ellos.\n\n\n"+
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
    output.println("\n" + currentExperiment.getCurrentTrial().toString());
    println("Succesfully written data.");
    //output.flush();
  } catch(Exception e){
    println("There was an error while writing to the data file");
  }
  
  currentExperiment.advanceToNextTrial(answeredCorrectly);

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

  if (keyCode == ENTER) {
    exit();
  }
}

/* Logic */

boolean hasUserAcceptedTerms = false;
boolean hasFinishedExperiments = false;
boolean interScreen = false;
boolean correct = false;
int currentGeneralInstructionIndex = 0;
int currentExperimentIndex = 0;
long timer = 0L;
long millisPerBoundedExperiment = 2000; 
String[] generalInstructions;
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
  generalInstructions = generateGeneralInstructions();

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
    text("INCORRECTO :(", width/2, height/2);
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
  if (hasFinishedExperiments || interScreen) return;

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
  
  if (keyCode == ENTER) {
    if (!currentExperiment.startedTrials) {
      currentExperiment.startTrials();
    }
  }
  
  if (keyCode == LEFT || keyCode == RIGHT) {
    Classification userClassification = keyCode == LEFT ? Classification.CLASS_A : Classification.CLASS_B;
    
    Trial currentTrial = currentExperiment.getCurrentTrial();
    correct = currentTrial.classification == userClassification;
    currentTrial.classified = true;
    currentTrial.correct = correct;
    currentTrial.time = millis() - timer;
    println(correct ? "correct!" : "wrong!");
    
    interScreen = true;
    timer = millis();
    updateExperiment(correct);
  }
}
