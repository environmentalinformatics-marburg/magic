package gui;


import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

import org.eclipse.swt.SWT;
import org.eclipse.swt.graphics.Color;
import org.eclipse.swt.graphics.GC;
import org.eclipse.swt.widgets.Canvas;

import timeseriesdatabase.TimeConverter;
import timeseriesdatabase.aggregated.AggregationInterval;
import timeseriesdatabase.aggregated.AggregationType;
import timeseriesdatabase.aggregated.TimeSeries;
import timeseriesdatabase.raw.TimestampSeries;
import timeseriesdatabase.raw.TimeSeriesEntry;
import util.Util;

public class DataView {

	public AggregationInterval aggregationInterval;
	public TimestampSeries resultTimeSeries;

	private long minTimestamp;
	private long maxTimestamp;
	private float minValue;
	private float maxValue;



	public Canvas canvas;


	Color color_black;
	Color color_grey;
	Color color_light;

	float border = 40;

	int xStart;
	int xEnd;
	int yStart;
	int yEnd;	
	float width;
	float height;
	float valueFactor;
	float valueOffset;
	
	float timeFactor;




	public DataView() {

	}

	void allign() {

		double scale = (int) (Math.log((maxValue-minValue))/Math.log(10));
		System.out.println("scale"+scale+" -> "+Math.pow(10, scale));
		float grid = (float) Math.pow(10, scale);

		System.out.println(";"+minValue+" "+maxValue+" "+Math.abs(minValue%grid)+" "+Math.abs(maxValue%grid));

		float absRestMin = Math.abs(minValue%grid);
		if(minValue>0) {
			minValue = minValue-absRestMin;
		} else {
			if(absRestMin>0) {
				minValue = minValue-(grid-absRestMin);
			}
		}

		float absRestMax = Math.abs(maxValue%grid);
		if(absRestMax>0) {
		if(absRestMax>0) {
			maxValue = maxValue+(grid-absRestMax);
		}
		} else {
			maxValue = maxValue+absRestMax;
		}

		System.out.println(":"+minValue+" "+maxValue);

	}

	void updateViewData() {
		if(resultTimeSeries!=null) {

			minValue = Float.MAX_VALUE;
			maxValue = -Float.MAX_VALUE;

			for(TimeSeriesEntry entry:resultTimeSeries) {
				float value = entry.data[0];
				if(!Float.isNaN(value)) {
					if(value<minValue) {
						minValue = value;						
					}
					if(value>maxValue) {
						maxValue = value;						
					}
				}
			}

			allign();

			minTimestamp = resultTimeSeries.getFirstTimestamp();
			maxTimestamp = resultTimeSeries.getLastTimestamp();

		} else {

			minTimestamp = -1;
			maxTimestamp = -1;

			minValue = Float.NaN;
			maxValue = -Float.NaN;
		}
	}

	private void drawGrid(GC gc) {

		gc.setForeground(color_light);

		float graphYDiff = yStart-yEnd;
		float valueDiff = maxValue-minValue;

		int maxLines = (int) (graphYDiff/17);


		float lineStep = valueDiff/maxLines;

		System.out.println("lineStep "+lineStep);

		if(lineStep<1) {
			lineStep=1;
		} else if(lineStep<5) {
			lineStep=5;
		} else if(lineStep<10) {
			lineStep=10;
		} else if(lineStep<50) {
			lineStep=50;
		} else if(lineStep<100) {
			lineStep=100;
		} else if(lineStep<500) {
			lineStep=500;
		}

		float firstLine = minValue-minValue%lineStep;
		maxLines =  (int) ((maxValue-firstLine)/lineStep);


		for(int line=0;line<maxLines;line++) {
			float value = firstLine+line*lineStep;
			int y = valueToGraph(value);
			
			gc.setForeground(color_light);
			gc.drawLine(xStart , y, xEnd, y);
			
					
			//gc.setForeground(color_grey);
			gc.setForeground(color_black);
			gc.drawText(Util.floatToString(value), 3, y-10);
			
		}


		LocalDateTime minDateTime = TimeConverter.oleMinutesToLocalDateTime(minTimestamp);
		LocalDateTime maxDateTime = TimeConverter.oleMinutesToLocalDateTime(maxTimestamp);
		
		int minYear = minDateTime.getYear();
		int maxYear = maxDateTime.getYear();
		
		for(int y=minYear;y<=maxYear;y++) {
			long timestamp = TimeConverter.DateTimeToOleMinutes(LocalDateTime.of(y, 1, 1, 0, 0));
			if(timestamp>=minTimestamp) {
				int x = (int) (xStart+(timestamp-minTimestamp)*timeFactor);
				
				gc.setForeground(color_light);
				gc.drawLine(x , yStart, x, yEnd);
				
				gc.setForeground(color_black);
				gc.drawText(""+y, x, yStart+20);
			}
			System.out.println(timestamp);
		}
		

	}

	private int timestampToGraph(long timestamp) {
		//return (int) (xStart+(x*valueFactor));
		return -1;
	}

	private int valueToGraph(float value) {
		return (int) (yStart-((valueOffset+value)*valueFactor));
	}


	private void drawXYAxis(GC gc) {

		gc.setForeground(color_black);

		gc.drawText(""+TimeConverter.oleMinutesToLocalDateTime(minTimestamp), xStart, yStart+2);
		gc.drawText(""+TimeConverter.oleMinutesToLocalDateTime(maxTimestamp), xEnd-70, yStart+2);

		//gc.drawText(Util.floatToString(minValue), 3, yStart-10);
		//gc.drawText(Util.floatToString(maxValue), 3, yEnd-10);


		gc.setForeground(color_grey);

		gc.drawLine(xStart , yStart, xEnd, yStart); //x-Aches
		gc.drawLine(xStart , yStart, xStart, yEnd); // y-Achse
		gc.drawLine(xStart , yEnd, xEnd, yEnd); //x-Grenze
		gc.drawLine(xEnd , yStart, xEnd, yEnd); // y-Grenze



		//int zero_y = (int) ((height-minValue)*valueFactor+border);


		//  min  zero max

		//  height   * (value-min) 
		//----------------- 
		//(max-min)


		int y = (int) ((height-(/*0f-*/minValue)*valueFactor)+border);

		int zero_y = (int) ((int) height-(height*(/*0-*/minValue)/(maxValue-minValue))+border);
		gc.drawLine(xStart , zero_y, xEnd, zero_y);

		System.out.println(yStart+" "+zero_y+" "+y+" "+yEnd);





	}


	public void paintCanvas(GC gc) {
		if(resultTimeSeries!=null) {

			color_black = new Color(canvas.getDisplay(),0,0,0);
			color_grey = new Color(canvas.getDisplay(),190,190,190);
			color_light = new Color(canvas.getDisplay(),220,220,220);

			xStart = (int) border;
			xEnd = (int)(canvas.getSize().x-border);
			yStart = (int) (canvas.getSize().y-border);
			yEnd = (int) border;

			width = xEnd-xStart;
			height = yStart-yEnd; //!!

			valueFactor = height/(maxValue-minValue);

			valueOffset = -minValue;





			timeFactor = width/(maxTimestamp-minTimestamp+1); //???









			int agg = 60;
			switch(aggregationInterval) {
			case HOUR:
				agg=60;
				break;
			case DAY:
				agg=1*24*60;
				break;
			case WEEK:
				agg=7*24*60;
				break;
			case MONTH:
				agg=28*24*60;
				break;
			case YEAR:
				agg=365*24*60;
				break;
			default:
				System.out.println("error in agg");
			}


			float timeAggregationSize = agg*timeFactor;


			System.out.println("valueFactor: "+valueFactor);
			System.out.println("valueOffset: "+valueOffset);

			Float prevValue = null;

			//for(int offset=0;offset<data.length;offset++) {
			/*for(TimestampSeriesEntry entry:resultTimeSeries) {	
				float value = entry.data[0];
				long offset = entry.timestamp-minTimestamp;
				if(!Float.isNaN(value)) {
					int x = (int) (offset*timeFactor);
					int y = (int)(height-((value+valueOffset)*valueFactor));
					if(prevValue!=null) {
						int xprev = (int) ((offset-1)*timeFactor);
						int yprev = (int)(height-((prevValue+valueOffset)*valueFactor));
						gc.drawLine(xprev, yprev, x, y);
					} else {
						gc.drawLine(x, y, x, y);
					}
					prevValue = value;
				} else {
					prevValue = null;
				}
			}*/

			//Color white = display.getSystemColor(SWT.COLOR_WHITE);
			//Color black = display.getSystemColor(SWT.COLOR_BLACK);



			Integer prevX = null;
			Integer prevY = null;

			List<int[]> grayList = new ArrayList<int[]>(resultTimeSeries.entryList.size());
			List<int[]> blackList = new ArrayList<int[]>(resultTimeSeries.entryList.size());

			for(TimeSeriesEntry entry:resultTimeSeries) {	
				float value = entry.data[0];
				if(!Float.isNaN(value)) {				
					float offset = (entry.timestamp-minTimestamp)*timeFactor;
					int x0 = (int) (offset+border);
					int x1 = (int) (offset+timeAggregationSize+border);
					int y = (int) ((height-(value-minValue)*valueFactor)+border);
					if(prevX!=null) {
						//gc.setForeground(c1);
						//gc.drawLine(x0, prevY, x0, y);
						grayList.add(new int[]{x0, prevY, x0, y});
					}
					//gc.setForeground(c0);
					//gc.drawLine(x0, y, x1, y);
					blackList.add(new int[]{x0, y, x1, y});
					prevX = x1;
					prevY = y;
				} else {
					prevX = null;
					prevY = null;
				}

			}

			//*** start drawing

			drawGrid(gc);

			drawXYAxis(gc);


			gc.setForeground(color_grey);
			for(int[] e:grayList) {
				gc.drawLine(e[0], e[1], e[2], e[3]);
			}

			gc.setForeground(color_black);
			for(int[] e:blackList) {
				gc.drawLine(e[0], e[1], e[2], e[3]);
			}


			//*** end drawing


			System.out.println("data length: "+resultTimeSeries.entryList.size());
		}

	}

}
