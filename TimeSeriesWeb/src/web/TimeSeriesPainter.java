package web;

public interface TimeSeriesPainter {	
	float getMinX();
	float getMinY();
	float getMaxX();
	float getMaxY();	
	void setColor(int r, int g, int b);	
	void drawLine(float x0, float y0, float x1, float y1);
	void setColorValueLine();
	void setColorConnectLine();
}
