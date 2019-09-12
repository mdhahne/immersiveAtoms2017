class ColorDot {
  float scale, size, xPos, yPos;
  String dCol;
  boolean atoms = false;
  float colorScale = 0;

  ColorDot(int s, float x, float y, String c) {
    scale = s;
    size = 0;
    xPos = x;
    yPos = y;
    dCol = c.toLowerCase();
    if (!c.equals("red") && !c.equals("green") && !c.equals("blue"))
      c = "white";
  }

  void setAtoms(boolean a) {
    atoms = a;
  }

  void setPos(float x, float y) {
    xPos = x;
    yPos = y;
  }
  
  void adjustColorScale(float a){
    colorScale += a;
  }

  void display(color in) {
    color temp = in;

    int r = (temp >> 16) & 0xFF; // Like red(), but faster
    int g = (temp >> 8) & 0xFF;
    int b = temp & 0xFF;
    
    if(r >= g && r >= b){
      in = color(r+r*colorScale, g-g*colorScale, b-b*colorScale);
    }
    if(g >= r && g >= b){
      in = color(r-r*colorScale, g+g*colorScale, b-b*colorScale);
    }
    if(b >= r && b >= g){
      in = color(r-r*colorScale, g-g*colorScale, b+b*colorScale);
    }

    switch (dCol) {
    case "red": 
      size = (int)map(((in >> 16) & 0xFF), 0, 255, 1, maxDotSize);
      fill(255, 0, 0);
      if (atoms) {
        fill(224, 147, 177);
      }
      break;
    case "green": 
      size = (int)map(((in >> 8) & 0xFF), 0, 255, 1, maxDotSize);
      fill(0, 255, 0);
      if (atoms) {
        //fill(155,254,131);
        fill(246, 222, 22);
      }
      break;
    case "blue": 
      size = (int)map((in & 0xFF), 0, 255, 1, maxDotSize);
      fill(0, 0, 255);
      if (atoms) {
        fill(77, 184, 254);
      }
      break; 
    case "white": 
      size = (in >> 16) & 0xFF;
      fill(255);
    }
    //rect(xPos, yPos, size, size);
    

    ellipse(xPos, yPos, size, size);
  }
}