package tsdb.remote;

import java.io.Serializable;

import tsdb.GeneralStation;
import tsdb.LoggerType;
import tsdb.Station;

public class StationInfo implements Serializable {

	
	public final String stationID;
	public final LoggerType loggerType;
	public final double geoPoslongitude;
	public final double geoPosLatitude;
	public final GeneralStation generalStation;
	public final String alternativeID;

	public StationInfo(Station station) {
		stationID= station.stationID;
		loggerType=station.loggerType;
		geoPoslongitude= station.geoPoslongitude;
		geoPosLatitude= station.geoPosLatitude;
		generalStation= station.generalStation;
		alternativeID=station.alternativeID;
	}		
}