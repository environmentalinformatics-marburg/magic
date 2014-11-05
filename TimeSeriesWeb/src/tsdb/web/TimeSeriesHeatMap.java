package tsdb.web;

import tsdb.TimeConverter;
import tsdb.raw.TimestampSeries;
import tsdb.raw.TsEntry;

public class TimeSeriesHeatMap {

	private final TimestampSeries ts;

	public TimeSeriesHeatMap(TimestampSeries ts) {
		this.ts = ts;
		/*if(ts.timeinterval!=60) {
			throw new RuntimeException("TimeSeriesHeatMap needs one hour time steps: "+ts.timeinterval);
		}*/
	}

	public void draw(TimeSeriesPainter tsp) {
		tsp.setColorRectWater();
		long start = ts.entryList.get(0).timestamp-ts.entryList.get(0).timestamp%(60*24);
		for(TsEntry entry:ts.entryList) {
			float value = entry.data[0];
			if(!Float.isNaN(value)) {
				tsp.setIndexedColor(value);
				float x = (((entry.timestamp-start)/60)/24)*1;
				float y = (((entry.timestamp-start)/60)%24)*1;
				tsp.drawLine(x, y, x, y);
				//tsp.fillRect(x, y, x+4, y+4);
			}
		}
		
		/*float value=-10f;
		for(int i=0;i<20000;i++) {
			value += 0.01f;			
			tsp.setIndexedColor(value);
			float x = i/24;
			float y = i%24;
			tsp.drawLine(x, y+100, x, y+100);
			if(y==0) {
				System.out.println(i+": "+value);
			}
		}*/
	}

}
