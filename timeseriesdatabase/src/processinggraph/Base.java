package processinggraph;

import timeseriesdatabase.DataQuality;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.VirtualPlot;

public abstract class Base extends Node {
	
	protected Base(TimeSeriesDatabase timeSeriesDatabase) {
		super(timeSeriesDatabase);
	}

	public static Base create(TimeSeriesDatabase timeSeriesDatabase, String plotID, String[] querySchema) {
		if(timeSeriesDatabase.virtualPlotExists(plotID)) {
			return VirtualBase.create(timeSeriesDatabase, plotID, querySchema);
		} else if(timeSeriesDatabase.stationExists(plotID)){
			return StationBase.create(timeSeriesDatabase, plotID, querySchema);
		} else {
			throw new RuntimeException();
		}
	}
	
	public static Base create(TimeSeriesDatabase timeSeriesDatabase, String plotID, String[] querySchema, DataQuality dataQuality) {
		if(timeSeriesDatabase.virtualPlotExists(plotID)) {
			return VirtualBase.create(timeSeriesDatabase, plotID, querySchema, dataQuality);
		} else if(timeSeriesDatabase.stationExists(plotID)){
			return StationBase.create(timeSeriesDatabase, plotID, querySchema, dataQuality);
		} else {
			throw new RuntimeException();
		}
	}

}
