package timeseriesdatabase.loader;

import java.util.List;
import java.util.Map;

import org.apache.logging.log4j.Logger;

import de.umr.jepc.store.Event;
import timeseriesdatabase.Station;
import timeseriesdatabase.StationProperties;
import timeseriesdatabase.raw.ASCTimeSeries;
import timeseriesdatabase.raw.TimestampSeries;
import util.Util;

public abstract class AbstractLoader {

	protected static final Logger log = Util.log;

	protected final String[] inputSchema;
	protected final StationProperties properties;
	protected final ASCTimeSeries csvtimeSeries;
	
	protected String[] resultSchema = null;
	protected int[] sourcePos;

	public AbstractLoader(String[] inputSchema, StationProperties properties, ASCTimeSeries csvtimeSeries) {
		this.inputSchema = inputSchema;
		this.properties = properties;
		this.csvtimeSeries = csvtimeSeries;
	}

	protected abstract void createProcessingTypes();
	protected abstract void createResultSchema();	
	protected abstract List<Event> toEvents(TimestampSeries timestampSeries);

	protected boolean createSourcePos(String[] targetSchema) {
		//sourcePos[targetIndex] => sourceIndex
		sourcePos = new int[targetSchema.length];
		for(int i=0;i<sourcePos.length;i++) {
			sourcePos[i] = -1;
		}
		boolean containsValidColumns = false;
		Map<String, Integer> targetIndexMap = Util.stringArrayToMap(targetSchema);
		for(int sourceIndex=0;sourceIndex<resultSchema.length;sourceIndex++) {
			String sensorName = resultSchema[sourceIndex];
			if(sensorName!=null) {
				if(targetIndexMap.containsKey(sensorName)) {
					sourcePos[targetIndexMap.get(sensorName)] = sourceIndex;
					containsValidColumns = true;
				} else {
					log.warn("sensor name not in target schema "+sensorName+" "+getClass().toGenericString());
				}
			} else {
				log.warn("no sensor translation: "+inputSchema[sourceIndex]+" in "+csvtimeSeries.filename);
			}

		}
		return containsValidColumns;
	}

	public List<Event> load(Station station, String[] targetSchema, TimestampSeries timestampSeries) {
		//System.out.println("inputSchema: "+Util.arrayToString(inputSchema));
		createResultSchema();
		createProcessingTypes();

		//System.out.println("resultSchema: "+Util.arrayToString(resultSchema));

		boolean containsValidColumns = createSourcePos(targetSchema);
		if(containsValidColumns) {
			return toEvents(timestampSeries);			
		} else {
			return null;
		}		
	}

	public String[] getResultSchema() {
		return resultSchema;
	}

	
}
