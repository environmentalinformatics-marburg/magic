package processinggraph;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collector;
import java.util.stream.Stream;

import timeseriesdatabase.DataQuality;
import timeseriesdatabase.Station;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.VirtualPlot;
import timeseriesdatabase.aggregated.Interpolator;
import timeseriesdatabase.aggregated.TimeSeries;
import timeseriesdatabase.aggregated.iterator.BadInterpolatedRemoveIterator;
import util.Util;
import util.iterator.TimeSeriesIterator;

public class Interpolated extends Node {

	final static int MIN_STATION_INTERPOLATION_COUNT = 2;
	final static int STATION_INTERPOLATION_COUNT = 15;		
	final static int TRAINING_TIME_INTERVAL = 60*24*7*4; // in minutes;  four weeks

	final Continuous source;
	final Continuous[] interpolationSources;
	final String[] interpolationSchema;

	public Interpolated(TimeSeriesDatabase timeSeriesDatabase, Continuous source, Continuous[] interpolationSources, String[] interpolationSchema) {		
		super(timeSeriesDatabase);
		if(!source.isContinuous()) {
			throw new RuntimeException("source not continuous");
		}
		this.source = source;
		for(Node interpolationSource:interpolationSources) {
			if(!interpolationSource.isContinuous()) {
				throw new RuntimeException("interpolation source not continuous");
			}
		}
		this.interpolationSources = interpolationSources;
		this.interpolationSchema = interpolationSchema;
	}

	public static Node create(TimeSeriesDatabase timeSeriesDatabase, String plotID, String[] querySchema, DataQuality dataQuality) {
		VirtualPlot virtualPlot = timeSeriesDatabase.getVirtualPlot(plotID);
		if(virtualPlot!=null) {
			return createFromVirtual(timeSeriesDatabase, virtualPlot, querySchema, dataQuality);
		} 
		Station station = timeSeriesDatabase.getStation(plotID);
		if(station!=null) {
			return createFromStation(timeSeriesDatabase,station,querySchema,dataQuality);
		}
		throw new RuntimeException("station not found");
	}

	public static Node createFromStation(TimeSeriesDatabase timeSeriesDatabase, Station station, String[] querySchema, DataQuality dataQuality) {
		if(querySchema==null) {
			querySchema = station.getSchema();
		} else {
			querySchema = station.getValidSchemaEntries(querySchema);
		}
		if(querySchema.length==0) {
			throw new RuntimeException("empty schema");
		}		
		Continuous source = Continuous.create(timeSeriesDatabase, station.stationID, querySchema, dataQuality);		

		String[] interpolationSchema = Arrays.asList(querySchema)
				.stream()
				.filter(sensorName -> timeSeriesDatabase.getSensor(sensorName).useInterpolation)
				.toArray(String[]::new);

		Continuous[] interpolationSources = station.nearestStations
				.stream()
				.limit(STATION_INTERPOLATION_COUNT)
				.filter(sourceStation -> sourceStation.getValidSchemaEntries(interpolationSchema).length>0)
				.map(sourceStation -> Continuous.create(timeSeriesDatabase, sourceStation.stationID, sourceStation.getValidSchemaEntries(interpolationSchema)))
				.toArray(Continuous[]::new);

		if(interpolationSources.length<MIN_STATION_INTERPOLATION_COUNT) {
			return source;
		} else {
			return new Interpolated(timeSeriesDatabase, source, interpolationSources, interpolationSchema);
		}		
	}
	
	public static Node createFromVirtual(TimeSeriesDatabase timeSeriesDatabase, VirtualPlot virtualPlot, String[] querySchema, DataQuality dataQuality) {
		if(querySchema==null) {
			querySchema = virtualPlot.getSchema();
		} else {
			querySchema = virtualPlot.getValidSchemaEntries(querySchema);
		}
		if(querySchema.length==0) {
			throw new RuntimeException("empty schema");
		}		
		Continuous source = Continuous.create(timeSeriesDatabase, virtualPlot.plotID, querySchema, dataQuality);		

		String[] interpolationSchema = Arrays.asList(querySchema)
				.stream()
				.filter(sensorName -> timeSeriesDatabase.getSensor(sensorName).useInterpolation)
				.toArray(String[]::new);

		Continuous[] interpolationSources = virtualPlot.nearestVirtualPlots
				.stream()
				.limit(STATION_INTERPOLATION_COUNT)
				.filter(sourceVirtualPlot -> sourceVirtualPlot.getValidSchemaEntries(interpolationSchema).length>0)
				.map(sourceVirtualPlot -> Continuous.create(timeSeriesDatabase, sourceVirtualPlot.plotID, sourceVirtualPlot.getValidSchemaEntries(interpolationSchema)))
				.toArray(Continuous[]::new);

		if(interpolationSources.length<MIN_STATION_INTERPOLATION_COUNT) {
			return source;
		} else {
			return new Interpolated(timeSeriesDatabase, source, interpolationSources, interpolationSchema);
		}
	}

	@Override
	public TimeSeriesIterator get(Long start, Long end) {
		Long queryStart = start;
		Long queryEnd = end;
		start =  Util.ifnull(start, x->x-TRAINING_TIME_INTERVAL);
		TimeSeries sourceTimeSeries = source.get(start, end).toTimeSeries();
		long interpolationStart = sourceTimeSeries.getFirstTimestamp();
		long interpolationEnd = sourceTimeSeries.getLastTimestamp();

		List<TimeSeries> interpolationTimeSeriesTemp = new ArrayList<TimeSeries>();
		for(Continuous interpolationSource:interpolationSources) {
			TimeSeriesIterator it = interpolationSource.getExactly(interpolationStart, interpolationEnd);
			if(it!=null&&it.hasNext()) {
				interpolationTimeSeriesTemp.add(it.toTimeSeries());
			}
		}
		TimeSeries[] interpolationTimeSeries = interpolationTimeSeriesTemp.toArray(new TimeSeries[0]);
		

		int interpolatedCount = 0;
		for(String interpolationName:interpolationSchema) {
			interpolatedCount += Interpolator.process(interpolationTimeSeries, sourceTimeSeries, interpolationName);
		}
		System.out.println("interpolatedCount: "+interpolatedCount);

		sourceTimeSeries.hasDataInterpolatedFlag = true;		
		TimeSeriesIterator clipIterator = sourceTimeSeries.timeSeriesIteratorCLIP(queryStart, queryEnd);
		if(interpolatedCount==0) {
			return clipIterator;
		} else {
			return new BadInterpolatedRemoveIterator(timeSeriesDatabase, clipIterator);
		}		
	}

	@Override
	public boolean isContinuous() {
		return true;
	}



}
