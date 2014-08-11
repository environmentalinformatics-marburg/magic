package timeseriesdatabase;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.HashSet;
import java.util.Iterator;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;
import java.util.stream.Stream;

import org.apache.logging.log4j.Logger;

import com.sun.xml.internal.messaging.saaj.packaging.mime.util.QEncoderStream;

import de.umr.jepc.Attribute;
import util.TimestampInterval;
import util.Util;

/**
 * plot with data from a collection of data streams changing in time
 * @author woellauer
 *
 */
public class VirtualPlot {

	private static final Logger log = Util.log;
	
	private final TimeSeriesDatabase timeSeriesDatabase;

	public final String plotID;
	public final String generalStationName;

	public final List<TimestampInterval<StationProperties>> intervalList;

	public VirtualPlot(TimeSeriesDatabase timeSeriesDatabase, String plotID, String generalStationName) {
		this.timeSeriesDatabase = timeSeriesDatabase;
		this.plotID = plotID;
		this.generalStationName = generalStationName;
		this.intervalList = new ArrayList<TimestampInterval<StationProperties>>();
	}

	public String[] getSchema() {
		return intervalList.stream()
				.map(interval->{
					LoggerType loggerType = timeSeriesDatabase.getLoggerType(interval.value.get_logger_type_name());
					if(loggerType==null) {
						throw new RuntimeException("logger type not found: "+interval.value.get_logger_type_name());
					}
					return loggerType;
					})
				.distinct()
				.flatMap(loggerType->Arrays.stream(loggerType.sensorNames))
				.distinct()
				.toArray(String[]::new);
	}

	public void addStationEntry(Station station, StationProperties properties) {
		intervalList.add(new TimestampInterval<StationProperties>(properties, properties.get_date_start(), properties.get_date_end()));
	}

	private static boolean overlaps(Long queryStart, Long queryEnd, Long iStart, Long iEnd) {
		if(queryStart==null) {
			queryStart = Long.MIN_VALUE;
		}
		if(queryEnd==null) {
			queryEnd = Long.MAX_VALUE;
		}
		if(iStart==null) {
			iStart = Long.MIN_VALUE;
		}
		if(iEnd==null) {
			iEnd = Long.MAX_VALUE;
		}		
		return queryStart <= iEnd && iStart <= queryEnd;
	}

	/**
	 * Get list of stations with overlapping entries in time interval start - end
	 * @param queryStart
	 * @param queryEnd
	 * @param schema
	 * @return
	 */
	public List<TimestampInterval<StationProperties>> getStationList(Long queryStart, Long queryEnd, String[] schema) {		
		if(schema==null) {
			schema = getSchema();
		}		
		intervalList.sort( (a,b) -> {
			if(a.start==null) {
				if(b.start==null) {
					return 0;
				} else {
					return -1; // start1==null start2!=null
				}
			} else {
				if(b.start==null) {
					return 1; // start1!=null start2==null
				} else {
					return (a.start < b.start) ? -1 : ((a.start == b.start) ? 0 : 1);
				}
			}
		});

		Iterator<TimestampInterval<StationProperties>> it = intervalList.iterator();


		List<TimestampInterval<StationProperties>> resultIntervalList = new ArrayList<TimestampInterval<StationProperties>>();
		while(it.hasNext()) {
			TimestampInterval<StationProperties> interval = it.next();
			if(schemaOverlaps(timeSeriesDatabase.getLoggerType(interval.value.get_logger_type_name()).sensorNames,schema)) {
				if(overlaps(queryStart, queryEnd, interval.start, interval.end)) {
					resultIntervalList.add(interval);
				}
			}
		}
		System.out.println("resultIntervalList: "+resultIntervalList.size());
		return resultIntervalList;
	}

	private boolean schemaOverlaps(String[] schema, String[] schema2) {
		for(String name:schema) {
			for(String name2:schema2) {
				if(name.equals(name2)) {
					return true;
				}
			}
		}
		return false;
	}
}
