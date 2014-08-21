package processinggraph;

import timeseriesdatabase.DataQuality;
import timeseriesdatabase.Station;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.VirtualPlot;
import util.Util;

public interface Base extends Node_temp {
	
	@Override
	public default boolean isConstantTimestep() {
		return true;
	}
	
	public static Base create(TimeSeriesDatabase timeSeriesDatabase, String plotID, String[] querySchema, NodeGen stationGen) {
		VirtualPlot virtualPlot = timeSeriesDatabase.getVirtualPlot(plotID);
		if(virtualPlot!=null) {
			return VirtualBase.create(timeSeriesDatabase, virtualPlot, querySchema, stationGen);
		}
		Station station = timeSeriesDatabase.getStation(plotID);
		if(station!=null) {
			return StationBase.create(timeSeriesDatabase, station, querySchema, stationGen);
		}else {
			throw new RuntimeException();
		}	
	}
	
	public abstract class Abstract implements Base {		
		protected TimeSeriesDatabase timeSeriesDatabase; // not null		
		Abstract(TimeSeriesDatabase timeSeriesDatabase) {
			Util.throwNull(timeSeriesDatabase);
			this.timeSeriesDatabase = timeSeriesDatabase;
		}		
	}
}
