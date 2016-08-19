package braintobrain.experiment3;

import processing.core.PApplet;
import processing.core.PShape;

import java.util.Random;
import java.util.TreeSet;

import oscP5.OscP5;
import oscP5.OscMessage;
import netP5.NetAddress;

//import ddf.minim.Minim;
//import ddf.minim.AudioPlayer;

/**
 * Brain-to-Brain Communication Experiment 3b.
 * 
 * Uses OpenBCI and the associated GUI for recording.
 * 
 * Please ensure proper electrode placement (following International
 * 10/20 guidelines):
 *  - BIAS/SRB on A1/A2
 *  - N1P on Oz
 *  - N2P on Fp2
 *  
 * The experiment displays a Processing window, then performs 10
 * randomized trials, 5 each for the control and experimental
 * conditions, as follows:
 *   - Control:
 *      o  White rectangle with red circle fixation point at center, and
 *         red rectangle saccade target at the rectangle's right edge
 *   - Experimental:
 *      o  Large rectangle flashing black and white at 8 Hz,
 *         with red circle fixation point at center, and red rectangle
 *         saccade target at the rectangle's right edge   
 *      
 * For all cases, the trial is initiated with an audio cue of one high-
 * pitched beep.
 * 
 * Cues of one system-default beep then signal when the subject should 
 * make saccades to the target
 * 
 * 
 * @author Chris Micek
 * Date: 2016/08/10
 */
public class Experiment3b extends PApplet {

    /** Explicit serialVersionUID to avoid class conflicts. */
    public static final long serialVersionUID = 1L;
    

    /** Server port for oscP5. */
    public static final int SERVERPORT = 6001;
    
    /** Client port for oscP5. */
    public static final int CLIENTPORT = 5001;
    
    
    /** File path to state-change beep file. */
    public static final String BEEP = 
            "beep-08b.wav";
            //"C:/Users/Chris/git/Experiment3/Experiment3/src/data/beep-08b.wav";
    
    /** Percentage of the screen for SSVEP rectangle to fill. */
    public static final float SCREENPERCENT = 1f / 5;
    /* NOTE: Audio timing is hugely affected by the size of the stimulus.
    Change with caution. */
    
    /** Percentage of the SSVEP rectangle for target rectangle to fill. */
    public static final float RECTPERCENT = 1f / 10;
    
    /** Time to delay from idle state to experiment start (in milliseconds). */
    public static final int IDLETIME = 15000;
    
    /** Time for each gaze. */
    public static final int GAZETIME = 22320;
    
    /** Frequency of SSVEP stimulus (in Hz). */
    public static final double FREQ = 8.0;
    
    /** Time to delay draw function. */
    public static final int DELAYTIME = (int) ((1.0 / FREQ) * 500);
    
    /** Number of loop iterations for the target to appear. */
    public static final int TARGETFRAMES = 15;
    
    
    /** Color to fill a rectangle for SSVEP. */
    public final int ssvepfill = color(255);
    
    /** Color to fill a rectangle for SSVEP. */
    public final int targetfill = color(255, 0, 0);
    
    
    
    /** Starting time of the program (in milliseconds). */
    int startTime = millis();
    
    /** Counters for number of times each condition has occurred. */
    int[] counters = new int[2];
    
    /** Counter for number of draw loop iterations.
     *  Used for flash/sound signals. */
    int loopCount = 0;
    
    /** Set of states excluded in choosing next state. */
    TreeSet<Integer> exStates = new TreeSet<Integer>();
    
    /** Random instance for state generator. */
    Random seed = new Random();
    
    /**
     * State of the program, sent to EEG output file.
     * Possible states.
     * 0 = pre-experiment
     * 1 = idle
     * 2 = control
     * 3 = experimental
     * 4 = SSVEP only
     * 5 = post-experiment
     */
    int state = 0;
    
    /** Stored number of eye saccades. */
    int gazeNum = 1;
    
    /** Number of loop iterations for the target to appear.
     * Decremented each trial. */
    int targetFrames = TARGETFRAMES;
    
    //For communication with OpenBCI_GUI
    /** Location of local UDP server (this program). */
    OscP5 oscP5Location2 = new OscP5(this, SERVERPORT);
    
    /** Location of UDP client (OpenBCI_GUI). */
    NetAddress location1 = new NetAddress("127.0.0.1", CLIENTPORT);
    
    /** Message to send to client. */
    OscMessage myMessage2 = new OscMessage("/test");
    
    
//    /** Minim instance for loading audio. */
//    Minim minim;
//    
//    /** AudioPlayer to play sounds. */
//    AudioPlayer player;
    
    /** Flashing square for SSVEP. */
    PShape ssvepRect;
    
    /** Small subtarget for eye saccades. */
    PShape target;
    
    /** Small circle to mark center of SSVEP rectangle. */
    PShape center;

    
    /**
     * Change state to newstate, and send state as UDP message.
     * @param newstate the number of the new state
     */
    public void changeState(int newstate) {
        state = newstate; //update state
        if (state == 2 || state == 3) {
            // First digit is state, last 2 are trial #
            myMessage2.add(state * 100 + 10 * counters[state - 2]);
        } else {
            myMessage2.add(newstate);
        }
     // Record new state in GUI data
        oscP5Location2.send(myMessage2, location1);
        myMessage2.clear();
//        java.awt.Toolkit.getDefaultToolkit().beep();
//        player.play();
    }
    
    /**
     * Generate a random integer in [start, end], excluding elements in
     * "exclude".
     * 
     * @param rnd       Random instance
     * @param start     the starting int for the range of numbers
     * @param end       the ending int for the range of numbers
     * @param exclude   the set of integers to exclude
     * @return          a random int in the specified range
     */
    public int getRandom(Random rnd, int start, int end, TreeSet<Integer> exclude) {
        int random = start
                + rnd.nextInt(end - start + 1 - exclude.size());
        for (int ex : exclude) {
            if (random < ex) {
                break;
            }
            random++;
        }
        return random;
    }
    
    /**
     * After the idle state, randomly chooses a new state for
     * experiment conditions, or the exit state if all trials
     * have been exhausted.
     * @return the new current state
     */
    public int chooseState() {
        if (counters[0] == 5 && counters[1] == 5) {
            // All trials finished; exit
            return 4;
        }
        if (counters[0] == 5) {
            // No more state 2
            exStates.add(2);
        }
        if (counters[1] == 5) {
            // No more state 3
            exStates.add(3);
        }
        // Randomly choose either state 2 or state 3
        int currState = getRandom(seed, 2, 3, exStates);
        counters[currState - 2] = counters[currState - 2] + 1;
        return currState;

    }


    @Override
    public void setup() {
//        minim = new Minim(this);
//        player = minim.loadFile(BEEP);
//        size(3840, 2160, P2D);
        size(displayWidth, displayHeight, P2D); // Basically fullscreen
        background(0); // Start black
        shapeMode(CENTER);
        int rectCenterX = width / 2;
        int rectCenterY = height / 2;
        ssvepRect = createShape(RECT, rectCenterX, rectCenterY,
                width * SCREENPERCENT,
                width * SCREENPERCENT);
        ssvepRect.setFill(ssvepfill);
        
        center = createShape(ELLIPSE, rectCenterX, rectCenterY,
                ssvepRect.getWidth() * RECTPERCENT / 3,
                ssvepRect.getWidth() * RECTPERCENT / 3);
        center.setFill(targetfill);
        
        target = createShape(RECT,
                5 * width / 6 + ssvepRect.getWidth() / 2f
                - (ssvepRect.getWidth() * RECTPERCENT / 2f),
                4 * height / 6 + ssvepRect.getWidth() / 2f
                - (ssvepRect.getWidth() * RECTPERCENT / 2f),
                ssvepRect.getWidth() * RECTPERCENT,
                ssvepRect.getWidth() * RECTPERCENT);
        target.setFill(targetfill);

        for (int i = 0; i < 2; i++) {
            counters[i] = 0;
        }
//        java.awt.Toolkit.getDefaultToolkit().beep();
//        player.play();
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
            if (loopCount != 0 && loopCount
                    % (int) ((double) GAZETIME / DELAYTIME)  == 0) {
                changeState(chooseState());
            }
            
            // Keep track of saccade number
            if (loopCount == 0 && state < 4) {
                myMessage2.add(state * 100 + 10 * counters[state - 2] + gazeNum);
                oscP5Location2.send(myMessage2, location1);
                myMessage2.clear(); 
                java.awt.Toolkit.getDefaultToolkit().beep();
                gazeNum++;
                
            } else if (loopCount % 90 == 0 && state < 4) {
                myMessage2.add(state * 100 + 10 * counters[state - 2] + gazeNum);
                oscP5Location2.send(myMessage2, location1);
                myMessage2.clear();
                if (gazeNum % 2 == 0) {
                    java.awt.Toolkit.getDefaultToolkit().beep();
                }
                gazeNum++;
                if (gazeNum == 5) {
                    gazeNum = 1;
                }
                targetFrames = TARGETFRAMES;
            }
            
            if (state == 2) {
                // No flash
                ssvepRect.setFill(color(0));
                shape(ssvepRect);
                shape(center);
                if (targetFrames == 0) {
                    target.setFill(color(0));
                    shape(target);
                }
                if ((gazeNum - 1) % 2 == 0 && targetFrames > 0) {
                    target.setFill(color(0));
                    shape(target);
                    targetFrames--;
                }
                
            } else if (state == 3) { // State 3 --> SSVEP with saccades
                if (loopCount % 2 == 0) {
                    ssvepRect.setFill(ssvepfill);
                } else {
                    ssvepRect.setFill(color(0));
                }
                shape(ssvepRect);
                shape(center);
                if (targetFrames == 0) {
                    target.setFill(color(0));
                    shape(target);
                }
                    
                if ((gazeNum - 1) % 2 == 0 && targetFrames > 0) {
                    target.setFill(color(0));
                    shape(target);
                    targetFrames--;
                } 
            }
            
            loopCount++;
        }
        
        
        if (state == 4) {
            exit();
        }
        
        // 4 Hz per rectangle color change
        delay(DELAYTIME);
    }

    /**
     * Main program for rendering Processing display.
     * @param args Command-line arguments (do not modify)
     */
    public static void main(String[] args) {
        PApplet.main(new String[] {
                braintobrain.experiment3.Experiment3b.class.getName()});
    }
}