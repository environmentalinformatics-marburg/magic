package tsdb.loader.ki;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import tsdb.DataRow;
import tsdb.raw.TsEntry;
import tsdb.raw.TimestampSeries;
import tsdb.util.Util;

class Loader_manual_tfi {
	
	private static final Logger log = LogManager.getLogger();

	private final TimestampSeries timestampSeries;
	private String[] inputSchema = null;

	private int[] sourcePos = null;

	public Loader_manual_tfi(TimestampSeries timestampSeries) {
		this.timestampSeries = timestampSeries;
		this.inputSchema = timestampSeries.sensorNames;
	}

	protected boolean createSourcePos(String[] targetSchema) {
		//sourcePos[targetIndex] => sourceIndex
		sourcePos = new int[targetSchema.length];
		for(int i=0;i<sourcePos.length;i++) {
			sourcePos[i] = -1;
		}
		boolean containsValidColumns = false;
		Map<String, Integer> targetIndexMap = Util.stringArrayToMap(targetSchema);
		for(int sourceIndex=0;sourceIndex<inputSchema.length;sourceIndex++) {
			String sensorName = inputSchema[sourceIndex];
			if(sensorName!=null) {
				if(targetIndexMap.containsKey(sensorName)) {
					sourcePos[targetIndexMap.get(sensorName)] = sourceIndex;
					containsValidColumns = true;
				} else {
					log.warn("sensor name not in target schema "+sensorName+" "+getClass().toGenericString());
				}
			} else {
				log.warn("no sensor translation: "+inputSchema[sourceIndex]);
			}

		}
		return containsValidColumns;
	}

	public List<DataRow> load(String[] targetSchema) {
		boolean containsValidColumns = createSourcePos(targetSchema);
		if(containsValidColumns) {
			return toEvents();			
		} else {
			return null;
		}		
	}

	public List<DataRow> toEvents() {
		List<DataRow> eventList = new ArrayList<DataRow>(timestampSeries.entryList.size());
		for(TsEntry entry:timestampSeries.entryList) {
			Float[] eventData = new Float[sourcePos.length];
			for(int schemaIndex=0;schemaIndex<sourcePos.length;schemaIndex++) {
				int sourceIndex = sourcePos[schemaIndex];
				if(sourceIndex==-1) {
					eventData[schemaIndex] = Float.NaN;
				} else {
					eventData[schemaIndex] = entry.data[sourceIndex];								
				}
			}
			eventList.add(new DataRow(eventData, entry.timestamp));
		}
		return eventList;
	}
}
