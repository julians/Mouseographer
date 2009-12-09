import java.awt.*;
import java.awt.geom.Point2D;

Point2D.Float old = new Point2D.Float(0, 0);
Point2D.Float current = new Point2D.Float(0, 0);

float screenWidth = 1920;
float screenHeight = 1200;
float zoom = 0.5;

ArrayList history = new ArrayList();
int eventID = 0;

boolean spatial = true;
float x = 5;
float y = 5;
float xIncrement = 5;
float border = 5;
float yFinal = 0;

void setup ()
{
    size((int) (screenWidth*zoom), (int) (screenHeight*zoom));
    smooth();
    background(255);
    current.setLocation(MouseInfo.getPointerInfo().getLocation());
    
    addMouseWheelListener(new java.awt.event.MouseWheelListener () { 
        public void mouseWheelMoved(java.awt.event.MouseWheelEvent event) { 
            mouseWheel(event.getWheelRotation());
        }
    });
}

void draw ()
{
    old.setLocation(current);
    current.setLocation(MouseInfo.getPointerInfo().getLocation());
    
    if (!current.equals(old)) {
        drawMouseMove();
        history.add(eventID + " m " + old.x + " " + old.y + " " + current.x + " " + current.y);
        eventID++;
    }
}

void keyPressed ()
{
    switch (key) {
        // clear
        case 'c':
            background(255);
            history.clear();
            break;
        // left click
        case 'l':
            drawLeftClick();
            history.add(eventID + " l " + old.x + " " + old.y + " " + current.x + " " + current.y);
            eventID++;
            break;
        // double click
        case 'd':
            drawDoubleClick();
            history.add(eventID + " d " + old.x + " " + old.y + " " + current.x + " " + current.y);
            eventID++;
            break;
        // save
        case 's':
            String savePath = selectOutput();
            if (savePath == null) {
                println("No output file selected.");
            } else {
                println(savePath);
                PrintWriter writer = createWriter(savePath);
                if (writer == null) {
                    println("Gah.");
                } else {
                    for (int i = 0; i < history.size(); i++) {
                        writer.write((String) history.get(i) + "\n");
                    }
                    writer.close();
                }
            }
    }
}

void drawWheel (int delta)
{
    if (spatial) {
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
        
        y += yFinal;
        smooth();
    }
}

void drawDoubleClick ()
{
    noSmooth();
    if (spatial) {
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
    } else {
        stroke(0, 50);
        line(current.x*zoom-2, current.y*zoom-2, current.x*zoom+2, current.y*zoom+2);
        line(current.x*zoom+2, current.y*zoom-2, current.x*zoom-2, current.y*zoom+2);
        line(current.x*zoom, current.y*zoom-2, current.x*zoom, current.y*zoom+2);
        line(current.x*zoom+2, current.y*zoom, current.x*zoom-2, current.y*zoom);
    }
    smooth();
}

void drawLeftClick ()
{
    noSmooth();
    if (spatial) {
        stroke(0, 67);
        if (y > height - border*2 - 5) {
            y = 5;
            x += xIncrement;
        }
        y += 3;
        line(x-2, y-2, x+2, y+2);
        line(x+2, y-2, x-2, y+2);
        y += 3;
    } else {
        stroke(0, 50);
        line(current.x*zoom-2, current.y*zoom-2, current.x*zoom+2, current.y*zoom+2);
        line(current.x*zoom+2, current.y*zoom-2, current.x*zoom-2, current.y*zoom+2);
    }
    smooth();
}

void drawMouseMove ()
{
    if (spatial) {
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
    } else {
        stroke(0, 33);
        line(old.x*zoom, old.y*zoom, current.x*zoom, current.y*zoom);            
    }
}

void mouseWheel (int delta)
{
    drawWheel(delta);
    history.add(eventID + " w " + old.x + " " + old.y + " " + current.x + " " + current.y + " " + delta);
    eventID++;
}