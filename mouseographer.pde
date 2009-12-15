float screenWidth = 1920;
float screenHeight = 1200;
float zoom = 0.5;

float x = 10;
float y = 10;
float yIncrement = 8;
float border = 10;

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
static final int FLAGSCHANGED = 12;
static final int WHEEL = 22;

boolean debug = false;

static final int SPATIAL = 0;
static final int LINEAR = 1;
static final int ORDERED = 2;

int mode = LINEAR;

float flags = 0;
float prevFlags = 0;
int kerning = 0;

void setup ()
{
    size((int) (screenWidth*zoom), (int) (screenHeight*zoom));
    smooth();
    loadHistory();
}

void draw ()
{
    background(255);
    stroke(0, 50);
    noFill();
    replayHistory();
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
        }
    }
}

void parseStringHistory (String[] stringHistory)
{
    if (debug) println("Parsing history log file.");
    float[][] tHistory = new float[stringHistory.length][12];
    String[] s;
    
    int k = 0;
    for (int i = 0; i < stringHistory.length; i++) {
        s = stringHistory[i].split(" ");
        
        // we don’t want no comments
        if (!s[0].equals("//")) {
            for (int j = 0; j < s.length; j++) {
                tHistory[k][j] = Float.parseFloat(s[j]);
            }
            k++;
        }
    }
    stringHistory = null;
    
    // the tHistory array is bigger than it needs to be
    // and we don’t want to loop through empty elements later,
    // therefor we copy it into a dapper new array with a snug fit
    history = new float[k][12];
    System.arraycopy(tHistory, 0, history, 0, k);
    if (debug) println("Done parsing history log file.");
}

void replayHistory ()
{
    if (debug) println("Replaying history.");
    if (mode == SPATIAL) {
        for (int i = 0; i < history.length; i++) {
            drawMouseTrail(i);
        }
        stroke(0);
        for (int i = 0; i < history.length; i++) {
            drawDetails(i);
        }        
    } else if (mode == LINEAR) {
        drawLinear();
    }
    if (debug) println("Done replaying history.");
}

void keyPressed ()
{
    if (key == CODED && (keyCode == LEFT || keyCode == RIGHT)) {
        if (keyCode == LEFT) {
            mode--;
            if (mode < 0) mode = 2;
        } else {
            mode++;
            if (mode > 2) mode = 0;
        }
        if (debug) println(mode);
        loop();
    }
}

void drawLinear ()
{
    float blah = 0;
    
    for (int l = 1; l < history.length; l++) {      
        // shift, command, alt, etc.
        prevFlags = flags;
        flags = 0;
        for (int i = COMMAND; i < FN+1; i++) {
            flags += history[l][i];
        }
        
        // mouse trail
        kerning = -3;
        if (history[l][TYPE] != MOVE && history[l][TYPE] != LDRAG && blah > 0) {
            while (blah > 0) {
                if (blah > width - border - x) {
                    if (history[l-1][TYPE] == MOVE) {
                        stroke(0, 50);
                    } else {
                        stroke(0, 128);
                    }
                    line((int) x, y, (int) (width - border), y);
                    if (prevFlags > 0) {
                        stroke(0, 24*prevFlags);
                        line((int) x + kerning, y-2, (int) (width - border), y-2);
                    }
                    y += yIncrement;
                    blah -= width - border - x;
                    x = border;
                } else {
                    if (history[l-1][TYPE] == MOVE) {
                        stroke(0, 50);
                    } else {
                        stroke(0, 128);
                    }
                    line((int) x, y, (int) (x + blah), y);
                    if (prevFlags > 0) {
                        stroke(0, 24*prevFlags);
                        line((int) x + kerning, y-2, (int) (x + blah), y-2);
                    }
                    x += blah + 3;
                    blah = 0;
                }
                kerning = 0;
            }
            blah = 0;
        }

        if (flags > prevFlags) {
            kerning = (history[l-2][TYPE] == LDOWN && history[l-1][TYPE] != LDRAG) ? 2 : 0;
            stroke(0, 128);
            rect((int) x + kerning, (int) y-2, 4, 4);
            x += 7;
        }
        
        if (history[l][TYPE] == LUP) {
            if (history[l-1][TYPE] == LDRAG) {
                // drag end
                stroke(0, 128);
                line((int) x-3, y, (int) x-6, y+2);
                line((int) x-3, y, (int) x-6, y-2);
            } else if (history[l-1][TYPE] == LDOWN) {
                if (history[l-2][TYPE] == LUP && history[l-3][TYPE] == LDOWN) {
                    kerning = 3;
                } else {
                    kerning = 0;
                }
                // left click
                stroke(0, 128);
                line((int) x-2+kerning, y-2, (int) x+2+kerning, y+2);
                line((int) x+2+kerning, y-2, (int) x-2+kerning, y+2);
                x += 3 + kerning;
            }
        } else if (history[l][TYPE] == LDOWN) {
            if (history[l+1][TYPE] == LDRAG) {
                // drag start
                if (history[l-1][TYPE] == LUP && history[l-2][TYPE] == LDOWN) {
                    kerning = 2;
                } else {
                    kerning = 0;
                }
                stroke(0, 128);
                line((int) x + kerning, y + 2, (int) x + kerning, y - 2);
                x += kerning;
            }
        }
        
        // regular typing
        if (history[l][TYPE] == KEYUP) {
           if (history[l-1][TYPE] == KEYDOWN || history[l-1][TYPE] == KEYUP) {
               stroke(0, 128);
               rect((int) x + 2, (int) y-2, 4, 4);
               x += 7;
           } 
        }
        blah += getDistance(l, l-1) * zoom;
    }
    
    x = border;
    y = border;
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
    } else if (history[l][TYPE] == LUP && l > 0) {
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

float getDistance (int a, int b)
{
    PVector o = new PVector(history[a][POINTX], history[a][POINTY]);
    PVector c = new PVector(history[b][POINTX], history[b][POINTY]);
    return PVector.dist(o, c);
}