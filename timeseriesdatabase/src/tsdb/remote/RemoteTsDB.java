package tsdb.remote;

import java.rmi.Remote;
import java.rmi.RemoteException;
import java.util.ArrayList;

import tsdb.LoggerType;
import tsdb.catalog.SourceEntry;
import tsdb.component.Region;
import tsdb.component.Sensor;
import tsdb.util.AggregationInterval;
import tsdb.util.DataQuality;
import tsdb.util.Pair;
import tsdb.util.TimeSeriesMask;
import tsdb.util.TimestampInterval;
import tsdb.util.iterator.TimestampSeries;

public interface RemoteTsDB extends Remote {
	
	//sensor
	String[] getSensorNamesOfPlot(String plotID) throws RemoteException;
	String[] getSensorNamesOfGeneralStation(String generalStationName) throws RemoteException;	
	Sensor[] getSensors() throws RemoteException;
	Sensor getSensor(String sensorName) throws RemoteException;
	String[] getBaseSchema(String[] rawSchema) throws RemoteException;
	String[] getCacheSchemaNames(String streamName) throws RemoteException;
	String[] getValidSchema(String plotID, String[] sensorNames) throws RemoteException;
	
	//region
	Region[] getRegions() throws RemoteException;
	@Deprecated
	String[] getRegionLongNames() throws RemoteException;
	@Deprecated
	Region getRegionByLongName(String longName) throws RemoteException;
	Region getRegionByPlot(String plotID) throws RemoteException;
	
	//general station
	GeneralStationInfo[] getGeneralStations() throws RemoteException;
	GeneralStationInfo[] getGeneralStationsOfRegion(String regionName) throws RemoteException;
	@Deprecated
	String[] getGeneralStationLongNames(String regionName) throws RemoteException;
	
	//plot station virtualPlot
	PlotInfo[] getPlots() throws RemoteException;
	StationInfo[] getStations() throws RemoteException;
	String[] getPlotStations(String plotID) throws RemoteException;	
	VirtualPlotInfo[] getVirtualPlots() throws RemoteException;
	VirtualPlotInfo getVirtualPlot(String plotID) throws RemoteException;
	String[] getStationNames() throws RemoteException;
	String[] cacheStorageGetStreamNames() throws RemoteException;
	String[] getPlotIDsByGeneralStationByLongName(String longName) throws RemoteException;
	ArrayList<TimestampInterval<String>> getPlotTimeSpans() throws RemoteException;
	ArrayList<TimestampInterval<String>> getPlotTimeSpansOfRegion(String regionName) throws RemoteException;	
	ArrayList<TimestampInterval<String>> getPlotTimeSpansOfGeneralStation(String generalStationName) throws RemoteException;
	
	//logger
	LoggerType[] getLoggerTypes() throws RemoteException;
	LoggerType getLoggerType(String loggerTypeName) throws RemoteException;
	
	//source catalog
	SourceEntry[] getSourceCatalogEntries() throws RemoteException;
	
	//console
	long execute_console_command(String input_line) throws RemoteException;	
	Pair<Boolean,String[]> console_comand_get_output(long commandThreadId) throws RemoteException;

	//query
	TimestampSeries plot(String queryType, String plotID, String[] columnNames, AggregationInterval aggregationInterval, DataQuality dataQuality, boolean interpolated, Long start, Long end) throws RemoteException;
	TimestampSeries cache(String streamName, String[] columnNames, AggregationInterval aggregationInterval) throws RemoteException;
	
	//time series mask
	TimeSeriesMask getTimeSeriesMask(String stationName, String sensorName) throws RemoteException;
	void setTimeSeriesMask(String stationName, String sensorName, TimeSeriesMask timeSeriesMask) throws RemoteException;
}
