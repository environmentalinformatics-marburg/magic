package timeseriesdatabase.server;

import java.rmi.Remote;
import java.rmi.RemoteException;

import timeseriesdatabase.DataQuality;
import timeseriesdatabase.aggregated.AggregationInterval;
import timeseriesdatabase.raw.TimestampSeries;
import util.iterator.TimeSeriesIterator;

public interface TSDServerInterface extends Remote {

	TimestampSeries query(String plotID, String[] querySchema, Long queryStart, Long queryEnd, DataQuality dataQuality, AggregationInterval aggregationInterval, boolean interpolated) throws RemoteException;
}
