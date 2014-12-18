package tsdb.util.gui;

import static tsdb.util.AssumptionCheck.throwNull;

import java.awt.geom.Rectangle2D;

import tsdb.util.gui.TimeSeriesPainter.PosHorizontal;
import tsdb.util.gui.TimeSeriesPainter.PosVerical;
import javafx.geometry.VPos;
import javafx.scene.canvas.Canvas;
import javafx.scene.canvas.GraphicsContext;
import javafx.scene.paint.Color;
import javafx.scene.text.TextAlignment;

@Deprecated
public class TimeSeriesPainterFX implements TimeSeriesPainter {
	
	private final GraphicsContext gc;
	
	float minX;
	float minY;
	float maxX;
	float maxY;
	
	Color color_black = Color.rgb(0,0,0);
	Color color_grey = Color.rgb(190,190,190);
	Color color_light_blue = Color.rgb(220,220,255);
	
	public TimeSeriesPainterFX(Canvas canvas) {
		throwNull(canvas);
		this.gc = canvas.getGraphicsContext2D();
		minX = 0;
		minY = 0;
		maxX = (float) canvas.getWidth();
		maxY = (float) canvas.getHeight();
		gc.setLineWidth(1d);
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
		gc.setFill(Color.rgb(r,g,b));
		gc.setStroke(Color.rgb(r,g,b));
	}

	@Override
	public void drawLine(float x0, float y0, float x1, float y1) {
		gc.strokeLine(x0+0.5, y0+0.5, x1+0.5, y1+0.5);
		
	}

	@Override
	public void fillRect(float xMin, float yMin, float xMax, float yMax) {
		gc.fillRect((int)xMin, (int)yMin, (int)(xMax-xMin), (int)(yMax-yMin));
	}

	@Override
	public void setColorValueLineTemperature() {
		gc.setStroke(Color.rgb(220, 0, 0));
	}

	@Override
	public void setColorValueLineTemperatureSecondary() {
		gc.setStroke(Color.rgb(156,232,17));
	}

	@Override
	public void setColorConnectLineTemperature() {
		gc.setStroke(Color.rgb(220,180,180));		
	}

	@Override
	public void setColorConnectLineTemperatureSecondary() {
		gc.setStroke(Color.rgb(132,150,99));		
	}

	@Override
	public void setColorValueLineUnknown() {
		gc.setStroke(color_black);
	}

	@Override
	public void setColorValueLineUnknownSecondary() {
		gc.setStroke(Color.rgb(156,232,17));
	}

	@Override
	public void setColorConnectLineUnknown() {
		gc.setStroke(color_grey);		
	}

	@Override
	public void setColorConnectLineUnknownSecondary() {
		gc.setStroke(Color.rgb(132,150,99));		
	}

	@Override
	public void setColorRectWater() {
		gc.setFill(Color.rgb(0, 0, 200));		
	}

	@Override
	public void setColorRectWaterSecondary() {
		gc.setFill(Color.rgb(156,232,17));		
	}

	@Override
	public void setColorAxisLine() {
		gc.setStroke(color_grey);		
	}

	@Override
	public void setColorZeroLine() {
		gc.setStroke(color_black);		
	}

	@Override
	public void setColorYScaleLine() {
		gc.setStroke(color_light_blue);		
	}

	@Override
	public void setColorYScaleText() {
		gc.setFill(color_black);		
	}

	@Override
	public void drawText(String text, float x, float y, PosHorizontal posHorizontal, PosVerical posVerical) {
		
		switch(posHorizontal) {
		case LEFT:
			gc.setTextAlign(TextAlignment.LEFT);
			break;
		case CENTER:
			gc.setTextAlign(TextAlignment.CENTER);
			break;
		case RIGHT:
			gc.setTextAlign(TextAlignment.RIGHT);
			break;
		default:
			throw new RuntimeException();			
		}
		
		switch(posVerical) {
		case TOP:
			gc.setTextBaseline(VPos.TOP);
			break;
		case CENTER:
			gc.setTextBaseline(VPos.CENTER);
			break;
		case BOTTOM:
			gc.setTextBaseline(VPos.BOTTOM);
			break;
		default:
			throw new RuntimeException();		
		}
		
		gc.fillText(text, x+0.5, y+0.5);	
	}

	@Override
	public void setColorXScaleYearText() {
		gc.setFill(Color.rgb(0,0,0));		
	}

	@Override
	public void setColorXScaleYearLine() {
		gc.setStroke(Color.rgb(220-100,220-100,255-100));	
	}

	@Override
	public void setColorXScaleMonthText() {
		gc.setFill(Color.rgb(100,100,100));

	}

	@Override
	public void setColorXScaleMonthLine() {
		gc.setStroke(Color.rgb(220,220,255));		
	}

	@Override
	public void setColorXScaleDayLine() {
		gc.setStroke(Color.rgb(240,240,255));		
	}

	@Override
	public void setColorXScaleDayText() {
		gc.setFill(Color.rgb(150,150,150));		
	}

	/*private float minValue = -10f;
	private float maxValue = 30f;
	private static Color[] indexedColors;
	static {
		indexedColors = new Color[6*256];
		for(int i=0;i<indexedColors.length;i++) {
			
			float v = ((float)i)/((float)(indexedColors.length-1));
			
			indexedColors[i] = getSpectraColor(v);
			
		}
	}*/
	
	public static void setIndexedColors(Color[] indexedColors) {
		//TimeSeriesPainterGraphics2D.indexedColors = indexedColors;
	}

	private static Color getSpectraColor(float value) {
		return null;
		/*
		//float x = 380f+(value*(780f-380f));
		float x = 380f+(value*(645f-380f));
		
		float r=0f;
		float g=0f;
		float b=0f;
		if ((x>=380f)&&(x<=440f)) { 
			r = -1f*(x-440f)/(440f-380f);
			g = 0f;
			b = 1f;
		}
		if ((x>=440f)&&(x<=490f)) {
			r = 0f;
			g = (x-440f)/(490f-440f);
			b = 1f;
		}
		if ((x>=490f)&&(x<=510f)) { 
			r = 0f;
			g = 1f;
			b = -1f*(x-510f)/(510f-490f);
		}
		if ((x>=510f)&&(x<=580f)) { 
			r = (x-510f)/(580f-510f);
			g = 1f;
			b = 0f;
		}
		if ((x>=580f)&&(x<=645f)) {
			r = 1f;
			g = -1f*(x-645f)/(645f-580f);
			b = 0f;
		}
		/*if ((x>=645f)&&(x<=780f)) {
			r = 1f;
			g = 0f;
			b = 0f;
		}*/
		/*return Color.rgb((int)(r*255f),(int)(g*255f),(int)(b*255f));*/
	}

	@Override
	public void setIndexedColor(float value) {
		/*//getSpectraColor(380);
		if(value>minValue) {
			if(value<maxValue) {
				float f = (value-minValue)/(maxValue-minValue);
				gc.setStroke(indexedColors[(int) (f*(indexedColors.length-1f))]);
				
			} else {
				gc.setStroke(indexedColors[indexedColors.length-1]);
			}
		} else {
			gc.setStroke(indexedColors[0]);
		}*/
	}
	
	@Override
	public void setIndexedColorRange(float min, float max) {
		/*minValue = min;
		maxValue = max;*/
	}

	@Override
	public void setColorXScaleHourLine() {
		// TODO Auto-generated method stub
		
	}

	@Override
	public void setColorXScaleHourText() {
		// TODO Auto-generated method stub
		
	}

	@Override
	public float[] getIndexColorRange() {
		// TODO Auto-generated method stub
		return null;
	}

}
