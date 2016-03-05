#include <LinkedList.h>
#import "Coordinates.h";
#include <SoftwareSerial.h>
#include <ZumoMotors.h>
int ledPin = 13; // Set the pin to digital I/O 13
SoftwareSerial XBee(2, 3); // RX, TX
const int SIZE_X = 640;
const int SIZE_Y = 480;
//
const int trigPin = 12;
const int echoPin = 5;

int turnLeftCount = 0;
bool completedRetrieve;

ZumoMotors motors;


void setup() 
{
//initialize serial communications at a 9600 baud rate
  pinMode(ledPin, OUTPUT); // Set pin as OUTPUT
  Serial.begin(9600);
  XBee.begin(9600); 
}

void loop(){

 // Wait for an action to carry out
 ZumoAction action = awaitAction();
 // Carry out action
 processAction(action);

  delay(50);
}

// Deal with action recieved via XBee
void processAction(ZumoAction action){

  // Large left swipes
  if(action == largeLeft){
    largeLeftTurn();
  }

  // Small left
  if(action == left){
    scanNewPathLeft();
  }

  // Forward until obstacle
  if(action == forward){
    moveForward();
  }

  // Found ball
  if(action == found){
    celebrateFoundBallAndReset();
  }
}

// Spin in a circle and wait 5 seconds
void celebrateFoundBallAndReset(){
  motors.setSpeeds(200,-200);
  delay(2000);
  motors.setSpeeds(0,0);
  delay(5000);
  //XBee.clear();
}

void largeLeftTurn(){
  motors.setSpeeds(200,-200);
  delay(300);
  motors.setSpeeds(0,0);
}

// Move to the left, if it happens 9 times, recalibrate.
void scanNewPathLeft(){

  if(turnLeftCount > 9){
    turnLeftCount = 0;
    XBee.write("recalibrate\n");
   delay(200);
    return;
  }

   motors.setSpeeds(-200,200);
   delay(50);
   motors.setSpeeds(0,0);
   turnLeftCount++;
}


// Move forward in increments checking an obstacle at every
// iteration
void moveForward(){
   
   int i = 0;
    
    while ( i < 1000 ){
    motors.setSpeeds(100,100);
    delay(100); 
    motors.setSpeeds(0,0);
    float cmdist = getObstacleDistanceInCM();
    if(cmdist < 15.00){
          manoeuvreObstacle();
          return;
     }
     
     i+=100;
    }

}


// Reverse back from the obstacle, check left and right, and then
// take the path which has the larger distance from zumo
void manoeuvreObstacle(){
  // Reverse back slightly
  motors.setSpeeds(-100,-100);
  delay(500);
  
  // Turn right, check distance
  motors.setSpeeds(150,-150);
  delay(250);
  float rightCMDistance = getObstacleDistanceInCM();
  
  //Turn left, check distance
  motors.setSpeeds(-150,150);
  delay(500);
  float leftCMDistance = getObstacleDistanceInCM();
  
  // Choose path with more distance from tests
  if(leftCMDistance < rightCMDistance){
    motors.setSpeeds(150,-150);
    delay(500);
  }
  
  moveForward();

  delay(100);
  
  // After a reverse, it is recalibrated
  XBee.write("recalibrate\n");

  delay(200);

  // Reset quick turn
  turnLeftCount = 0;
  
}

float getObstacleDistanceInCM(){
   long duration, inches, cm;
 
  // The sensor is triggered by a HIGH pulse of 10 or more microseconds.
  // Give a short LOW pulse beforehand to ensure a clean HIGH pulse:
  pinMode(trigPin, OUTPUT);
  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);
 
  // Read the signal from the sensor: a HIGH pulse whose
  // duration is the time (in microseconds) from the sending
  // of the ping to the reception of its echo off of an object.
  pinMode(echoPin, INPUT);
  duration = pulseIn(echoPin, HIGH);
 
  // convert the time into a distance
  inches = microsecondsToInches(duration);
  double inchesToCm = 2.54 * inches;
  cm = microsecondsToCentimeters(duration);
  cm += inchesToCm;

  return cm;
}

// Retrieves all info sent from Kinect, sets in class variables for access
ZumoAction awaitAction(){
   String string;
   
  if (XBee.available()){
    
      string = XBee.readStringUntil('\0');
      
     if(string.startsWith("left")){
      ZumoAction action = left;
      return action;
     }
     
     if(string.startsWith("forward")){
      ZumoAction action = forward;
      turnLeftCount = 0;
      return action;
     }

     if(string.startsWith("found")){
      ZumoAction action = found;
      turnLeftCount = 0;
      return action;
     }

     if(string.startsWith("largeLeft")){
      ZumoAction action = largeLeft;
      return action;
     }

   }
   
}

// For ultra sonic time
long microsecondsToInches(long microseconds)
{
  return microseconds / 74 / 2;
}
 
long microsecondsToCentimeters(long microseconds)
{
  return microseconds / 29 / 2;
}


