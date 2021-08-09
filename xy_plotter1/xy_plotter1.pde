import processing.serial.*;

Serial machine;
// machine Limits: 
float mTop=-2.;
float mBottom=-355.;
float mLeft=-298.;
float mRight=-70.;

boolean homed = false;

PVector prevPos;
PVector nextPos;
PVector mPos;
PVector mTarget;
PVector homePos = new PVector(mLeft, mTop);
float distanceToTarget = 0;
float feedSpeed = 10000.;
float maxFeedSpeed = 10000;
float maxDistance = (new PVector(mLeft, mTop)).dist(new PVector(mRight, mBottom));
boolean isMoving = false;
boolean initialized = false;

boolean penDown = false;

void setup () {
  fullScreen();
  frameRate(6  );
  //size(10, 10);
  cursor();
  fill(255);
  stroke(255);
  strokeWeight(3);

  machine =  new Serial(this, "/dev/cu.wchusbserial1420", 115200);
  prevPos = new PVector(width, 0);
  nextPos = new PVector(width, 0);
  mPos = new PVector(mLeft, mTop);
  mTarget = new PVector(mLeft, mTop);
  //home();
}

void getMachinePos() {
  machine.write("?");

  while (machine.available() > 0) {
    String inBuffer = machine.readString();   
    //println(inBuffer);
    if (inBuffer != null) {
      String[] parts = inBuffer.split("MPos:");
      //println(inBuffer);
      if (parts.length < 2) return;
      parts = parts[1].split(",");
      //println(parseFloat(parts[0]), parseFloat(parts[1]));

      if (parts.length < 2) return;
      mPos = new PVector(parseFloat(parts[0]), parseFloat(parts[1]));
      println("mPos", mPos);
      println("mTarget", mTarget);
      //println("homePos", homePos);

      distanceToTarget = mPos.dist(mTarget);

      //feedSpeed = maxFeedSpeed * (1.-exp(-distanceToTarget));

      println("distanceToTarget", distanceToTarget);

      isMoving = distanceToTarget > 1;
      if (!homed) {
        homed = homePos.dist(mPos) < 1;
      }
      if (!initialized) {
        homing();
        initialized = true;
      }
    }
  }
}

void draw() {
  getMachinePos();

  if (!homed) return;

  //if (!isMoving) {
  setTarget();
  goToTarget();
  //}
}

void setTarget() {
  if (!homed) return;
  nextPos = new PVector(mouseX, mouseY);

  if (prevPos == nextPos) return;

  noStroke();
  fill(0, 50);
  rect(0, 0, width, height);
  stroke(255);

  line(prevPos.x, prevPos.y, nextPos.x, nextPos.y);
  prevPos = nextPos.copy();
  float x = map(nextPos.y, 0, height, mLeft, mRight);
  float y = map(nextPos.x, 0, width, mBottom, mTop);
  mTarget = new PVector(x, y);
}

void mouseClicked() {
  //setTarget();

  if (!penDown) {
    machine.write("$1=255\n");
    machine.write("G0 z10\n");
    penDown = true;
  } else {
    machine.write("G0 z0\n");
    machine.write("$1=0\n");
    penDown = false;
  }
}

void mouseMoved() {
  //setTarget();
}

void goToTarget() {
  if (!homed) return;
  isMoving = true;
  machine.write("$J=G90 X"+str(mTarget.x) + " Y"+ str(mTarget.y)+ " F" + str(parseInt(feedSpeed)) +"\n");
}

void homing() {
  homed = false; // <-- important
  prevPos = new PVector(width, 0);
  nextPos = new PVector(width, 0);
  machine.write("$H\n");
  mTarget = homePos.copy();
  background(0);
}

void keyPressed() {
  if (key == 'h') {
    homing();
  }
  if (key == ' ') {
    if (!penDown) {
      machine.write("$1=255\n");
      machine.write("G0 z10\n");
      penDown = true;
    } else {
      machine.write("G0 z0\n");
      machine.write("$1=0\n");
      penDown = false;
    }
  } 
  if (!homed) return;

  if (keyCode == DOWN) {
    mTarget = mPos.copy().add(new PVector(10, 0));
    goToTarget();
    //machine.write("$J=G91 X10 F1000\n");
  }
  if (keyCode == UP) { // 
    mTarget = mPos.copy().add(new PVector(-10, 0));
    goToTarget();
    //machine.write("$J=G91 X-10 F1000\n");
  }
  if (keyCode == LEFT) { 
    mTarget = mPos.copy().add(new PVector(0, -10));
    goToTarget();
    //machine.write("$J=G91 Y-10 F1000\n");
  }
  if (keyCode == RIGHT) { 
    mTarget = mPos.copy().add(new PVector(0, 10));
    goToTarget();
    //machine.write("$J=G91 Y10 F1000\n");
  }
}
