package web;

import static tsdb.util.AssumptionCheck.throwNull;

import java.awt.Color;
import java.awt.Graphics2D;
import java.awt.image.BufferedImage;

public class TimeSeriesPainterGraphics2D implements TimeSeriesPainter {
	
	Graphics2D gc;
	
	float minX;
	float minY;
	float maxX;
	float maxY;
	
	Color color_black = new Color(0,0,0);
	Color color_grey = new Color(190,190,190);
	
	public TimeSeriesPainterGraphics2D(BufferedImage bufferedImage) {
		this(bufferedImage.createGraphics(),0,0,bufferedImage.getWidth(),bufferedImage.getHeight());
	}
	
	public TimeSeriesPainterGraphics2D(Graphics2D gc,float minX, float minY, float maxX, float maxY) {
		throwNull(gc);
		this.gc = gc;
		this.minX = minX;
		this.minY = minY;
		this.maxX = maxX;
		this.maxY = maxY;
	}

	@Override
	public float getMinX() {
		return minX;
	}

	@Override
	public float getMinY() {
		return minY;
	}

	@Override
	public float getMaxX() {
		return maxX;
	}

	@Override
	public float getMaxY() {
		return maxY;
	}

	@Override
	public void setColor(int r, int g, int b) {
		gc.setColor(new Color(r,g,b));
		
	}

	@Override
	public void drawLine(float x0, float y0, float x1, float y1) {
		gc.drawLine((int)x0, (int)y0, (int)x1, (int)y1);
		
	}

	@Override
	public void setColorValueLine() {
		gc.setColor(color_black);
		
	}

	@Override
	public void setColorConnectLine() {
		gc.setColor(color_grey);		
	}
}
