import java.awt.*;
import java.awt.geom.Point2D;
import processing.pdf.*;

Point2D.Float old = new Point2D.Float(0, 0);
Point2D.Float current = new Point2D.Float(0, 0);

float screenWidth = 1920;
float screenHeight = 1200;
float zoom = 0.5;

ArrayList history = new ArrayList();

boolean spatial = true;
float x = 5;
float y = 5;
float xIncrement = 5;
float border = 5;
float yFinal = 0;

boolean dragging = false;
boolean draggingInPreviousFrame = false;
float tempRotation = 0;

boolean record = true;

static final int OLDPOINT = 0;
static final int CURRENTPOINT = 1;
static final int TYPE = 2;
static final int WHEELDELTA = 3;

static final int SEVENTID = 0;
static final int SOLDPOINTX = 1;
static final int SOLDPOINTY = 2;
static final int SCURRENTPOINTX = 3;
static final int SCURRENTPOINTY = 4;
static final int STYPE = 5;
static final int SWHEELDELTA = 6;

static final int MOVE = 0;
static final int LEFTCLICK = 1;
static final int RIGHTCLICK = 2;
static final int DOUBLECLICK = 3;
static final int DRAG = 4;
static final int WHEEL = 5;

PGraphicsPDF pdf;

void setup ()
{
    size((int) (screenWidth*zoom), (int) (screenHeight*zoom));
    smooth();
    background(255);
    current.setLocation(MouseInfo.getPointerInfo().getLocation());
    
    pdf = (PGraphicsPDF) createGraphics(width, height, PDF, "/Users//julian/Desktop/pause-resume.pdf");
    beginRecord(pdf);
    
    addMouseWheelListener(new java.awt.event.MouseWheelListener () { 
        public void mouseWheelMoved(java.awt.event.MouseWheelEvent event) { 
            mouseWheel(event.getWheelRotation());
        }
    });
}

void draw ()
{
    if (record) {
        old.setLocation(current);
        current.setLocation(MouseInfo.getPointerInfo().getLocation());
    
        if (!current.equals(old)) {
            drawMouseMove();
        }
    }
}

void makeHistory (int type, int delta)
{
    Object[] hTemp = {old.clone(), current.clone(), type, delta};
    history.add(hTemp);
}

void clearHistory ()
{
    history.clear();
}

String writeHistory ()
{
    println("Writing history");
    StringBuilder l = new StringBuilder();
    Object[] h;
    Point2D.Float o;
    Point2D.Float c;
    for (int i = 0; i < history.size(); i++) {
        println(i);
        h = (Object[]) history.get(i);
        o = (Point2D.Float) h[OLDPOINT];
        c = (Point2D.Float) h[CURRENTPOINT];
        l.append(i + " " + o.x + " " + o.y + " " + c.x + " " + c.y + " " + h[TYPE] + " " + h[WHEELDELTA] + "\n");
    }
    println("Done writing history");
    return l.toString();
}

void saveHistory ()
{
    println("Saving…");
    String savePath = selectOutput();
    println(savePath);
    if (savePath == null) {
        println("No output file selected.");
    } else {
        println(savePath);
        PrintWriter writer = createWriter(savePath);
        if (writer == null) {
            println("Gah.");
        } else {
            writer.write(writeHistory());
            writer.close();
        }
    }
    println("Done saving.");
}

void loadHistory ()
{
    stopRecording();
    String loadPath = selectInput();
    if (loadPath == null) {
        println("No output file selected.");
    } else {
        println(loadPath);
        String lines[] = loadStrings(loadPath);
        if (lines == null) {
            println("Gah. File does not exist.");
        } else {
            history = parseStringHistory(lines);
            replayHistory();
        }
    }
}

ArrayList parseStringHistory (String[] stringHistory)
{
    ArrayList newHistory = new ArrayList();
    String[] s;    
    
    for (int i = 0; i < stringHistory.length; i++) {
        s = stringHistory[i].split(" ");

        Point2D.Float o = new Point2D.Float(
            Float.parseFloat(s[SOLDPOINTX]),
            Float.parseFloat(s[SOLDPOINTY])
        );
        Point2D.Float c = new Point2D.Float(
            Float.parseFloat(s[SCURRENTPOINTX]),
            Float.parseFloat(s[SCURRENTPOINTY])
        );
        
        Object[] h = {o, c, Integer.parseInt(s[STYPE]), Integer.parseInt(s[SWHEELDELTA])};
        println(h);
        newHistory.add(h);
    }
    return newHistory;
}

void replayHistory ()
{
    println("Replaying history");
    Object[] h;
    background(255);
    
    for (int i = 0; i < history.size(); i++) {
        println(i);
        h = (Object[]) history.get(i);
        old = (Point2D.Float) h[OLDPOINT];
        current = (Point2D.Float) h[CURRENTPOINT];
        switch ((Integer) h[TYPE]) {
            case MOVE:
                drawMouseMove();
                break;
            case LEFTCLICK:
                drawLeftClick();
                break;
            case DOUBLECLICK:
                drawDoubleClick();
                break;
            case DRAG:
                drawMouseMove();
                break;
            case WHEEL:
                drawWheel((Integer) h[WHEELDELTA]);
                break;
        }
    }
    println("Done!");
}

void startRecording ()
{
    record = true;
    beginRecord(pdf);
}

void stopRecording ()
{
    record = false;
    endRecord();
}

void keyPressed ()
{
    switch (key) {
        // clear
        case 'c':
            background(255);
            clearHistory();
            break;
        // left click
        case 'l':
            drawLeftClick();
            makeHistory(LEFTCLICK, 0);
            break;
        // double click
        case 'd':
            drawDoubleClick();
            makeHistory(DOUBLECLICK, 0);
            break;
        case 'r':
            if (record) {
                stopRecording();
            } else {
                startRecording();
            }
            break;
        case 'a':
            dragging = !dragging;
            break;
        // save
        case 's':
            saveHistory();
            break;
        // load
        case 'o':
            loadHistory();
            break;
        case 'q':
            stopRecording();
            exit();
    }
    draggingInPreviousFrame = false;
}

void drawWheel (int delta)
{
    if (!spatial) {
        noSmooth();
        stroke(0, 67);
        
        if (y + Math.abs(delta) > height - border*2) {
            yFinal = y + Math.abs(delta) - (height - border*2);
            // have to cast to int when drawing the rect, or else…
            rect((int) x-1, (int) y, 3, (int) Math.abs(delta) - yFinal);
            y = 5;
            x += xIncrement;
        } else {
            yFinal = Math.abs(delta);
        }
        rect((int) x-1, (int) y, 3, (int) yFinal);
        
        /*
        if (stringHistory.size() > 0) {
            String[] temp = ((String) stringHistory.get(eventID-1)).split(" ");
            if (temp[1].equals("w")) {
                noStroke();
                fill(255);
                rect((int) x-1, (int) y-1, 3, 2);
                noFill();
            }
        }
        */
        
        y += yFinal;
        smooth();
    }
}

void drawDoubleClick ()
{
    noSmooth();
    if (spatial) {
        stroke(0, 50);
        line(current.x*zoom-2, current.y*zoom-2, current.x*zoom+2, current.y*zoom+2);
        line(current.x*zoom+2, current.y*zoom-2, current.x*zoom-2, current.y*zoom+2);
        line(current.x*zoom, current.y*zoom-2, current.x*zoom, current.y*zoom+2);
        line(current.x*zoom+2, current.y*zoom, current.x*zoom-2, current.y*zoom);
    } else {
        stroke(0, 67);
        if (y > height - border*2 - 9) {
            y = 5;
            x += xIncrement;
        }
        y += 5;
        line(x-2, y-2, x+2, y+2);
        line(x+2, y-2, x-2, y+2);
        line(x, y-2, x, y+2);
        line(x+2, y, x-2, y);
        y += 5;        
    }
    smooth();
}

void drawLeftClick ()
{
    noSmooth();
    if (spatial) {
        stroke(0, 50);
        line(current.x*zoom-2, current.y*zoom-2, current.x*zoom+2, current.y*zoom+2);
        line(current.x*zoom+2, current.y*zoom-2, current.x*zoom-2, current.y*zoom+2);
    } else {
        stroke(0, 67);
        if (y > height - border*2 - 5) {
            y = 5;
            x += xIncrement;
        }
        y += 3;
        line(x-2, y-2, x+2, y+2);
        line(x+2, y-2, x-2, y+2);
        y += 3;
    }
    smooth();
}

void drawMouseMove ()
{
    if (spatial) {
        stroke(0, 33);
        line(old.x*zoom, old.y*zoom, current.x*zoom, current.y*zoom);
    } else {
        stroke(0, 50);
        if (y + (float) old.distance(current)*zoom > height - border*2) {
            yFinal = y + (float) old.distance(current)*zoom - (height - border*2);
            line(x, y, x, y + (float) old.distance(current)*zoom - yFinal);
            y = 5;
            x += xIncrement;
        } else {
            yFinal = (float) old.distance(current)*zoom;
        }
        line(x, y, x, y + yFinal);
        y += yFinal;
    }
    
    if ((keyPressed == true && key == CODED && keyCode == SHIFT) || dragging) {
        // dragging starts
        if (!draggingInPreviousFrame) {
            tempRotation = getAngle(old, current);
            translate(current.x*zoom, current.y*zoom);
            rotate(tempRotation + radians(90));
            stroke(0, 67);
            line(3, 0, -3, 0);
            resetMatrix();
        }
        draggingInPreviousFrame = true;
        if (record) makeHistory(DRAG, 0);
    } else {
        // dragging ends
        if (draggingInPreviousFrame) {
            tempRotation = getAngle(old, current);
            translate(current.x*zoom, current.y*zoom);
            rotate(tempRotation + radians(90));
            stroke(0, 67);
            line(0, 0, -3, 3);
            line(0, 0, 3, 3);
            resetMatrix();
        }
        draggingInPreviousFrame = false;
        if (record) makeHistory(MOVE, 0);
    }
}

void mouseWheel (int delta)
{
    draggingInPreviousFrame = false;
    drawWheel(delta);
    if (record) makeHistory(WHEEL, delta);
}

float getAngle(Point2D.Float old, Point2D.Float current)
{
    PVector o = new PVector(old.x, old.y);
    PVector c = new PVector(current.x, current.y);
    c.sub(o);
    return c.heading2D();
}