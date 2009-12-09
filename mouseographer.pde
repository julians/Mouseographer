import java.awt.*;
import java.awt.geom.Point2D;

Point2D.Float old = new Point2D.Float(0, 0);
Point2D.Float current = new Point2D.Float(0, 0);

float screenWidth = 1920;
float screenHeight = 1200;
float zoom = 0.5;

ArrayList history = new ArrayList();

void setup ()
{
    size((int) (screenWidth*zoom), (int) (screenHeight*zoom));
    smooth();
    background(255);
    stroke(0, 33);
    current.setLocation(MouseInfo.getPointerInfo().getLocation());
    
    addMouseWheelListener(new java.awt.event.MouseWheelListener () { 
        public void mouseWheelMoved(java.awt.event.MouseWheelEvent evt) { 
            mouseWheel(evt.getWheelRotation());
        }
    });
}

void draw ()
{
    old.setLocation(current);
    current.setLocation(MouseInfo.getPointerInfo().getLocation());
    
    if (!current.equals(old)) {
        line(old.x*zoom, old.y*zoom, current.x*zoom, current.y*zoom);
        history.add("m " + old.x + " " + old.y + " " + current.x + " " + current.y);
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
            stroke(0, 50);
            line(current.x*zoom-2, current.y*zoom-2, current.x*zoom+2, current.y*zoom+2);
            line(current.x*zoom+2, current.y*zoom-2, current.x*zoom-2, current.y*zoom+2);
            stroke(0, 33);
            history.add("l " + old.x + " " + old.y + " " + current.x + " " + current.y);
            break;
        // double click
        case 'd':
            stroke(0, 50);
            line(current.x*zoom-2, current.y*zoom-2, current.x*zoom+2, current.y*zoom+2);
            line(current.x*zoom+2, current.y*zoom-2, current.x*zoom-2, current.y*zoom+2);
            line(current.x*zoom, current.y*zoom-2, current.x*zoom, current.y*zoom+2);
            line(current.x*zoom+2, current.y*zoom, current.x*zoom-2, current.y*zoom);
            stroke(0, 33);
            history.add("d " + old.x + " " + old.y + " " + current.x + " " + current.y);
            break;
        // save
        case 's':
            String savePath = selectOutput();  // Opens file chooser
            if (savePath == null) {
                println("No output file was selected...");
            } else {
                println(savePath);
                PrintWriter writer = createWriter(savePath);
                if (writer == null) {
                    println("gah");
                } else {
                    for (int i = 0; i < history.size(); i++) {
                        writer.write((String) history.get(i) + "\n");
                    }
                    writer.close();
                }
            }
    }
}

void mouseWheel (int delta)
{
    println(delta); 
    history.add("w:" + delta + " " + old.x + " " + old.y + " " + current.x + " " + current.y);
}