package web;

import static tsdb.util.AssumptionCheck.throwNull;
import static tsdb.util.AssumptionCheck.throwNulls;

import java.util.ArrayList;
import java.util.List;

import tsdb.aggregated.AggregationInterval;
import tsdb.raw.TimeSeriesEntry;
import tsdb.raw.TimestampSeries;

public class TimeSeriesDiagram {

	private final TimestampSeries timestampseries;
	private final AggregationInterval aggregationInterval;

	private long aggregationTimeInterval;

	private float dataMinValue;
	private float dataMaxValue;
	private float dataValueRange;
	private float dataCount;
	private float dataSum;

	private long dataMinTimestamp;
	private long dataMaxTimestamp;
	private long dataTimestampRange;

	private static final float borderTop = 10;
	private static final float borderBottom = 15;
	private static final float borderLeft = 40;
	private static final float borderRight = 10;

	private float diagramMinX;
	private float diagramMinY;
	private float diagramMaxX;
	private float diagramMaxY;
	private float diagramWidth;
	private float diagramHeigh;

	private float diagramMinTimestamp;
	private float diagramMaxTimestamp;
	private float diagramTimestampRange;
	private float diagramMinValue;
	private float diagramMaxValue;
	private float diagramValueRange;
	private float diagramTimestampFactor;
	private float diagramValueFactor;

	public TimeSeriesDiagram(TimestampSeries timestampseries, AggregationInterval aggregationInterval) {
		throwNulls(timestampseries,aggregationInterval);
		this.timestampseries = timestampseries;
		this.aggregationInterval = aggregationInterval;

		aggregationTimeInterval = 60;
		switch(aggregationInterval) {
		case HOUR:
			aggregationTimeInterval=60;
			break;
		case DAY:
			aggregationTimeInterval=1*24*60;
			break;
		case WEEK:
			aggregationTimeInterval=7*24*60;
			break;
		case MONTH:
			aggregationTimeInterval=30*24*60;//28*24*60;
			break;
		case YEAR:
			aggregationTimeInterval=365*24*60;
			break;
		default:
			System.out.println("error in agg");
		}

		dataMinValue = Float.MAX_VALUE;
		dataMaxValue = -Float.MAX_VALUE;
		dataCount = 0f;
		dataSum = 0f;

		for(TimeSeriesEntry entry:timestampseries) {
			float value = entry.data[0];
			if(!Float.isNaN(value)) {
				if(value<dataMinValue) {
					dataMinValue = value;						
				}
				if(value>dataMaxValue) {
					dataMaxValue = value;						
				}
				dataCount++;
				dataSum += value;
			}
		}

		dataValueRange = dataMaxValue-dataMinValue;

		dataMinTimestamp = timestampseries.getFirstTimestamp();
		dataMaxTimestamp = timestampseries.getLastTimestamp();
		dataTimestampRange = dataMaxTimestamp-dataMinTimestamp;		
	}

	public int calcDiagramX(float timestamp) {
		return (int) (diagramMinX+((timestamp-diagramMinTimestamp)*diagramTimestampFactor));
	}

	public int calcDiagramY(float value) {
		return (int) (diagramMaxY-((value-diagramMinValue)*diagramValueFactor));
	}

	private class ValueLine {
		public final float x0;
		public final float x1;
		public final float y;
		public ValueLine(float x0, float x1, float y) {
			this.x0 = x0;
			this.x1 = x1;
			this.y = y;
		}
	}

	private class ConnectLine {
		public final float x;
		public final float y0;
		public final float y1;
		public ConnectLine(float x, float y0, float y1) {
			this.x = x;
			this.y0 = y0;
			this.y1 = y1;
		}
	}

	public void draw(TimeSeriesPainter tsp) {
		throwNull(tsp);
		tsp.setColor(0,0,0);

		diagramMinX = tsp.getMinX()+borderLeft;
		diagramMinY = tsp.getMinY()+borderTop;
		diagramMaxX = tsp.getMaxX()-borderRight;
		diagramMaxY = tsp.getMaxY()-borderBottom;
		diagramWidth = diagramMaxX-diagramMinX;
		diagramHeigh = diagramMaxY-diagramMinY;

		diagramMinTimestamp = dataMinTimestamp;
		diagramMaxTimestamp = dataMaxTimestamp;
		diagramTimestampRange = dataMaxTimestamp-dataMinTimestamp;

		diagramMinValue = dataMinValue;
		diagramMaxValue = dataMaxValue;
		diagramValueRange = dataMaxValue-dataMinValue;
		diagramTimestampFactor = diagramWidth/diagramTimestampRange;
		diagramValueFactor = diagramHeigh/diagramValueRange;

		boolean hasPrev = false;
		float prevY = 0;
		float prevTimestamp = 0;

		List<ValueLine> valueLineList = new ArrayList<ValueLine>(timestampseries.entryList.size());
		List<ConnectLine> connectLineList = new ArrayList<ConnectLine>(timestampseries.entryList.size());

		for(TimeSeriesEntry entry:timestampseries) {
			float timestamp = entry.timestamp;
			float value = entry.data[0];
			if(Float.isNaN(value)) {
				hasPrev = false;
			} else {
				int x0 = calcDiagramX(timestamp);
				int x1 = calcDiagramX(timestamp+aggregationTimeInterval);
				int y = calcDiagramY(value);
				valueLineList.add(new ValueLine(x0, x1, y));
				if(hasPrev) {
					connectLineList.add(new ConnectLine(x0, prevY, y));
					//System.out.println("draw "+x+" "+y);
					//timeSeriesPainter.drawLine(x, y, x2, y);
				}
				prevY = y;
				hasPrev = true;
			}

		}
		
		tsp.setColorConnectLine();
		for(ConnectLine connectLine:connectLineList) {
			tsp.drawLine(connectLine.x, connectLine.y0, connectLine.x, connectLine.y1);
		}
		
		tsp.setColorValueLine();
		for(ValueLine valueLine:valueLineList) {
			tsp.drawLine(valueLine.x0,valueLine.y,valueLine.x1,valueLine.y);
		}

		//*** start drawing
		
		/*

		gc.setForeground(clrConnections);
		for(int[] e:connectLineList) {
			gc.drawLine(e[0], e[1], e[2], e[3]);
		}

		gc.setForeground(clrValues);
		for(int[] e:valueLineList) {
			gc.drawLine(e[0], e[1], e[2], e[3]);
		}
		*/
		//*** end drawing
	}

}
