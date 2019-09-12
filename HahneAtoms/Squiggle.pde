class Squiggle {
  float scale, size, xPos, yPos;
  String sCol;
  float len = 30;
  int vNum = 7;
  float beta;
  float betaScale = 0.2;
  float maxBeta = 2;
  float amp;
  float ampScale = 0.15;
  boolean monochrome = true;

  float tick=0;
  float dt = 0.2;

  int sColAvgLen = 2;

  ArrayList<Integer> cList = new ArrayList<Integer>(sColAvgLen);

  void updateAvg(color c) {
    cList.remove(0);
    cList.add(c);
  }

  color getAvg() {
    int h = 0;
    int s = 0;
    int b = 0;
    for (int i = 0; i < cList.size(); i++) {
      h += hue(cList.get(i));
    }

    for (int i = 0; i < cList.size(); i++) {
      s += saturation(cList.get(i));
    }

    for (int i = 0; i < cList.size(); i++) {
      b += brightness(cList.get(i));
    }

    h /= cList.size();
    s /= cList.size();
    b /= cList.size();

    return color(h, s, b);
  }

  Squiggle(float x, float y, String c) {

    size = 0;
    xPos = x;
    yPos = y;
 
    if (!c.equals("red") && !c.equals("green") && !c.equals("blue"))
      c = "white";

    sCol = c.toLowerCase();

    for (int i =0; i < sColAvgLen; i++) {
      cList.add(color(0, 0, 0));
    }
  }

  void setPos(float x, float y) {
    xPos = x;
    yPos = y;
  }

  void display(color in) {

    updateAvg(in);
    in = getAvg();

    switch (sCol) {
    case "red": 
      size = (int)map(((in >> 16) & 0xFF), 0, 255, 1, maxSquigSize);
      fill(255, 0, 0);
      break;
    case "green": 
      size = (int)map(((in >> 8) & 0xFF), 0, 255, 1, maxSquigSize);
      fill(0, 255, 0);
      break;
    case "blue": 
      size = (int)map((in & 0xFF), 0, 255, 1, maxSquigSize);
      fill(0, 0, 255);
      break; 
    case "white": 
      size = (in >> 16) & 0xFF;
      fill(255);
    }
    //rect(xPos, yPos, size, size);

    pushStyle();
    colorMode(HSB);
    noFill();

    beta = brightness(in) * betaScale;
    if (beta > maxBeta)
      beta = maxBeta;
    amp =  brightness(in) * ampScale;
    if (monochrome)
      stroke(255);
    else
      stroke(hue(in), saturation(in), brightness(in)*2);


    beginShape();
    for (int i = 0; i < vNum; i++) {

      float yn = yPos + map(i, 0, vNum, 0, len);
      float xn = xPos + sin(tick + i*beta)*amp;
      curveVertex(xn, yn);
    }
    endShape();

    popStyle();

    tick += dt;
  }

  void toggleColor() {
    monochrome = !monochrome;
  }
}