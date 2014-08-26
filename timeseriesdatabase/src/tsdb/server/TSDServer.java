package tsdb.server;

import java.rmi.RemoteException;

import tsdb.DataQuality;
import tsdb.GeneralStation;
import tsdb.QueryProcessor;
import tsdb.Station;
import tsdb.TsDB;
import tsdb.aggregated.AggregationInterval;
import tsdb.raw.TimestampSeries;
import tsdb.util.iterator.TimeSeriesIterator;

public class TSDServer implements TSDServerInterface {
	
	private TsDB timeSeriesDatabase;
	private QueryProcessor qp;
	
	public TSDServer(TsDB timeSeriesDatabase) throws RemoteException {
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
		return timeSeriesDatabase.getGeneralStationNames();
	}

	@Override
	public String[] queryPlotIds(String generalStationName) {
		GeneralStation generalStation = timeSeriesDatabase.getGeneralStation(generalStationName);
		if(generalStation!=null) {
			String[] names = new String[generalStation.stationList.size()];
			for(int i=0;i<generalStation.stationList.size();i++) {
				names[i] = generalStation.stationList.get(i).stationID;
			}
			return names;
		}
		return null;
	}

}
