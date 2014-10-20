package web;

import static tsdb.util.AssumptionCheck.throwNull;

import java.awt.Color;
import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.geom.Rectangle2D;
import java.awt.image.BufferedImage;

public class TimeSeriesPainterGraphics2D implements TimeSeriesPainter {
	
	Graphics2D gc;
	
	float minX;
	float minY;
	float maxX;
	float maxY;
	
	Color color_black = new Color(0,0,0);
	Color color_grey = new Color(190,190,190);
	Color color_light_blue = new Color(220,220,255);
	
	public TimeSeriesPainterGraphics2D(BufferedImage bufferedImage) {
		this(bufferedImage.createGraphics(),0,0,bufferedImage.getWidth(),bufferedImage.getHeight());
	}
	
	public TimeSeriesPainterGraphics2D(Graphics2D gc,float minX, float minY, float maxX, float maxY) {
		throwNull(gc);
		gc.setRenderingHint(RenderingHints.KEY_RENDERING, RenderingHints.VALUE_RENDER_QUALITY);
		//gc.setRenderingHint( RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);		
		//gc.setRenderingHint(RenderingHints.KEY_TEXT_ANTIALIASING, RenderingHints.VALUE_TEXT_ANTIALIAS_ON);
		gc.setRenderingHint(RenderingHints.KEY_TEXT_ANTIALIASING, RenderingHints.VALUE_TEXT_ANTIALIAS_LCD_HRGB);
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
	public void fillRect(float xMin, float yMin, float xMax, float yMax) {
		gc.fillRect((int)xMin, (int)yMin, (int)(xMax-xMin), (int)(yMax-yMin));
	}

	@Override
	public void setColorValueLineTemperature() {
		gc.setColor(new Color(220, 0, 0));
	}
	
	@Override
	public void setColorValueLineTemperatureSecondary() {
		gc.setColor(new Color(156,232,17));
	}

	@Override
	public void setColorConnectLineTemperature() {
		gc.setColor(new Color(220,180,180));		
	}
	
	@Override
	public void setColorConnectLineTemperatureSecondary() {
		gc.setColor(new Color(132,150,99));		
	}
	
	@Override
	public void setColorValueLineUnknown() {
		gc.setColor(color_black);
	}
	
	@Override
	public void setColorValueLineUnknownSecondary() {
		gc.setColor(new Color(156,232,17));
	}

	@Override
	public void setColorConnectLineUnknown() {
		gc.setColor(color_grey);		
	}
	
	@Override
	public void setColorConnectLineUnknownSecondary() {
		gc.setColor(new Color(132,150,99));		
	}
	
	@Override
	public void setColorRectWater() {
		gc.setColor(new Color(0, 0, 200));		
	}
	
	@Override
	public void setColorRectWaterSecondary() {
		gc.setColor(new Color(156,232,17));		
	}

	@Override
	public void setColorAxisLine() {
		gc.setColor(color_grey);		
	}

	@Override
	public void setColorZeroLine() {
		gc.setColor(color_black);		
	}

	@Override
	public void setColorYScaleLine() {
		gc.setColor(color_light_blue);		
	}

	@Override
	public void setColorYScaleText() {
		gc.setColor(color_black);		
	}

	@Override
	public void drawText(String text, float x, float y, PosHorizontal posHorizontal, PosVerical posVerical) {
		Rectangle2D rect = gc.getFontMetrics().getStringBounds(text, gc);		
		float xPos;
		switch(posHorizontal) {
		case LEFT:
			xPos = (float)(x-rect.getMinX());
			break;
		case CENTER:
			xPos = (float)(x-rect.getMinX()-(rect.getMaxX()-rect.getMinX())/2);
			break;
		case RIGHT:
			xPos = (float)(x-rect.getMaxX());
			break;
		default:
			throw new RuntimeException();				
		}
		float yPos;
		switch(posVerical) {
		case TOP:
			yPos = (float)(y-rect.getMinY());
			break;
		case CENTER:
			yPos = (float)(y-rect.getMinY()-(rect.getMaxY()-rect.getMinY())/2);
			break;
		case BOTTOM:
			yPos = (float)(y-rect.getMaxY());
			break;
		default:
			throw new RuntimeException();		
		}		
		gc.drawString(text, xPos, yPos);		
	}

	@Override
	public void setColorXScaleYearText() {
		gc.setColor(new Color(0,0,0));		
	}

	@Override
	public void setColorXScaleYearLine() {
		gc.setColor(new Color(220-100,220-100,255-100));	
	}

	@Override
	public void setColorXScaleMonthText() {
		gc.setColor(new Color(100,100,100));
		
	}

	@Override
	public void setColorXScaleMonthLine() {
		gc.setColor(new Color(220,220,255));		
	}

	@Override
	public void setColorXScaleDayLine() {
		gc.setColor(new Color(240,240,255));		
	}

	@Override
	public void setColorXScaleDayText() {
		gc.setColor(new Color(150,150,150));		
	}

}
