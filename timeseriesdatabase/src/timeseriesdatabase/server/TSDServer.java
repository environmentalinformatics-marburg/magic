package timeseriesdatabase.server;

import java.rmi.RemoteException;

import timeseriesdatabase.DataQuality;
import timeseriesdatabase.GeneralStation;
import timeseriesdatabase.QueryProcessor;
import timeseriesdatabase.Station;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.aggregated.AggregationInterval;
import timeseriesdatabase.raw.TimestampSeries;
import util.iterator.TimeSeriesIterator;

public class TSDServer implements TSDServerInterface {
	
	private TimeSeriesDatabase timeSeriesDatabase;
	private QueryProcessor qp;
	
	public TSDServer(TimeSeriesDatabase timeSeriesDatabase) throws RemoteException {
		super();
		this.timeSeriesDatabase = timeSeriesDatabase;
		this.qp = new QueryProcessor(timeSeriesDatabase);
	}
	
	@Override
	public TimestampSeries query(String plotID, String[] querySchema, Long queryStart, Long queryEnd, DataQuality dataQuality, AggregationInterval aggregationInterval, boolean interpolated) {
		TimeSeriesIterator it = qp.query_aggregated(plotID, querySchema, queryStart, queryEnd, dataQuality, aggregationInterval, interpolated);
		TimestampSeries timestampSeries = TimestampSeries.create(it);
		return timestampSeries;
	}

	@Override
	public String[] queryGeneralStations() {		
		return timeSeriesDatabase.generalStationMap.keySet().toArray(new String[0]);
	}

	@Override
	public String[] queryPlotIds(String generalStationName) {
		GeneralStation generalStation = timeSeriesDatabase.generalStationMap.get(generalStationName);
		if(generalStation!=null) {
			String[] names = new String[generalStation.stationList.size()];
			for(int i=0;i<generalStation.stationList.size();i++) {
				names[i] = generalStation.stationList.get(i).plotID;
			}
			return names;
		}
		return null;
	}

}
