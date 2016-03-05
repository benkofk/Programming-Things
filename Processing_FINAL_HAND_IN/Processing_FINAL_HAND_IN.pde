import SimpleOpenNI.*;
SimpleOpenNI kinect;
import processing.serial.*;
import java.util.List;
import java.util.Iterator;



final int SIZE_X = 640;
final int SIZE_Y = 480;

// Serial
Serial XBee;  // Create object from Serial class


// Frame stuff
PImage currentFrame;
color trackColorRed;
color trackColorGreen;
color trackColorBlue;
color trackScreenPress;


Coordinates blueBall;
Coordinates greenBall;
Coordinates redBall;

ArduinoStatus arduinoStatus;

int onPathCounter;
int onMissedPathCounter;
boolean foundLoosePath;

void setup()
{
  size(SIZE_X, SIZE_Y);

  // Get XBee serial
  XBee = new Serial(this, "/dev/tty.usbserial-DA01HA3Y", 9600);

  // start simpleOpenNI lib
  kinect = new SimpleOpenNI(this);
  kinect.enableRGB();
  smooth ();

  currentFrame = createImage (SIZE_X, SIZE_Y, RGB);
  
  // set vars
  arduinoStatus = ArduinoStatus.deciding;
  foundLoosePath = false;
  trackScreenPress = color(0,0,0);
}

void draw()
{
  // Scan all webcam pixels, get red green and purple closest on each 
  getColourAverage();
  
  // Get trajectory of the zumo 
  Coordinates zumoAngle = findZumoAngle();
  
  // Create a path of its current trajectory
  List<Coordinates> coordinatePath = createCoordinatePath(zumoAngle);

  // To begin with, the zumo finds a general path to get it in the right direction
  if(!foundLoosePath){
    findLoosePath(coordinatePath);
  }else{
    // After finding a general path, the accuracy is increased and it is checked if it is 
    // currently on path
  // path & accuracy (higher is more accurate)
  boolean onPath = isOnPathToTarget(coordinatePath, 20);
  updatePathCounterAndArduinoStatus(onPath);
  
  // Checks if the ball has been found yet
  checkIfBallHasBeenFound();
  
  // If the path is being decided whether or not it is a path to be taken yet, the status
  // is set as deciding inside the updatePathCounterAndArduinoStatus method
    if(arduinoStatus != ArduinoStatus.deciding){
       processAction();
    }
  
  }
  
  // Output reply messages
    outputSerial();

  delay(200);
}

// Find a general path
void findLoosePath(List<Coordinates>  coordinatePath){
  
  // using a lower accuracy
    boolean onPath = isOnPathToTarget(coordinatePath, 10);
    if(onPath){
      // if it's on, we have a general path
      foundLoosePath = true;
    }
    
    // a large left turn happens whether it is or isn't, and then it is slowly iterated
    // if it's on a general path
    XBee.write("largeLeft" + "\0");
    println("Large left turn");
    delay(300);
    
}

// if ball has been found, make zumo spin
void checkIfBallHasBeenFound(){
  int redX = redBall.x;
  int redY = redBall.y;
  int greenX = greenBall.x;
  int greenY = greenBall.y;
  
  int redXDifference = abs(redX - greenX);
  int redYDifference = abs(redY - greenY);
  
  // if red is within 25 x and y difference of target
  
  if(redXDifference < 25 && redYDifference < 25){
        XBee.write("found" + "\0");
        println("Found ball!");
        foundLoosePath = false;
        delay(5000);
        resetPathCount();
        XBee.clear();
  }
  
}

void processAction(){
  
  // tells the zumo what to do
  
  if(arduinoStatus == ArduinoStatus.onPath){
    XBee.write("forward" + "\0");
    println("On path");
    delay(150);
  }
  
  if(arduinoStatus == ArduinoStatus.notOnPath){
     XBee.write("left" + "\0");
     println("Not on path");
     delay(150);
  }
  
  if(arduinoStatus == ArduinoStatus.found){
       XBee.write("found" + "\0");
       println("Found ball");
  }
  
  resetPathCount();
}

// if we want to track anything other than the green ball, this should be used
// and it is simply used by clicking on something on the kinect screen
void mousePressed(){
 trackScreenPress = get(mouseX, mouseY);
}


void resetPathCount(){
 onPathCounter = 0; 
 onMissedPathCounter = 0;
}

// decisions on whether it should take a path or not have been guarded
// by some logic. if two onPath's happen, it is considered to be on target
// if there are three missed paths, it is considered to be off target, else it is deciding
// and the zumo will do another loop
void updatePathCounterAndArduinoStatus(boolean onPath){
   if(onPath == true){
     onPathCounter++;
   }else{
     onMissedPathCounter++;
   } 
   
  if(onPathCounter >= 2){
    arduinoStatus = ArduinoStatus.onPath;
  }else if(onMissedPathCounter >= 3){
    arduinoStatus = ArduinoStatus.notOnPath;
  }else{
    arduinoStatus = ArduinoStatus.deciding;
  }
}

// checks if the coordinate path is on target

boolean isOnPathToTarget(List<Coordinates> coordinatePath, int rangeOfAccuracy){
  //int rangeOfAccuracy = 20; // higher = more accurate
  int xAccuracy = SIZE_X / rangeOfAccuracy;
  int yAccuracy = SIZE_Y / rangeOfAccuracy;
  
  // goes through all coordinates seeing if any in the path are within 10% of the 
  // green ball
  for(Coordinates coord : coordinatePath){
   
   int targetX = greenBall.x;
   int targetY = greenBall.y;
   int posX = coord.x;
   int posY = coord.y;
   
    if(posX < targetX + xAccuracy && posX > targetX - xAccuracy){
      if(posY < targetY + yAccuracy && posY > targetY - yAccuracy){
         return true;
       } 
     }
    
  }
  
  return false;
}

// Creates a coordinate path with some error protection, it takes the zumo
// trajectery, and adds/subtracts it to the red until hitting arena edge.
List<Coordinates> createCoordinatePath(Coordinates zumoTrajectory){
  List<Integer> xCoordTrajectoryList = new ArrayList<Integer>();
  List<Integer> yCoordTrajectoryList = new ArrayList<Integer>();

  int redX = redBall.getX();
  int redY = redBall.getY();
  
  // the trajectory is divided by 4 for more precision
  float xTrajectory = zumoTrajectory.x / 4;
  float yTrajectory = zumoTrajectory.y / 4;
  
  // X
  if(xTrajectory < 0){
    int tempRedX = redX;
      while(tempRedX > 0){
        xCoordTrajectoryList.add(tempRedX);
        tempRedX += xTrajectory;
      }
  }else if(xTrajectory >0){
      int tempRedX = redX;
      while(tempRedX < SIZE_X){
         xCoordTrajectoryList.add(tempRedX);
         tempRedX += xTrajectory;
      }
    }
    
    // Y
    if(yTrajectory < 0){
    int tempRedY = redY;
      while(tempRedY > 0){
        yCoordTrajectoryList.add(tempRedY);
        tempRedY += yTrajectory;
      }
  }else if(yTrajectory > 0){
      int tempRedY = redY;
      while(tempRedY < SIZE_Y){
         yCoordTrajectoryList.add(tempRedY);
         tempRedY += yTrajectory;
      }
    }
    
    // If there are any more X coords than Y (and vice versa), they should be disregarded
    // as it cannot travel in that direction any further. 
    int difference = abs(yCoordTrajectoryList.size() - xCoordTrajectoryList.size());
    
    if(xCoordTrajectoryList.size() < yCoordTrajectoryList.size()){
     while(difference > 0){
      yCoordTrajectoryList.remove(yCoordTrajectoryList.size()-1);
      difference--;
     }
  }else{
     while(difference > 0){
      xCoordTrajectoryList.remove(xCoordTrajectoryList.size()-1);
      difference--;
     }
  }
  
  // final coordinate path X & Y put together
  List<Coordinates> coordinatePath = new ArrayList<Coordinates>();
  
  int  i = 0;
    while ( i < xCoordTrajectoryList.size()){
      Coordinates coords = new Coordinates();
      coords.setX(xCoordTrajectoryList.get(i));
      coords.setY(yCoordTrajectoryList.get(i));
      coordinatePath.add(coords);
      i++;
    }
    
  return coordinatePath;
}

// takes the red location and removes it from blue, this gives us a trajectory
// of which way the zumo is currently facing
Coordinates findZumoAngle(){
  int trajectoryX = (redBall.x - blueBall.x);
  int trajectoryY = (redBall.y - blueBall.y);

  Coordinates tempCoords = new Coordinates();
  tempCoords.setX(trajectoryX);
  tempCoords.setY(trajectoryY);

  return tempCoords;
}

// outputs XBee messages, handles 'recalibrate'
void outputSerial(){
  String val = "";
  if ( XBee.available() > 0) 
  {  // If data is available,
  val = XBee.readStringUntil('\n');         // read it and store it in val
    if(val!=null&&val.startsWith("recalibrate")){
        //println("XBEEMSG: " + val);
        println("Recalibrating...");
        resetPathCount();
        foundLoosePath = false;
        delay(100);
        XBee.clear();
    }
  }  
}

// Gets 5 sets of three coordinates for red green and blue ball.
void getColourAverage(){
  final int AMOUNT_OF_COORDINATES = 5;
  
  // Gets all averages
  List<List> list = new ArrayList();
  for (int i = 0 ; i < AMOUNT_OF_COORDINATES ; i++) {
    list.add(getColours());
  }
  

  List<Coordinates> blueList = new ArrayList();
  List<Coordinates> redList = new ArrayList();
  List<Coordinates> greenList = new ArrayList();

// Split into different lists
  for(List innerList : list){
      Coordinates blueCoords = (Coordinates) innerList.get(0);
      blueList.add(blueCoords);
      Coordinates redCoords = (Coordinates) innerList.get(1);
      redList.add(redCoords);
      Coordinates greenCoords = (Coordinates) innerList.get(2);
      greenList.add(greenCoords); 
  }
  
  Coordinates tempLowestCoordinate = new Coordinates();
  List<Coordinates> blueXSortedList = new ArrayList();
  
  // Sort the list from lowest to highest
  for(int i = 0 ; i < AMOUNT_OF_COORDINATES ; i ++){ 
   int lowestX = 100000000;
   for(Coordinates coord : blueList){
     if(coord.x < lowestX){
       lowestX = coord.x;
       tempLowestCoordinate = coord;
     }
   }
   blueXSortedList.add(tempLowestCoordinate);
   blueList.remove(tempLowestCoordinate);
 }
 
  // Remove outer X edges, this is an error guard for potentially fluctuating kinect info
   blueXSortedList.remove(AMOUNT_OF_COORDINATES-1);
   blueXSortedList.remove(0);
  
  
 // Sort Y lowest to largest, now with juts three coordinates remaining
 List<Coordinates> blueXYSortedList = new ArrayList();
  
   for(int i = 0 ; i < AMOUNT_OF_COORDINATES-2 ; i ++){ 
   int lowestY = 100000000;
   for(Coordinates coord : blueXSortedList){
     if(coord.y < lowestY){
       lowestY = coord.y;
       tempLowestCoordinate = coord;
       }
     }
   blueXYSortedList.add(tempLowestCoordinate);
   blueXSortedList.remove(tempLowestCoordinate);
   }
   
   // Remove outer edge Y results, so we are now left with just one resulet
   blueXYSortedList.remove(AMOUNT_OF_COORDINATES-3);
   blueXYSortedList.remove(0);
   
   // Sort for red aswell..
  
   List<Coordinates> redXSortedList = new ArrayList();
     
  for(int i = 0 ; i < AMOUNT_OF_COORDINATES ; i ++){ 
   int lowestX = 100000000;
   for(Coordinates coord : redList){
     if(coord.x < lowestX){
       lowestX = coord.x;
       tempLowestCoordinate = coord;
     }
   }
   redXSortedList.add(tempLowestCoordinate);
   redList.remove(tempLowestCoordinate);
 }
 
  // Remove outer X's
   redXSortedList.remove(AMOUNT_OF_COORDINATES-1);
   redXSortedList.remove(0);
  
 // Sort Y, remove outer two results
 List<Coordinates> redXYSortedList = new ArrayList();
  
   for(int i = 0 ; i < AMOUNT_OF_COORDINATES-2 ; i ++){ 
   int lowestY = 100000000;
   for(Coordinates coord : redXSortedList){
     if(coord.y < lowestY){
       lowestY = coord.y;
       tempLowestCoordinate = coord;
       }
     }
   redXYSortedList.add(tempLowestCoordinate);
   redXSortedList.remove(tempLowestCoordinate);
   }
   
   
   redXYSortedList.remove(AMOUNT_OF_COORDINATES-3);
   redXYSortedList.remove(0);
   
   // Sort for green aswell. 
   
    List<Coordinates> greenXSortedList = new ArrayList();
     
  for(int i = 0 ; i < AMOUNT_OF_COORDINATES ; i ++){ 
   int lowestX = 100000000;
   for(Coordinates coord : greenList){
     if(coord.x < lowestX){
       lowestX = coord.x;
       tempLowestCoordinate = coord;
     }
   }
   greenXSortedList.add(tempLowestCoordinate);
   greenList.remove(tempLowestCoordinate);
 }
 
 
  // Remove outer X's
   greenXSortedList.remove(AMOUNT_OF_COORDINATES-1);
   greenXSortedList.remove(0);
  
 // Sort Y, remove outer two results
 List<Coordinates> greenXYSortedList = new ArrayList();
  
   for(int i = 0 ; i < AMOUNT_OF_COORDINATES-2 ; i ++){ 
   int lowestY = 100000000;
   for(Coordinates coord : greenXSortedList){
     if(coord.y < lowestY){
       lowestY = coord.y;
       tempLowestCoordinate = coord;
       }
     }
   greenXYSortedList.add(tempLowestCoordinate);
   greenXSortedList.remove(tempLowestCoordinate);
   }
   
   // remove outer y results
   greenXYSortedList.remove(AMOUNT_OF_COORDINATES-3);
   greenXYSortedList.remove(0);
  
  // Get all coordinates remaining, there will ony be three pairs left and they should be the
  // most accurate
  redBall = redXYSortedList.get(0);
  greenBall = greenXYSortedList.get(0);
  blueBall = blueXYSortedList.get(0);
}

// Scans the webcam and takes all of the readings at once for all the tracked colours
// using the dist function
List<Coordinates> getColours(){
   kinect.update();
  
  // Colours to detect
  trackColorBlue = color(108,36,170); // blue
  trackColorRed = color(223,7,122); // red
  trackColorGreen = color(120,144,8); //green
  
  // If the screen is pressed, use instead of green
  if(trackScreenPress != color(0,0,0)){
    trackColorGreen = trackScreenPress;
  }

  currentFrame = kinect.rgbImage ();
  image(currentFrame, 0, 0);

  currentFrame.loadPixels();

  // Before we begin searching, the "world record" for closest color is set to a high number that is easy for the first pixel to beat.
  float worldRecordBlue = 500;
  float worldRecordRed = 500;
  float worldRecordGreen = 500;

  // XY coordinate of closest color
  int closestBlueX = 0;
  int closestBlueY = 0;
  int closestRedX = 0;
  int closestRedY = 0;
  int closestGreenX = 0;
  int closestGreenY = 0;
  

  // Begin loop to walk through every pixel
  for (int x = 0; x < currentFrame.width; x ++ ) {
    for (int y = 0; y < currentFrame.height; y ++ ) {
      int loc = x + y*currentFrame.width;
      // What is current color
      color currentColor = currentFrame.pixels[loc];
      float r1 = red(currentColor);
      float g1 = green(currentColor);
      float b1 = blue(currentColor);
      
      // Track blue
      float r2 = red(trackColorBlue);
      float g2 = green(trackColorBlue);
      float b2 = blue(trackColorBlue);
      
      // Track red
      float r3 = red(trackColorRed);
      float g3 = green(trackColorRed);
      float b3 = blue(trackColorRed);
      
      // Track green
      float r4 = red(trackColorGreen);
      float g4 = green(trackColorGreen);
      float b4 = blue(trackColorGreen);
      
  
      // Using euclidean distance to compare colors
      float d1 = dist(r1, g1, b1, r2, g2, b2); // We are using the dist( ) function to compare the current color with the color we are tracking.
      float d2 = dist(r1, g1, b1, r3, g3, b3); // dist with red set
      float d3 = dist(r1, g1, b1, r4, g4, b4); // dist with green set


      // BLUE
      if (d1 < worldRecordBlue) {
        worldRecordBlue = d1;
        closestBlueX = x;
        closestBlueY = y;
      }
      
       // Red
      if (d2 < worldRecordRed) {
        worldRecordRed = d2;
        closestRedX = x;
        closestRedY = y;
      }
      
      // GREEN
      if (d3 < worldRecordGreen) {
        worldRecordGreen = d3;
        closestGreenX = x;
        closestGreenY = y;
      }
    }
  }
  
  List<Coordinates> list = new ArrayList();
  
  Coordinates blueCoords = new Coordinates();
  blueCoords.x = closestBlueX;
  blueCoords.y = closestBlueY;
  
  Coordinates redCoords = new Coordinates();
  redCoords.x = closestRedX;
  redCoords.y = closestRedY;

  Coordinates greenCoords = new Coordinates();
  greenCoords.x = closestGreenX;
  greenCoords.y = closestGreenY;

  // Add all the closest to a single list, and then this list is returned.
  list.add(blueCoords);
  list.add(redCoords);
  list.add(greenCoords);

  return list;
}


