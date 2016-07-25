package braintobrain.experiment3;

import processing.core.PApplet;
import processing.core.PShape;

import java.util.concurrent.ThreadLocalRandom;

import oscP5.OscP5;
import oscP5.OscMessage;
import netP5.NetAddress;

import ddf.minim.Minim;
import ddf.minim.AudioPlayer;

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
    
    
    /** File path to state-change beep file. */
    public static final String BEEP =
            "C:/Users/Chris/git/Experiment3/Experiment3/src/data/beep-08b.wav";
    
    
    /** Color to fill a rectangle for SSVEP. */
    public static final int FILLCOLOR = 255;
    
    /** Percentage of the screen for the rectangle to fill. */
    public static final float SCREENPERCENT = 1f / 6;
    /* NOTE: Audio timing is hugely affected by the size of the stimulus.
    Change with caution. */
    
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
    
    
    /** Minim instance for loading audio. */
    Minim minim;
    
    /** AudioPlayer to play sounds. */
    AudioPlayer player;
    
    /** Flashing square for SSVEP. */
    PShape rectangle;

    /**
     * Change state to newstate, and send state as UDP message.
     * @param newstate the number of the new state
     */
    public void changeState(int newstate) {
        state = newstate; //update state
        myMessage2.add(newstate);
     // Record new state in GUI data
        oscP5Location2.send(myMessage2, location1);
        myMessage2.clear(); 
        player.play();
    }
    
    /**
     * After the idle state, randomly chooses a new state for
     * experiment conditions, or the exit state if all trials
     * have been exhausted.
     * @return the new current state
     */
    public int chooseState() {
        if (counters[0] == 20 && counters[1] == 20) {
            // All trials finished; exit
            return 4;
        } else if (counters[0] == 20 && counters[1] != 20) {
            // Need more state 3
            counters[1]++;
            return 3;
        } else if (counters[0] != 20 && counters[1] == 20) {
            // Need more state 2
            counters[0]++;
            return 2;
        } else {
            // Randomly choose either state 2 or state 3
            int currState = ThreadLocalRandom.current().nextInt(2, 3 + 1);
            counters[currState - 2] = counters[currState - 2] + 1;
            return currState;
        }
    }


    @Override
    public void setup() {
        minim = new Minim(this);
        player = minim.loadFile(BEEP);
        size(1920, 1080, P2D); // Basically fullscreen
        background(0); // Start black
        shapeMode(CENTER);
        rectangle = createShape(RECT, width / 2, height / 2,
                width * SCREENPERCENT,
                width * SCREENPERCENT);
        rectangle.setFill(color(FILLCOLOR));

        for (int i = 0; i < 2; i++) {
            counters[i] = 0;
        }
        player.play();
    }


    @Override
    public void draw() {
        
        if (millis() - startTime > IDLETIME && state == 0) {
            changeState(1);
        }
        
        if (millis() - startTime > 2 * IDLETIME && state == 1) {
            // Randomly choose experiment state.
            changeState(chooseState());
        }
              
        if (state == 2 || state == 3) {
            // Update state first
            if (loopCount != 0 && loopCount % 320 == 0) {
                changeState(chooseState());
            }
            
            // Keep track of gaze directions
            if (loopCount == 0) {
                myMessage2.add(state * 10 + gazeDirection);
                oscP5Location2.send(myMessage2, location1);
                myMessage2.clear(); 
                java.awt.Toolkit.getDefaultToolkit().beep();
                
            } else if (loopCount % 80 == 0) {
                ++gazeDirection;
                if (gazeDirection == 4) {
                    gazeDirection = 0;
                }
                myMessage2.add(state * 10 + gazeDirection);
                oscP5Location2.send(myMessage2, location1);
                myMessage2.clear(); 
                java.awt.Toolkit.getDefaultToolkit().beep();
            }
            
            if (state == 2) {
                // No flash
                rectangle.setFill(color(0));
                shape(rectangle);
            } else { // State 3 --> SSVEP
                if (loopCount % 2 == 0) {
                    rectangle.setFill(color(FILLCOLOR));
                } else {
                    rectangle.setFill(color(0));
                }
                shape(rectangle);
            }
            
           
            loopCount++;
        }
        
        
        if (state == 4) {
            exit();
        }
        
        // 4 Hz per rectangle color change
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