# Search and rescue robot

Assignment for "Programming Things" - Computer Science - Ryan Gough & Ben Pratt

This assignment was integrating different technologies to make a Zumo robot go to a ball with the help from the Kinect
feeding it information about where the Zumo is and where it needs to go. It sends information via XBee's from a computer
to the Zumo. The zumo also has ultrasonic sensors on it, these are used to detect when an object is in the way. This helps because
the Kinect is situated above the Zumo and some objects will appear to be 2D to the Kinect, and therefore, will not find them.

# Processing

Processing was the IDE that we used to create the controller. Most of the computation happened here. We did
attempt to pass the coordinates to the Zumo and do all processing there, but we suddenly ran out of memory after trying to create coordinate paths etc.
We used the library SimpleOpenNI (http://openni.ru/files/simpleopenni/index.html) in Processing 2.0 to allow for use of the kinect. 
To detect colours, we used the method used on here: https://zugiduino.wordpress.com/2012/12/30/kinect-color-tracking/ but we adapted it
to suit our needs and we detected multiple colours per pass of the webcam. This was because it was very slow at getting many of these
snap shots to create an average that we could rely on.

To talk between Processing and the Zumo, we used XBee's. We used the sparkfun tutorial to help us get it set up(https://learn.sparkfun.com/tutorials/connecting-arduino-to-processing).
With the first assignment, we only had to send messages in one direction, but to recalibrate the Zumo after coming into contact
with an obstacle, we had to send messages to the controller.

# Arduino

The Zumo side was programmed in Arduino IDE, and it was essentially the worker for the Processing controller. For the most part, it recieved an action, and processed that action. The ultra sonic sensor detected distances from obstacles, and returned the value. We did find it to show incorrect values sometimes, but most of the time it seemed to work well. The code we altered slightly was found
at (http://randomnerdtutorials.com/complete-guide-for-ultrasonic-sensor-hc-sr04/), it seemed to be very accurate, so all we needed
to change the return vals. We had some issues with finding available pins for the trig/echo. The Arduino board is connected to a Zumo robot and the XBee shield. The Zumo had a few pre-assigned actions, such as turn left, reverse or move forward that the controller could send. 

# How it works

