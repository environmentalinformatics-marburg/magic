package tsdb.remote;

import static tsdb.util.AssumptionCheck.throwNull;

import java.rmi.RemoteException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Stream;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import tsdb.DataQuality;
import tsdb.GeneralStation;
import tsdb.LoggerType;
import tsdb.QueryProcessor;
import tsdb.Region;
import tsdb.Sensor;
import tsdb.Station;
import tsdb.TsDB;
import tsdb.VirtualPlot;
import tsdb.aggregated.AggregationInterval;
import tsdb.catalog.SourceEntry;
import tsdb.graph.Node;
import tsdb.graph.QueryPlan;
import tsdb.graph.RawSourceTemp;
import tsdb.graph.StationRawSource;
import tsdb.raw.TimestampSeries;
import tsdb.run.ConsoleStarter;
import tsdb.run.ConsoleRunner;
import tsdb.util.Pair;
import tsdb.util.TimestampInterval;
import tsdb.util.iterator.TsIterator;

public class ServerTsDB implements RemoteTsDB {

	private static final Logger log = LogManager.getLogger();

	protected final TsDB tsdb; //not null

	public ServerTsDB(TsDB tsdb) throws RemoteException { // !!
		throwNull(tsdb);
		this.tsdb = tsdb;
	}

	//----------------------- sensor

	@Override
	public String[] getSensorNamesOfPlot(String plotID) {
		if(plotID==null) {
			log.warn("plotID null");
			return null;
		}
		VirtualPlot virtualPlot = tsdb.getVirtualPlot(plotID);
		if(virtualPlot!=null) {
			return virtualPlot.getSchema();
		}
		Station station = tsdb.getStation(plotID);
		if(station!=null) {
			return station.getSchema();

		}
		log.warn("plotID not found "+plotID);
		return null;
	}

	@Override
	public String[] getSensorNamesOfGeneralStation(String generalStationName) {
		if(generalStationName==null) {
			log.warn("generalStationName null");
			return null;
		}		
		GeneralStation generalStation = tsdb.getGeneralStation(generalStationName);
		if(generalStation==null) {
			log.warn("generalStation not found");
			return null;
		}

		TreeSet<String> sensorNameSet = new TreeSet<String>();

		for(Station station:generalStation.stationList) {
			sensorNameSet.addAll(Arrays.asList(station.getSchema()));
		}

		for(VirtualPlot virtualPlot:generalStation.virtualPlots) {
			sensorNameSet.addAll(Arrays.asList(virtualPlot.getSchema()));
		}		

		return sensorNameSet.toArray(new String[sensorNameSet.size()]); 
	}

	@Override
	public Sensor[] getSensors() {
		return tsdb.getSensors().toArray(new Sensor[0]);
	}

	@Override
	public Sensor getSensor(String sensorName) {
		return tsdb.getSensor(sensorName);
	}

	@Override
	public String[] getBaseSchema(String[] rawSchema) {
		return tsdb.getBaseSchema(rawSchema);
	}

	@Override
	public String[] getCacheSchemaNames(String streamName) {
		return tsdb.cacheStorage.getSchema(streamName).names;
	}

	@Override
	public String[] getValidSchema(String plotID, String[] sensorNames) {
		return tsdb.getValidSchema(plotID, sensorNames);
	}

	// ----------------------------------- region
	@Override
	public Region[] getRegions() {
		Collection<Region> regions = tsdb.getRegions();
		return regions.toArray(new Region[regions.size()]);
	}

	@Override
	public String[] getRegionLongNames() {
		return tsdb.getRegionLongNames().toArray(String[]::new);
	}

	@Override
	public Region getRegionByLongName(String longName) {
		return tsdb.getRegionByLongName(longName);
	}

	// ---------------------------- general station
	@Override
	public GeneralStationInfo[] getGeneralStations() {
		return tsdb.getGeneralStations().stream().map(g->new GeneralStationInfo(g)).toArray(GeneralStationInfo[]::new);
	}

	@Override
	public GeneralStationInfo[] getGeneralStationsOfRegion(String regionName) {
		return tsdb.getGeneralStations(regionName).map(g->new GeneralStationInfo(g)).toArray(GeneralStationInfo[]::new);
	}

	@Override
	public String[] getGeneralStationLongNames(String regionName) {
		return tsdb.getGeneralStationLongNames(regionName);
	}

	// ----------------------------------- plot station virtualPlot
	@Override
	public PlotInfo[] getPlots() {
		return Stream.concat(
				tsdb.getStations().stream().filter(s->s.isPlot).map(s->new PlotInfo(s)), 
				tsdb.getVirtualPlots().stream().map(v->new PlotInfo(v))
				).toArray(PlotInfo[]::new);
	}

	@Override
	public StationInfo[] getStations() {
		return tsdb.getStations().stream().map(s->new StationInfo(s)).toArray(StationInfo[]::new);
	}

	@Override
	public VirtualPlotInfo[] getVirtualPlots() {
		return tsdb.getVirtualPlots().stream().map(v->new VirtualPlotInfo(v)).toArray(VirtualPlotInfo[]::new);
	}

	@Override
	public VirtualPlotInfo getVirtualPlot(String plotID) {
		VirtualPlot virtualPlot = tsdb.getVirtualPlot(plotID);
		if(virtualPlot!=null) {
			return new VirtualPlotInfo(virtualPlot);
		} else {
			return null;
		}
	}

	@Override
	public String[] getStationNames() {
		return tsdb.getStationNames().toArray(new String[0]);
	}

	@Override
	public String[] cacheStorageGetStreamNames() {
		return tsdb.cacheStorage.getStreamNames().toArray(String[]::new);
	}

	@Override
	public String[] getPlotIDsByGeneralStationByLongName(String longName) {		
		GeneralStation generalStation = tsdb.getGeneralStationByLongName(longName);
		if(generalStation==null) {
			return null;
		}
		ArrayList<String> plotIDList = new ArrayList<String>();
		generalStation.stationList.stream().forEach(station->plotIDList.add(station.stationID));
		generalStation.virtualPlots.stream().forEach(virtualPlot->plotIDList.add(virtualPlot.plotID));
		if(plotIDList.isEmpty()) {
			return null;
		}
		return plotIDList.toArray(new String[0]);
	}

	@Override 
	public ArrayList<TimestampInterval<String>> getPlotTimeSpans() {
		ArrayList<TimestampInterval<String>> result = new ArrayList<TimestampInterval<String>>();

		tsdb.getPlotNames().forEach(plotID->{
			long[] interval = tsdb.getTimeInterval(plotID);
			if(interval!=null) {
				result.add(new TimestampInterval<String>(plotID, interval[0], interval[1]));
			}
		});		

		return result;
	}

	@Override
	public ArrayList<TimestampInterval<String>> getPlotTimeSpansOfGeneralStation(String generalStationName) throws RemoteException {
		System.out.println("*********************************************  getTimeSpanListByGeneralStation   "+generalStationName);
		ArrayList<TimestampInterval<String>> result = new ArrayList<TimestampInterval<String>>();
		GeneralStation generalStation = tsdb.getGeneralStation(generalStationName);
		if(generalStation==null) {
			log.warn("generalStationName not found: "+generalStationName);
			return null;
		}
		generalStation.getStationAndVirtualPlotNames().forEach(plotID->{
			long[] interval = tsdb.getTimeInterval(plotID);
			if(interval!=null) {
				result.add(new TimestampInterval<String>(plotID, interval[0], interval[1]));
			}
		});

		return result;
	}

	@Override
	public ArrayList<TimestampInterval<String>> getPlotTimeSpansOfRegion(String regionName) throws RemoteException {
		ArrayList<TimestampInterval<String>> result = new ArrayList<TimestampInterval<String>>();
		tsdb.getGeneralStations(regionName).forEach(generalStation->{
			generalStation.getStationAndVirtualPlotNames().forEach(plotID->{
				long[] interval = tsdb.getTimeInterval(plotID);
				if(interval!=null) {
					result.add(new TimestampInterval<String>(plotID, interval[0], interval[1]));
				}
			});	
		});
		return result;
	}

	// ------------------------------- logger

	@Override
	public LoggerType[] getLoggerTypes() {
		return tsdb.getLoggerTypes().toArray(new LoggerType[0]);
	}

	@Override
	public LoggerType getLoggerType(String loggerTypeName) {
		return tsdb.getLoggerType(loggerTypeName);
	}

	// ------------------------------------ source catalog

	@Override
	public SourceEntry[] getSourceCatalogEntries() {
		return tsdb.sourceCatalog.getEntries().toArray(new SourceEntry[0]);
	}

	// ------------------------------------ console

	Long command_counter=0l;

	Map<Long,Pair<Thread,ConsoleRunner>> commandThreadMap = new ConcurrentHashMap<Long,Pair<Thread,ConsoleRunner>>();

	private long createCommandThreadId() {
		synchronized (command_counter) {
			final long commandThreadId = command_counter;
			command_counter++;
			return commandThreadId;
		}
	}

	@Override
	public long execute_console_command(String input_line) throws RemoteException {
		final long commandThreadId = createCommandThreadId();
		ConsoleRunner consolerunner = new ConsoleRunner(tsdb, input_line);
		Thread commandThread = new Thread(consolerunner);		
		commandThread.start();
		System.out.println("execute_console_command: "+input_line+"     "+command_counter);
		commandThreadMap.put(commandThreadId, new Pair<Thread,ConsoleRunner>(commandThread,consolerunner));
		return commandThreadId;
	}

	@Override
	public Pair<Boolean,String[]> console_comand_get_output(long commandThreadId) throws RemoteException {
		Pair<Thread,ConsoleRunner> pair = commandThreadMap.get(commandThreadId);
		if(pair==null) {
			return null;
		}
		System.out.println("console_comand_get_output: "+commandThreadId);
		Thread commandThread = pair.a;
		ConsoleRunner consolerunner = pair.b;
		boolean running = commandThread.isAlive(); //first
		String[] output_lines = consolerunner.getOutputLines();  //and then
		if(!running) {
			commandThreadMap.remove(commandThreadId);
		}

		return new Pair<Boolean,String[]>(running,output_lines);
	}


	//-------------------------------------- query

	@Override
	public TimestampSeries plot(String queryType, String plotID, String[] columnNames, AggregationInterval aggregationInterval, DataQuality dataQuality, boolean interpolated, Long start, Long end) {
		if(AggregationInterval.RAW==aggregationInterval) {
			try {
				RawSourceTemp rawSource = RawSourceTemp.of(tsdb, plotID, columnNames);
				if(rawSource!=null) {
					TsIterator it = rawSource.get(start, end);
					if(it==null||!it.hasNext()) {
						return null;
					}
					return it.toTimestampSeries();
				}
			} catch (Exception e) {
				log.error(e);
				return null;
			}

		}




		Node node = null;
		if(queryType==null||queryType.equals("standard")) {		
			node = QueryPlan.plot(tsdb, plotID, columnNames, aggregationInterval, dataQuality, interpolated);
		} else if(queryType.equals("difference")) {
			node = QueryPlan.plotDifference(tsdb, plotID, columnNames, aggregationInterval, dataQuality, interpolated);
		} else {
			log.error("queryType unknown");
		}
		if(node==null) {
			return null;
		}
		TsIterator it = node.get(start, end);
		if(it==null||!it.hasNext()) {
			return null;
		}
		//System.out.println(it.getProcessingChain().getText());
		return it.toTimestampSeries();
	}

	@Override
	public TimestampSeries cache(String streamName, String[] columnNames, AggregationInterval aggregationInterval) {
		Node node =  QueryPlan.cache(tsdb, streamName, columnNames, aggregationInterval);
		if(node==null) {
			return null;
		}
		TsIterator it = node.get(null, null);
		if(it==null||!it.hasNext()) {
			return null;
		}
		return it.toTimestampSeries();		
	}

	@Override
	public TsIterator query_raw(String plotID, String[] querySchema, Long queryStart, Long queryEnd) {
		QueryProcessor qp = new QueryProcessor(tsdb);
		return qp.query_raw(plotID, querySchema, queryStart, queryEnd);
	}	
}
