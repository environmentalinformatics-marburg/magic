package gui;

import java.awt.Color;
import java.util.ArrayList;
import java.util.List;

import org.eclipse.swt.SWT;
import org.eclipse.swt.graphics.GC;
import org.eclipse.swt.widgets.Canvas;

import timeseriesdatabase.aggregated.AggregationInterval;
import timeseriesdatabase.aggregated.AggregationType;
import timeseriesdatabase.aggregated.TimeSeries;
import timeseriesdatabase.raw.TimestampSeries;
import timeseriesdatabase.raw.TimestampSeriesEntry;

public class DataView {

	public AggregationInterval aggregationInterval;
	public TimestampSeries resultTimeSeries;
	public Canvas canvas;

	private long minTimestamp;
	private long maxTimestamp;
	private float minValue;
	private float maxValue;


	public DataView() {

	}

	void updateViewData() {
		if(resultTimeSeries!=null) {

			minValue = Float.MAX_VALUE;
			maxValue = -Float.MAX_VALUE;

			for(TimestampSeriesEntry entry:resultTimeSeries) {
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

			minTimestamp = resultTimeSeries.getFirstTimestamp();
			maxTimestamp = resultTimeSeries.getLastTimestamp();

		} else {

			minTimestamp = -1;
			maxTimestamp = -1;

			minValue = Float.NaN;
			maxValue = -Float.NaN;
		}
	}

	public void paintCanvas(GC gc) {
		if(resultTimeSeries!=null) {
			float border = 20;
			float width = canvas.getSize().x-(2*border);
			float height = canvas.getSize().y-(2*border);
			float timeFactor = width/(maxTimestamp-minTimestamp+1); //???

			float valueFactor = height/(maxValue-minValue);

			float valueOffset = -minValue;

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
			
			org.eclipse.swt.graphics.Color c0 = new org.eclipse.swt.graphics.Color(canvas.getDisplay(),0,0,0);
			org.eclipse.swt.graphics.Color c1 = new org.eclipse.swt.graphics.Color(canvas.getDisplay(),200,200,200);
			
			Integer prevX = null;
			Integer prevY = null;
			
			List<int[]> grayList = new ArrayList<int[]>(resultTimeSeries.entryList.size());
			List<int[]> blackList = new ArrayList<int[]>(resultTimeSeries.entryList.size());

			for(TimestampSeriesEntry entry:resultTimeSeries) {	
				float value = entry.data[0];
				if(!Float.isNaN(value)) {				
					float offset = (entry.timestamp-minTimestamp)*timeFactor;
					int x0 = (int) (offset+border);
					int x1 = (int) (offset+timeAggregationSize+border);
					int y = (int) ((value-minValue)*valueFactor+border);
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
			
			gc.setForeground(c1);
			for(int[] e:grayList) {
				gc.drawLine(e[0], e[1], e[2], e[3]);
			}
			
			gc.setForeground(c0);
			for(int[] e:blackList) {
				gc.drawLine(e[0], e[1], e[2], e[3]);
			}


			System.out.println("data length: "+resultTimeSeries.entryList.size());
		}

	}

}
