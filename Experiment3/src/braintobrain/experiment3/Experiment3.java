package braintobrain.experiment3;

import processing.core.PApplet;
import processing.core.PShape;


import oscP5.OscP5;
import oscP5.OscMessage;

import netP5.NetAddress;

/**
 * Brain-to-Brain Communication Experiment 3.
 * 
 * Uses OpenBCI and the associated GUI for recording.
 * 
 * Please ensure proper electrode placement (following International
 * 10/20 guidelines):
 *  - BIAS/SRB on A1/A2
 *  - N1P on Oz
 *  - N2P on Fp1
 *  
 * The experiment displays a Processing window, then performs 20
 * randomized trials, 10 each for both the control and experimental
 * conditions, as follows:
 *   - Control:
 *      o  No presented visual stimulus
 *   - Experimental:
 *      o  Large rectangle flashing black and white at 8 Hz
 *      
 * For both cases, the trial is initiated with an audio cue of 2 beeps.
 * 
 * Cues of one beep then signal when the subject should change his/her
 * gazing direction, following the sequence below:
 *    left --> right --> up --> down
 * 
 * 
 * @author Chris Micek
 * Date: 2016/07/20
 */
public class Experiment3 extends PApplet {

    /** Explicit serialVersionUID to avoid class conflicts. */
    public static final long serialVersionUID = 1L;
    

    /** Server port for oscP5. */
    public static final int SERVERPORT = 6001;
    
    /** Client port for oscP5. */
    public static final int CLIENTPORT = 5001;
    
    
    /** Color to fill a rectangle for SSVEP. */
    public static final int FILLCOLOR = 255;
    
    /** Percentage of the screen for the rectangle to fill. */
    public static final float SCREENPERCENT = 5f / 6;
    
    /** Time to delay from idle state to experiment start (in milliseconds). */
    public static final int IDLETIME = 15000;
    
    /** Time for each gaze. */
    public static final int GAZETIME = 5000;
    
    /** Frequency of SSVEP stimulus (in Hz). */
    public static final double FREQ = 8.0;
    
    
    
    /** Starting time of the program (in milliseconds). */
    int startTime = millis();
    
    /** Counters for number of times each condition has occurred. */
    int[] counters = new int[2];
    
    /** Counter for number of draw loop iterations.
     *  Used for flash/sound signals. */
    int loopCount = 0;
    
    /**
     * State of the program, sent to EEG output file.
     * Possible states.
     * 0 = pre-experiment
     * 1 = idle
     * 2 = control
     * 3 = experimental
     * 4 = post-experiment
     */
    int state = 0;
    
    /** 
     * Current gaze direction, sent to EEG output file. 
     * 0 = left
     * 1 = right
     * 2 = up
     * 3 = down
     */
    int gazeDirection = 0;
    
    
    //For communication with OpenBCI_GUI
    /** Location of local UDP server (this program). */
    OscP5 oscP5Location2 = new OscP5(this, SERVERPORT);
    
    /** Location of UDP client (OpenBCI_GUI). */
    NetAddress location1 = new NetAddress("127.0.0.1", CLIENTPORT);
    
    /** Message to send to client. */
    OscMessage myMessage2 = new OscMessage("/test");
    
    /** Flashing square for SSVEP. */
    PShape rectangle;

    /**
     * Change state to newstate, and send state as UDP message.
     * @param newstate the number of the new state
     */
    public void changeState(int newstate) {
        state = newstate; //update state
        myMessage2.add(newstate);
        oscP5Location2.send(myMessage2, location1);
        myMessage2.clear(); 
        java.awt.Toolkit.getDefaultToolkit().beep();
        java.awt.Toolkit.getDefaultToolkit().beep();
    }
    
    /**
     * After the idle state, randomly chooses a new state for
     * experiment conditions, or the exit state if all trials
     * have been exhausted.
     * @return the new current state
     */
    public int chooseState() {
        if (counters[0] == 20 && counters[1] == 20) {
            return 4;
        } else if (counters[0] == 20 && counters[1] != 20) {
            counters[1]++;
            return 3;
        } else if (counters[0] != 20 && counters[1] == 20) {
            counters[0]++;
            return 2;
        } else {
            int currState = 2 + (int) (Math.random() * 3);
            counters[currState - 2] = counters[currState - 2] + 1;
            return currState;
        }
    }


    @Override
    public void setup() {
        size(displayWidth, displayHeight, P2D); // Basically fullscreen
        background(0); // Start black
        shapeMode(CENTER);
        rectangle = createShape(RECT, width / 2, height / 2,
                width * SCREENPERCENT,
                width * SCREENPERCENT);
        rectangle.setFill(color(FILLCOLOR));

        for (int i = 0; i < 2; i++) {
            counters[i] = 0;
        }
    }


    @Override
    public void draw() {
        
        if (millis() - startTime > IDLETIME && state == 0) {
            changeState(1);
        }
        
        if (millis() - startTime > 2 * IDLETIME && state == 1) {
            changeState(chooseState());
        }
              
        if (state == 2 || state == 3) {
            if (loopCount == 0) {
                myMessage2.add(state + ", " + gazeDirection);
                oscP5Location2.send(myMessage2, location1);
                myMessage2.clear(); 
                java.awt.Toolkit.getDefaultToolkit().beep();
                
            } else if (loopCount % 80 == 0) {
                gazeDirection++;
                if (gazeDirection == 4) {
                    gazeDirection = 0;
                }
                myMessage2.add(state + ", " + gazeDirection);
                oscP5Location2.send(myMessage2, location1);
                myMessage2.clear(); 
                java.awt.Toolkit.getDefaultToolkit().beep();
            }
            
            if (state == 2) {
                rectangle.setFill(color(0));
                shape(rectangle);
            } else {
                if (loopCount % 2 == 0) {
                    rectangle.setFill(color(FILLCOLOR));
                } else {
                    rectangle.setFill(color(0));
                }
                shape(rectangle);
            }
            
            if (loopCount != 0 && loopCount % 320 == 0) {
                changeState(chooseState());
            }
            loopCount++;
        }
        
        
        if (state == 4) {
            exit();
        }
        delay((int) (1.0 / FREQ) * 500);
    }

    /**
     * Main program for rendering Processing display.
     * @param args Command-line arguments (do not modify)
     */
    public static void main(String[] args) {
        PApplet.main(new String[] {
                braintobrain.experiment3.Experiment3.class.getName()});
    }
}