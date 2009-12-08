import java.awt.*;
import java.awt.geom.Point2D;

Point2D.Float old = new Point2D.Float(0, 0);
Point2D.Float current = new Point2D.Float(0, 0);

float screenWidth = 1920;
float screenHeight = 1200;
float zoom = 0.5;

void setup ()
{
    size((int) (screenWidth*zoom), (int) (screenHeight*zoom));
    smooth();
    background(255);
    stroke(0, 33);
    current.setLocation(MouseInfo.getPointerInfo().getLocation());
}

void draw ()
{
    old.setLocation(current);
    current.setLocation(MouseInfo.getPointerInfo().getLocation());
    
    if (!current.equals(old)) line(old.x*zoom, old.y*zoom, current.x*zoom, current.y*zoom);
}

void keyPressed ()
{
    // press c to clear screen
    if (key == 'c') background(255);
}