package processinggraph;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.function.Function;
import java.util.stream.Collector;
import java.util.stream.Stream;

import timeseriesdatabase.DataQuality;
import timeseriesdatabase.Station;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.VirtualPlot;
import timeseriesdatabase.aggregated.Interpolator;
import timeseriesdatabase.aggregated.TimeSeries;
import timeseriesdatabase.aggregated.iterator.BadInterpolatedRemoveIterator;
import timeseriesdatabase.aggregated.iterator.LinearIterpolationIterator;
import util.Util;
import util.iterator.TimeSeriesIterator;

public class Interpolated extends Continuous_temp.Abstract {

	final static int MIN_STATION_INTERPOLATION_COUNT = 2;
	final static int STATION_INTERPOLATION_COUNT = 15;		
	final static int TRAINING_TIME_INTERVAL = 60*24*7*4; // in minutes;  four weeks

	final Continuous_temp source;  //not null
	final Continuous_temp[] interpolationSources;  //not null
	final String[] interpolationSchema;  //not null

	protected Interpolated(TimeSeriesDatabase timeSeriesDatabase, Continuous_temp source, Continuous_temp[] interpolationSources, String[] interpolationSchema) {		
		super(timeSeriesDatabase);
		Util.throwNull(source,interpolationSources,interpolationSchema);
		if(!source.isContinuous()) {
			throw new RuntimeException("source not continuous");
		}
		this.source = source;
		for(Continuous_temp interpolationSource:interpolationSources) {
			if(!interpolationSource.isContinuous()) {
				throw new RuntimeException("interpolation source not continuous");
			}
		}
		this.interpolationSources = interpolationSources;
		this.interpolationSchema = interpolationSchema;
	}
	
	public static Continuous_temp create(TimeSeriesDatabase timeSeriesDatabase, String plotID, String[] querySchema, ContinuousGen sourceGen) {
		VirtualPlot virtualPlot = timeSeriesDatabase.getVirtualPlot(plotID);
		if(virtualPlot!=null) {
			return createFromVirtual(timeSeriesDatabase, virtualPlot, querySchema, sourceGen);
		} 
		Station station = timeSeriesDatabase.getStation(plotID);
		if(station!=null) {
			return createFromStation(timeSeriesDatabase,station,querySchema, sourceGen);
		}
		throw new RuntimeException("station not found");
	}

	public static Continuous_temp createFromStation(TimeSeriesDatabase timeSeriesDatabase, Station station, String[] querySchema, ContinuousGen sourceGen) {
		if(querySchema==null) {
			querySchema = station.getSchema();
		} else {
			querySchema = station.getValidSchemaEntries(querySchema);
		}
		if(querySchema.length==0) {
			throw new RuntimeException("empty schema");
		}		
		Continuous_temp source = sourceGen.get(station.stationID, querySchema);	

		String[] interpolationSchema = Arrays.asList(querySchema)
				.stream()
				.filter(sensorName -> timeSeriesDatabase.getSensor(sensorName).useInterpolation)
				.toArray(String[]::new);

		Concrete[] interpolationSources = station.nearestStations
				.stream()
				.limit(STATION_INTERPOLATION_COUNT)
				.filter(sourceStation -> sourceStation.getValidSchemaEntries(interpolationSchema).length>0)
				.map(sourceStation -> sourceGen.get(sourceStation.stationID, sourceStation.getValidSchemaEntries(interpolationSchema)))
				.toArray(Concrete[]::new);

		if(interpolationSources.length<MIN_STATION_INTERPOLATION_COUNT) {
			return source;
		} else {
			return new Interpolated(timeSeriesDatabase, source, interpolationSources, interpolationSchema);
		}		
	}
	
	public static Continuous_temp createFromVirtual(TimeSeriesDatabase timeSeriesDatabase, VirtualPlot virtualPlot, String[] querySchema, ContinuousGen sourceGen) {
		if(querySchema==null) {
			querySchema = virtualPlot.getSchema();
		} else {
			querySchema = virtualPlot.getValidSchemaEntries(querySchema);
		}
		if(querySchema.length==0) {
			throw new RuntimeException("empty schema");
		}		
		Continuous_temp source = sourceGen.get(virtualPlot.plotID, querySchema);		

		String[] interpolationSchema = Arrays.asList(querySchema)
				.stream()
				.filter(sensorName -> timeSeriesDatabase.getSensor(sensorName).useInterpolation)
				.toArray(String[]::new);

		Concrete[] interpolationSources = virtualPlot.nearestVirtualPlots
				.stream()
				.limit(STATION_INTERPOLATION_COUNT)
				.filter(sourceVirtualPlot -> sourceVirtualPlot.getValidSchemaEntries(interpolationSchema).length>0)
				.map(sourceVirtualPlot -> sourceGen.get(sourceVirtualPlot.plotID, sourceVirtualPlot.getValidSchemaEntries(interpolationSchema)))
				.toArray(Concrete[]::new);

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
		TimeSeriesIterator source_iterator = source.get(start, end);
		if(source_iterator==null||!source_iterator.hasNext()) {
			return null;
		}
		TimeSeries sourceTimeSeries = source_iterator.toTimeSeries();		
		int linearInterpolatedCount = Interpolator.processOneValueGaps(sourceTimeSeries);
		long interpolationStart = sourceTimeSeries.getFirstTimestamp();
		long interpolationEnd = sourceTimeSeries.getLastTimestamp();

		List<TimeSeries> interpolationTimeSeriesTemp = new ArrayList<TimeSeries>();
		int sourcesLinearInterpolationCount=0;
		for(Continuous_temp interpolationSource:interpolationSources) {
			TimeSeriesIterator it = interpolationSource.getExactly(interpolationStart, interpolationEnd);//TODO
			if(it!=null&&it.hasNext()) {
				TimeSeries timeSeries = it.toTimeSeries();
				sourcesLinearInterpolationCount += Interpolator.processOneValueGaps(timeSeries);
				interpolationTimeSeriesTemp.add(timeSeries);
			}
		}
		TimeSeries[] interpolationTimeSeries = interpolationTimeSeriesTemp.toArray(new TimeSeries[0]);
		

		int interpolatedCount = 0;
		for(String interpolationName:interpolationSchema) {
			interpolatedCount += Interpolator.process(interpolationTimeSeries, sourceTimeSeries, interpolationName);
		}
		System.out.println("interpolated: linear: "+linearInterpolatedCount+"   multi linear: "+interpolatedCount+"   sources linear: "+sourcesLinearInterpolationCount);

		sourceTimeSeries.hasDataInterpolatedFlag = true;		
		TimeSeriesIterator clipIterator = sourceTimeSeries.timeSeriesIteratorCLIP(queryStart, queryEnd);
		TimeSeriesIterator resultIterator = clipIterator;
		if(interpolatedCount>0) {
			resultIterator = new BadInterpolatedRemoveIterator(timeSeriesDatabase, clipIterator);
		}
		return resultIterator;
	}

	@Override
	public Station getSourceStation() {
		return source.getSourceStation();
	}

	@Override
	public String[] getSchema() {
		return source.getSchema();
	}

	@Override
	public TimeSeriesIterator getExactly(long start, long end) {
		return get(start,end);
	}
	
	@Override
	public boolean isContinuous() {
		return source.isContinuous();
	}	

	@Override
	public boolean isConstantTimestep() {
		return source.isConstantTimestep();
	}
}
