import java.awt.*;
import java.awt.geom.Point2D;
//import processing.pdf.*;

float screenWidth = 1920;
float screenHeight = 1200;
float zoom = 0.5;

boolean spatial = true;
float x = 5;
float y = 5;
float xIncrement = 5;
float border = 5;
float yFinal = 0;

float[][] history;

boolean shaping = false;

// positions in the array
static final int TIME = 0;
static final int TYPE = 1;
static final int NUMBER = 2;
static final int CLICKSTATE = 3;
static final int POINTX = 4;
static final int POINTY = 5;
static final int COMMAND = 6;
static final int OPTION = 7;
static final int CONTROL = 8;
static final int SHIFT = 9;
static final int FN = 10;
static final int WHEELDELTA = 11;

// event types
static final int LDOWN = 1;
static final int LUP = 2;
static final int RDOWN = 3;
static final int RUP = 4;
static final int MOVE = 5;
static final int LDRAG = 6;
static final int RDRAG = 7;
static final int KEYDOWN = 10;
static final int KEYUP = 11;
static final int WHEEL = 22;

boolean debug = false;

void setup ()
{
    size((int) (screenWidth*zoom), (int) (screenHeight*zoom));
    smooth();
}

void draw ()
{
    background(255);
    stroke(0, 50);
    noFill();
    loadHistory();
    noLoop();
}

void loadHistory ()
{
    //String loadPath = selectInput();
    String loadPath = "sample.log";
    if (loadPath == null) {
        if (debug) println("No output file selected.");
    } else {
        if (debug) println(loadPath);
        String lines[] = loadStrings(loadPath);
        if (lines == null) {
            if (debug) println("Gah. File does not exist.");
        } else {
            parseStringHistory(lines);
            replayHistory();
        }
    }
}

void parseStringHistory (String[] stringHistory)
{
    if (debug) println("Parsing history log file.");
    history = new float[stringHistory.length][12];
    String[] s;
    
    for (int i = 0; i < stringHistory.length; i++) {
        s = stringHistory[i].split(" ");
        
        // we don’t want no comments
        if (!s[0].equals("//")) {
            for (int j = 0; j < s.length; j++) {
                history[i][j] = Float.parseFloat(s[j]);
            }
        }
    }
    stringHistory = null;
    if (debug) println("Done parsing history log file.");
}

void replayHistory ()
{
    if (debug) println("Replaying history.");
    for (int i = 0; i < history.length; i++) {
        drawMouseTrail(i);
    }
    stroke(0);
    for (int i = 0; i < history.length; i++) {
        drawDetails(i);
    }
    if (debug) println("Done replaying history.");
}

void drawDetails (int l)
{
    if (history[l][TYPE] == LDOWN) {
        if (history[l+1][TYPE] == LDRAG) {
            // drag start
            int i = l+1;
            float angle = 0;
            while (history[i][TYPE] == LDRAG && i < l + 15) {
                angle += getAngle(l, i);
                i++;
            }
            angle /= i-l;
            translate(history[l][POINTX]*zoom, history[l][POINTY]*zoom);
            rotate(angle);
            line(0, -3, 0, 3);
            resetMatrix();
        } else {
            // left click
            line(history[l][POINTX]*zoom-2, history[l][POINTY]*zoom-2, history[l][POINTX]*zoom+2, history[l][POINTY]*zoom+2);
            line(history[l][POINTX]*zoom+2, history[l][POINTY]*zoom-2, history[l][POINTX]*zoom-2, history[l][POINTY]*zoom+2);
        }
    } else if (history[l][TYPE] == LUP) {
        if (history[l-1][TYPE] == LDRAG) {
            // drag end
            int i = l-1;
            float angle = 0;
            while (history[i][TYPE] == LDRAG && i > l - 30) {
                angle += getAngle(i, l);
                i--;
            }
            angle /= l-i;
            translate(history[l][POINTX]*zoom, history[l][POINTY]*zoom);
            rotate(angle);
            line(0, 0, -3, -3);
            line(0, 0, -3, 3);
            resetMatrix();
        }
    }
}

void drawMouseTrail (int l)
{
    if (!shaping && l < history.length-2 && (history[l+1][TYPE] == MOVE || history[l+1][TYPE] == LDRAG)) {
        if (history[l+1][TYPE] == MOVE) {
            stroke(0, 50);
        } else if (history[l+1][TYPE] == LDRAG) {
            stroke(0, 128);
        }
        beginShape();
        shaping = true;
        if (debug) println("Beginning shape");
    }
    
    if (history[l][TYPE] == MOVE || history[l][TYPE] == LDRAG) {
        vertex(history[l][POINTX]*zoom, history[l][POINTY]*zoom);
        if (debug) println(history[l][TIME]);
    }
    
    if (shaping && (l == history.length-2 || (history[l+1][TYPE] != MOVE && history[l+1][TYPE] != LDRAG))) {
        endShape();
        shaping = false;
        if (debug) println("Ending shape");
    }
}

float getAngle(int a, int b)
{
    PVector o = new PVector(history[a][POINTX], history[a][POINTY]);
    PVector c = new PVector(history[b][POINTX], history[b][POINTY]);
    c.sub(o);
    return c.heading2D();
}