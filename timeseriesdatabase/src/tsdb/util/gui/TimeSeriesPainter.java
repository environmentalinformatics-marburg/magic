package tsdb.util.gui;


public interface TimeSeriesPainter {
	
	public enum PosHorizontal {LEFT,CENTER,RIGHT};
	public enum PosVerical {TOP,CENTER,BOTTOM};
	
	float getMinX();
	float getMinY();
	float getMaxX();
	float getMaxY();	
	void setColor(int r, int g, int b);	
	void drawLine(float x0, float y0, float x1, float y1);
	void setColorAxisLine();
	void setColorZeroLine();
	void setColorYScaleLine();
	void setColorYScaleText();
	void drawText(String text, float x, float y, PosHorizontal posHorizontal, PosVerical posVerical);
	void setColorXScaleYearText();
	void setColorXScaleYearLine();
	void setColorXScaleMonthText();
	void setColorXScaleMonthLine();
	void setColorXScaleDayText();
	void setColorXScaleDayLine();
	void fillRect(float xMin, float yMin, float xMax, float yMax);
	void setColorValueLineTemperature();
	void setColorValueLineTemperatureSecondary();
	void setColorConnectLineTemperature();
	void setColorConnectLineTemperatureSecondary();
	void setColorValueLineUnknown();
	void setColorValueLineUnknownSecondary();
	void setColorConnectLineUnknown();
	void setColorConnectLineUnknownSecondary();
	void setColorRectWater();	
	void setColorRectWaterSecondary();
	void setIndexedColor(float value);
	void setIndexedColorRange(float min, float max);	
}
