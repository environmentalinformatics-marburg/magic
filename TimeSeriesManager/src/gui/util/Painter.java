package gui.util;



import org.eclipse.swt.graphics.GC;
import org.eclipse.swt.graphics.Point;

public class Painter {
	
	public enum PosHorizontal {LEFT,CENTER,RIGHT};
	public enum PosVerical {TOP,CENTER,BOTTOM};

	public static void drawText(String text, GC gc, int x, int y, PosHorizontal posHorizontal, PosVerical posVerical) {
		Point point = gc.textExtent(text);
		int xPos;
		switch(posHorizontal) {
		case LEFT:
			xPos = x;
			break;
		case CENTER:
			xPos = x-point.x/2;
			break;
		case RIGHT:
			xPos = x-point.x;
			break;
		default:
			throw new RuntimeException();				
		}
		int yPos;
		switch(posVerical) {
		case TOP:
			yPos = y;
			break;
		case CENTER:
			yPos = y-point.y/2;
			break;
		case BOTTOM:
			yPos = y-point.y;
			break;
		default:
			throw new RuntimeException();		
		}
		gc.drawText(text, xPos, yPos);
	}

}
