float rel_tr_height = sqrt(3)/2;
int counter;
int problem = 0;
String classif = "NOTVALID";

void setup() {
  //fullScreen();
  size(600,600);
  
  background(200);
  //frameRate(30);
  counter = 0;
}

void draw(){
  
}

String makeTutorial(boolean circle){
  String result = "tutorial";
  
  background(255);
  stroke(0);
  strokeWeight(4);
  noFill();
  
  float half = random(width*0.15, width*0.3);
  float x = random(half + 10, width-half-10);
  float y = random(half + 10, height-half-10);
  
  if(circle){
    ellipse(x, y, half*2, half*2);
    result += "_classA";
  } else {
    rect(x-half, y-half, half*2, half*2);
    result += "_classB";
  }
  
  return result;
}

// genero imágenes de bongard #35
String makeProblemOne(boolean complex, boolean parallel, boolean high){
  String result = "problem1";
  
  boolean isRect = random(1) > 0.5;
  
  float angle = random(2*PI);
  
  float w = random(70, 150);
  float h = random(200, 350);
  
  float x = random(h, width - h);
  float y = random(h, height - h);
  
  println(angle);
  
  fill(0);
  noStroke();
  background(255);
  
  // dibujo la figura externa
  
  pushMatrix();
  translate(x, y);
  rotate(angle);
  if(isRect){
    rect(0 - w/2, 0 - h/2, w, h);
  } else {
    ellipse(0, 0, w, h);
  }
  popMatrix();
  
  //dibujo la figura interna
  
  isRect = random(1) > 0.5;
  
  float fillColor = random(50, 250);
  float angleChange = 0;
  
  float oo = 0; // hay que variarlo
  
  fill(fillColor);
  
  if(complex){
    result = result + "_complex";
    if(high){
      result = result + "_classB";
      oo+=PI/4;
    } else {
      result = result + "_classA";
    }
    angleChange = oo + map(fillColor, 50, 250, 0, PI/4);
  } else {
    result = result + "_simple";
    if(!parallel){
      result = result + "_classB";
      angleChange = PI/2;
    } else {
      result = result + "_classA";
    }
  }
  
  pushMatrix();
  translate(x, y);
  
  //acá chequeo la condición que determina 
  //si esta imagen es de una clase u otra
  if(parallel){
    rotate(angle);
  } else{
    rotate(angle + angleChange);
  }
  
  float scaling = (w/h) * random(0.3, 0.7);
  w *= scaling;
  h *= scaling;
  
  if(isRect){
    rect(0 - w/2, 0 - h/2, w, h);
  } else {
    ellipse(0, 0, w, h);
  }
  popMatrix();
  
  return result;
}

String makeProblemTwo(boolean complex, boolean high, boolean highDensity){
  String result = "problem2";
  
  float w = 100 + random(100, 400);
  float h = w/2;
  
  float x = width/2;
  float y = height/2;
  
  float oo = 0; // hay que variarlo
  
  float density = 0.02;
  
  if(complex){
    result = result + "_complex";
    println("COMPLEX");
    if(high){
      result = result + "_classB";
      oo+=0.005;
      println("B");
    } else {
      result = result + "_classA";
      println("A");
    }
    density = oo + map(w, 200, 500, 0, 0.02);
  } else {
    result = result + "_simple";
    if(highDensity){
      result = result + "_classB";
      density = 0.01;
    } else {
      result = result + "_classA";
      density = 0.02;
    }
  }
  
  float numPoints = density * w * h;
  
  
  fill(0);
  noStroke();
  background(255);
  
  // dibujo la figura externa
  
  
  rect(x - w/2, y - h/2, w, h);
  stroke(0, 255, 0);
  for(int i = 0; i < numPoints; i++){
    point(random(x - w/2 + 2, x + w/2 - 2), random(y - h/2 + 2, y + h/2 - 2));
  }
  
  //dibujo la figura interna
  
  
  return result;
}


void mouseClicked(){
  save(classif + "_" + counter + ".png");
  counter++;
  
  generate();
  
}

void keyPressed(){
  if (keyCode != RIGHT){
    return;
  }
  
  generate();
}

void generate(){
  if(problem == 1){
    classif = makeProblemOne(false,random(1)>0.5,random(1)>0.5);
  } else if (problem == 2){
    classif = makeProblemTwo(false, random(1)>0.5, random(1)>0.5);
  } else if (problem == 0){
    classif = makeTutorial(random(1)>0.5);
  }
}