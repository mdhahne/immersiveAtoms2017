/**
 */

int mode = 0;
int numModes = 4;
int cycleLength = 4 * 60;
int startTime;
boolean cycle = false;
boolean advertise = false;
boolean mirror = true;
boolean invert = true;

import processing.video.*;

int numPixels;
Capture video;

/* squiggles */
int maxSquigSize = 12;
int minSquigSize = 1;
int squigSpacing = 20;
int squigGain = 6;
int squigX, squigY;
Squiggle[][] squiggles = {{}};
/*end squiggles */


/* color Dots */
int maxDotSize = 12;
int minDotSize = 1;
int dotGain = 6;
int dotBg = 0;

//int maxDotSize = 60;
//int minDotSize = 6;
//int dotGain = 6;
//color dotBg = color(70);

int dotSpacing = 8;
int deltaDotSize = 0;
int dotSize = 0;
int dotsX, dotsY;

ColorDot[][] dots = {{}};
/* end color dots */


/* Common Differencing */
int[] previousFrame;
int averageList (ArrayList<Integer> list) {
  int result = 0;
  for (int i = 0; i < list.size(); i++) {
    result += list.get(i);
  }
  return result/list.size();
}
/* end Commmon Differencing */


/* color trails */
int colorPxThreshold = 120;
ArrayList<int[]> frameHistory = new ArrayList<int[]>();
int frameHistoryLength = 5;
int R, G, B, i;
/* end color trails*/

/* diff thresh */
int threshPxThreshold = 120;

/* end diff thresh */

/* advertising stuff */
PFont adfont;
float imgWidth = 0;
float textMargin = 0;
float textSize = 0;
float textBgHeight = 0;
String adtext = "ART + TECH Exhibition @ UMD  |  April 26-29 in Art/Soc 3306";

PImage logo;
/* end advertising stuff */

void setup() {
  //fullScreen();
  //size(1280, 720);
  //size(320, 180);
  size(1280, 960);

  imgWidth = width * 0.2;
  textMargin = imgWidth * 0.1;
  textSize = height * 0.038;
  textBgHeight = height * 0.1;
  logo = loadImage("logo.png");

  adfont = loadFont("Verdana-BoldItalic-48.vlw");

  String[] cameras = Capture.list();

  if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    exit();
  } else {
    println("Available cameras:");
    for (int i = 0; i < cameras.length; i++) {
      println(cameras[i]);
    }
  }

  noStroke();

  //video = new Capture(this, width, height, cameras[15]);
  video = new Capture(this, width, height);
  video.start(); 

  numPixels = video.width * video.height;
  loadPixels();

  startTime = millis()/1000;

  /* squiggles */
  colorMode(HSB);
  squiggles = new Squiggle[(width/squigSpacing)][(height/squigSpacing)];
  for (int i = 0; i < width/float(squigSpacing); i += 1) {
    for (int j = 0; j < height/float(squigSpacing); j += 1) {
      squiggles[i][j] = new Squiggle((i*float(squigSpacing)), (j*float(squigSpacing)), "white");
    }
  }
  /* end squiggles */

  /* color dots */
  colorMode(RGB);
  dots = new ColorDot[(width/dotSpacing)][(height/dotSpacing)];
  for (int i = 0; i < width/dotSpacing; i += 1) {
    for (int j = 0; j < height/dotSpacing; j += 1) {
      String c = "white";
      //switch (int(random(3))) {
      switch ((i+j)%3) {
      case 0: 
        c = "red";
        break;
      case 1: 
        c = "green";
        break;
      case 2: 
        c = "blue";
        break;
      }
      dots[i][j] = new ColorDot(maxDotSize, (i*dotSpacing) + random(-5, 5), (j*dotSpacing) + random(-5, 5), c);
    }
  }
  /* end color dots */


  /* common differencing */
  previousFrame = new int[numPixels];

  /* end common differencing */

  /* color Trails */
  if (frameHistoryLength < 1) {
    frameHistoryLength = 1;
    println("set historylength to 1 to prevent out of bounds issues");
  }

  for (int i = 0; i < frameHistoryLength; i++) {
    frameHistory.add(null);
  }
  /* end color trails */
}

void draw() {
  if (video.available()) {
    background(0);

    video.read(); // Read the new frame from the camera
    video.loadPixels(); // Make its pixels[] array available


    /* Squiggles */
    if (mode == 0) {
      colorMode(HSB);

      squigX = 0;
      squigY = 0;
      for (int i = 0; i < numPixels; i+= squigSpacing) { // For each pixel in the video frame...
        color currColor = video.pixels[i];
        if (mirror) {
          squiggles[(width/squigSpacing) - squigX - 1][squigY].display(currColor);
        } else {
          squiggles[squigX][squigY].display(currColor);
        }

        squigX++;
        if (squigX >= width/squigSpacing) {
          squigX = 0;
          squigY ++;
          if (squigY >= height/squigSpacing) {
            squigY = 0;
          }
        }
        if (i%video.width == 0) {
          i += (squigSpacing * video.width);
        }
      }
    }

    /* color dots */
    if (mode == 1) {
      colorMode(RGB);
      background(dotBg);
      dotsX = 0;
      dotsY = 0;
      for (int i = 0; i < numPixels; i+= dotSpacing) { // For each pixel in the video frame...
        color currColor = video.pixels[i];


        if (mirror) {
          dots[(width/dotSpacing) - dotsX - 1][dotsY].display(currColor);
        } else {
          dots[dotsX][dotsY].display(currColor);
        }
        //dots[dotsX][dotsY].display(currColor);


        dotsX++;
        if (dotsX >= width/dotSpacing) {
          dotsX = 0;
          dotsY ++;
          if (dotsY >= height/dotSpacing) {
            dotsY = 0;
          }
        }

        if (i%video.width == 0) {
          i += (dotSpacing * video.width);
        }
      }
    }
    /* color trails */
    if (mode == 2) {
      int [] diffImg = new int[numPixels];
      for (int i = 0; i < numPixels; i++) { // For each pixel in the video frame...
        int pxMovement = 0;

        color currColor = video.pixels[i];
        color prevColor = previousFrame[i];
        // Extract the red, green, and blue components from current pixel
        int currR = (currColor >> 16) & 0xFF; // Like red(), but faster
        int currG = (currColor >> 8) & 0xFF;
        int currB = currColor & 0xFF;
        // Extract red, green, and blue components from previous pixel
        int prevR = (prevColor >> 16) & 0xFF;
        int prevG = (prevColor >> 8) & 0xFF;
        int prevB = prevColor & 0xFF;
        // Compute the difference of the red, green, and blue values
        int diffR = abs(currR - prevR);
        int diffG = abs(currG - prevG);
        int diffB = abs(currB - prevB);
        // Add these differences to the running tally
        pxMovement = diffR + diffG + diffB;

        if (pxMovement > colorPxThreshold)
        {
          diffImg[i] = color(invert ? 0 : 255);
        } else {
          diffImg[i] = color(invert ? 255 : 0);
        }
        previousFrame[i] = currColor;
      }

      frameHistory.remove(0);
      frameHistory.add(diffImg);

      int[] bFrame = frameHistory.get(frameHistoryLength-1);
      int[] gFrame = frameHistory.get(frameHistoryLength/2);
      int[] rFrame = frameHistory.get(0);

      if (frameHistory.get(0) != null) {
        for (i = 0; i < numPixels; i++) { // For each pixel in the video frame...
          R = (rFrame[i] >> 16) & 0xFF;
          G = (gFrame[i] >> 8) & 0xFF;
          B = (bFrame[i]) & 0xFF;

          int y = i/width;
          int x = i%width;
          int newX = width - x - 1;
          if (!mirror) {
            newX =x;
          }
          int newI = y*width+newX;

          pixels[newI] = 0xff000000 | (R << 16) | (G << 8) | (B);
        }
      } else
        background(0, 0, 255);
      // To prevent flicker from frames that are all black (no movement),
      // only update the screen if the image has changed.
      if (colorPxThreshold > 0) {
        updatePixels();
        //println(movementSum); // Print the total amount of movement to the console
      }
    }

    /* diff thresh*/
    if (mode == 3) {
      for (int i = 0; i < numPixels; i++) { // For each pixel in the video frame...
        int pxMovement = 0;

        color currColor = video.pixels[i];
        color prevColor = previousFrame[i];
        // Extract the red, green, and blue components from current pixel
        int currR = (currColor >> 16) & 0xFF; // Like red(), but faster
        int currG = (currColor >> 8) & 0xFF;
        int currB = currColor & 0xFF;
        // Extract red, green, and blue components from previous pixel
        int prevR = (prevColor >> 16) & 0xFF;
        int prevG = (prevColor >> 8) & 0xFF;
        int prevB = prevColor & 0xFF;
        // Compute the difference of the red, green, and blue values
        int diffR = abs(currR - prevR);
        int diffG = abs(currG - prevG);
        int diffB = abs(currB - prevB);
        // Add these differences to the running tally
        pxMovement = diffR + diffG + diffB;

        int y = i/width;
        int x = i%width;

        int newX = width - x - 1;

        if (!mirror) {
          newX = x;
        }

        int newI = y*width+newX;

        if (pxMovement > threshPxThreshold)
        {
          pixels[newI] = color(invert ? 255 : 0);
        } else {
          pixels[newI] = color(invert ? 0 : 255);
        }

        // Save the current color into the 'previous' buffer
        previousFrame[i] = currColor;
      }
      // To prevent flicker from frames that are all black (no movement),
      // only update the screen if the image has changed.
      if (threshPxThreshold > 0) {
        updatePixels();
        //println(movementSum); // Print the total amount of movement to the console
      }
    }

    if (cycle) {
      updateMode();
    }

    if (advertise) {
      pushStyle();
      fill(0);
      rect(0, 0, width, textBgHeight);

      fill(255);
      textAlign(LEFT, CENTER);
      textFont(adfont, textSize);
      text(adtext, imgWidth + textMargin, 0, width, textBgHeight);


      // image standin
      //colorMode(RGB);
      //fill(204, 102, 0);
      //rect(0, 0, imgWidth, textBgHeight);
      image(logo, 0, 0, imgWidth, imgWidth*0.3869);

      popStyle();
    }
  }
}

void updateMode() {
  if (millis()/1000-startTime > cycleLength) {
    mode++;
    if (mode > numModes-1) {
      mode = 0;
    }
    if (mode < 0) {
      mode = numModes-1;
    }

    startTime = millis()/1000;
  }
}

void keyPressed() {
  switch(key) {
  case '1': 
  case '2': 
  case '3': 
  case '4': 
    // converts from ascii code to int value - 1
    // so pressing key '1' gives an int of 0.
    mode = int(key)-49; 
    break; 
  default:
    if (key == 'c' || key == 'C') {
      cycle = !cycle;
    }
    if (key == 'a') {
      advertise = !advertise;
    }
    if (key == 'A') {
      for (int i = 0; i < width/dotSpacing; i += 1) {
        for (int j = 0; j < height/dotSpacing; j += 1) {
          dots[i][j].atoms = !dots[i][j].atoms;
        }
      }
    }
    if (key == 'm' || key == 'M') {
      mirror = !mirror;
    }
    if (key == 'i' || key == 'I') {
      invert = !invert;
    }
    if (key == '.' || key == '>') {
      colorPxThreshold++;
      threshPxThreshold++;
    }
    if (key == ',' || key == '<') {
      colorPxThreshold--;
      threshPxThreshold--;
    }
    if (key == CODED) {
      if (keyCode == LEFT) {
        mode++;
      }
      if (keyCode == RIGHT) {
        mode--;
      }
      if (keyCode == UP) {
        for (int i = 0; i < width/dotSpacing; i += 1) {
          for (int j = 0; j < height/dotSpacing; j += 1) {
            dots[i][j].adjustColorScale(0.1);
          }
        }
      }
      if (keyCode == DOWN) {
        for (int i = 0; i < width/dotSpacing; i += 1) {
          for (int j = 0; j < height/dotSpacing; j += 1) {
            dots[i][j].adjustColorScale(-0.1);
          }
        }
      }
    } 
    if (mode > numModes-1) {
      mode = 0;
    }
    if (mode < 0) {
      mode = numModes-1;
    }
    break;
  }
}