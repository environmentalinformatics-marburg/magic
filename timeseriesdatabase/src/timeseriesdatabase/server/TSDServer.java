package timeseriesdatabase.server;

import java.rmi.RemoteException;

import timeseriesdatabase.DataQuality;
import timeseriesdatabase.QueryProcessor;
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

}
