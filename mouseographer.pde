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

static final int TRAIL = 94;
static final int CLICK = 95;
static final int DRAGSTART = 96;
static final int DRAGEND = 97;
static final int KEY = 98;
static final int NOTHING = 99;

boolean debug = false;

static final int SPATIAL = 0;
static final int LINEAR = 1;
static final int ORDERED = 2;

int mode = LINEAR;

float flags = 0;
float prevFlags = 0;
int kerning = 0;
int lastStart = 0;

boolean prefOptimalPaths = false;
boolean prefDiffs = false;
boolean prefSegments = false;
boolean prefAge = false;
boolean prefWeight = false;

void setup ()
{
    size((int) (screenWidth*zoom), (int) (screenHeight*zoom));
    smooth();
    loadHistory();
}

void draw ()
{
    background(255);
    noFill();
    replayHistory();
    noLoop();
}

void loadHistory ()
{
    //String loadPath = selectInput();
    String loadPath = "matrix.log";
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
        stroke(0, 50);
        for (int i = 0; i < history.length; i++) {
            if (prefSegments) {
                drawMouseTrailSegment(i, prefAge, prefWeight);
            } else {
                drawMouseTrail(i, prefDiffs, prefOptimalPaths);
            }
        }
        stroke(0, 128);
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
    } else {
        switch (key) {
            case 'o':
                prefOptimalPaths = !prefOptimalPaths;
                break;
            case 'd':
                prefDiffs = !prefDiffs;
                break;
            case 's':
                prefSegments = !prefSegments;
                break;
            case 'a':
                prefAge = !prefAge;
                break;
            case 'w':
                prefWeight = !prefWeight;
                break;
        }
        loop();
    }
}

void drawLinear ()
{
    float distance = 0;
    int drawn = NOTHING;
    
    for (int l = 1; l < history.length; l++) {
        // shift, command, alt, etc.
        prevFlags = flags;
        flags = 0;
        for (int i = COMMAND; i < FN+1; i++) {
            flags += history[l][i];
        }
        
        // mouse trail
        kerning = -3;
        if (history[l][TYPE] != MOVE && history[l][TYPE] != LDRAG && distance > 0) {
            while (distance > 2) {
                if (x != border) x += 3;
                if (distance > width - border - x) {
                    if (history[l-1][TYPE] == LDRAG) {
                        stroke(0, 128);
                    } else {
                        stroke(0, 50);
                    }
                    line((int) x, y, (int) (width - border), y);
                    if (prevFlags > 0) {
                        stroke(0, 24*prevFlags);
                        line((int) x + kerning, y-2, (int) (width - border), y-2);
                    }
                    y += yIncrement;
                    distance -= width - border - x;
                    x = border;
                    drawn = NOTHING;
                } else {
                    if (history[l-1][TYPE] == LDRAG) {
                        stroke(0, 128);
                    } else {
                        stroke(0, 50);
                    }
                    line((int) x, y, (int) (x + distance), y);
                    if (prevFlags > 0) {
                        stroke(0, 24*prevFlags);
                        int wee = 0;
                        if (drawn == KEY) {
                            wee = 2;
                        }
                        line((int) x + kerning, y-2, (int) (x + distance + wee), y-2);
                    }
                    x += distance;
                    distance = 0;
                    drawn = TRAIL;
                }
                kerning = 0;
            }
            distance = 0;
        }

        if (flags > prevFlags) {
            kerning = drawn == CLICK ? 2 : 0;
            x += 3 + kerning;
            stroke(0, 128);
            rect((int) x, (int) y-2, 4, 4);
            x += 4;
            drawn = KEY;
        }
        
        if (history[l][TYPE] == LUP) {
            int g = 1;
            while (g > 0) {
                if (history[l-g][TYPE] == LDRAG) {
                    if (drawn != TRAIL) x += 3;
                    // drag end
                    stroke(0, 128);
                    if (drawn == KEY) {
                        x += 3;
                        line(x-4, y, x-1, y);
                    }
                    line((int) x, y, (int) x-3, y+2);
                    line((int) x, y, (int) x-3, y-2);
                    g = -1;
                    drawn = DRAGEND;
                } else if (history[l-g][TYPE] == LDOWN) {
                    if (drawn == CLICK) {
                        kerning = 2;
                    } else {
                        kerning = 0;
                    }
                    // left click
                    x += 3;
                    stroke(0, 128);
                    beginShape();
                    vertex((int) x+kerning, (int) y-2);
                    vertex((int) x+kerning, (int) y+2);
                    vertex((int) x+kerning+4, (int) y+2);
                    vertex((int) x+kerning, (int) y-2);
                    endShape();
                    x += 2 + kerning;
                    g = -1;
                    drawn = CLICK;
                }
                g++;
            }
        } else if (history[l][TYPE] == LDOWN) {
            if (history[l+1][TYPE] == LDRAG) {
                // drag start
                x += 3;
                if (drawn == CLICK) {
                    kerning = 2;
                } else {
                    kerning = 0;
                }
                stroke(0, 128);
                line((int) x + kerning, y + 2, (int) x + kerning, y - 2);
                x += kerning - 3;
                drawn = DRAGSTART;
            }
        }
        
        // regular typing
        if (history[l][TYPE] == KEYUP) {
           if (history[l-1][TYPE] == KEYDOWN || history[l-1][TYPE] == KEYUP || history[l-1][TYPE] == FLAGSCHANGED) {
               kerning = drawn == CLICK ? 2 : 0;
               x += 3 + kerning;
               stroke(0, 128);
               rect((int) x, (int) y-2, 4, 4);
               x += 4;
               drawn = KEY;
           } 
        }
        distance += getDistance(l, l-1) * zoom;
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
            beginShape();
            vertex((int) history[l][POINTX]*zoom, (int) history[l][POINTY]*zoom-2);
            vertex((int) history[l][POINTX]*zoom, (int) history[l][POINTY]*zoom+2);
            vertex((int) history[l][POINTX]*zoom+4, (int) history[l][POINTY]*zoom+2);
            vertex((int) history[l][POINTX]*zoom, (int) history[l][POINTY]*zoom-2);
            endShape();
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

void drawMouseTrailSegment (int l, boolean age, boolean weight)
{
    if (l > 0) {
        strokeWeight(1);
        if (age) {
            stroke(0, map(history[l][TIME], history[0][TIME], history[history.length-1][TIME], 8, 96));
        } else {
            stroke(0, 50);
        }
        if (history[l][TYPE] == MOVE) {
            line(history[l-1][POINTX]*zoom, history[l-1][POINTY]*zoom, history[l][POINTX]*zoom, history[l][POINTY]*zoom);
        } else if (history[l][TYPE] == LDRAG) {
            if (weight) {
                strokeWeight(2);
            } else {
                if (age) {
                    stroke(0, map(history[l][TIME], history[0][TIME], history[history.length-1][TIME], 96, 128));                
                } else {
                    stroke(0, 128);
                }
            }
            line(history[l-1][POINTX]*zoom, history[l-1][POINTY]*zoom, history[l][POINTX]*zoom, history[l][POINTY]*zoom);
        }
    }
}

void drawMouseTrail (int l, boolean diff, boolean optimalPath)
{
    if (!shaping && l < history.length-2 && (history[l+1][TYPE] == MOVE || history[l+1][TYPE] == LDRAG)) {
        beginShape();
        lastStart = l;
        shaping = true;
        if (debug) println("Beginning shape");
    }
    
    if (history[l][TYPE] == MOVE || history[l][TYPE] == LDRAG) {
        vertex(history[l][POINTX]*zoom, history[l][POINTY]*zoom);
        if (debug) println(history[l][TIME]);
    }
    
    if (shaping && (l == history.length-2 || (history[l+1][TYPE] != MOVE && history[l+1][TYPE] != LDRAG))) {
        if (diff) {
            vertex(history[lastStart][POINTX]*zoom, history[lastStart][POINTY]*zoom);
            fill(0, 16);
            noStroke();
        } else {
            noFill();
            if (history[l][TYPE] == MOVE) {
                stroke(0, 50);
            } else if (history[l][TYPE] == LDRAG) {
                stroke(0, 128);
            }
        }
        endShape();
        if (optimalPath) {
            if (history[l][TYPE] == MOVE) {
                stroke(0, 50);
            } else if (history[l][TYPE] == LDRAG) {
                stroke(0, 128);
            }
            line(history[lastStart][POINTX]*zoom, history[lastStart][POINTY]*zoom, history[l][POINTX]*zoom, history[l][POINTY]*zoom);
        }
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