package tsdb.loader;

import java.util.ArrayList;
import java.util.List;

import tsdb.StationProperties;
import tsdb.raw.TimeSeriesEntry;
import tsdb.raw.TimestampSeries;
import de.umr.jepc.store.Event;

public class Loader_pu1 extends AbstractLoader {
	
	private enum ProcessingType {NONE,COPY,P_RT_NRT};

	private ProcessingType[] processingTypes = null;
	private float calib_coefficient_P_RT_NRT = Float.NaN;
	private int pos_P_RT_NRT = -1;

	public Loader_pu1(String[] inputSchema, StationProperties properties, ASCTimeSeries csvtimeSeries) {
		super(inputSchema,properties, csvtimeSeries);
	}

	@Override
	protected void createResultSchema() {
		final String P_RT_NRT_I = "P_RT_NRT_I";
		resultSchema = new String[inputSchema.length];
		for(int schemaIndex=0;schemaIndex<inputSchema.length;schemaIndex++) {
			switch(inputSchema[schemaIndex]) {
			case P_RT_NRT_I:
				resultSchema[schemaIndex] = "P_RT_NRT";
				break;
			default:
				resultSchema[schemaIndex] = inputSchema[schemaIndex];	
			}
		}
	}
	
	@Override
	protected void createProcessingTypes() {
		processingTypes = new ProcessingType[resultSchema.length];
		for(int schemaIndex=0; schemaIndex<resultSchema.length; schemaIndex++) {
			switch(resultSchema[schemaIndex]) {
			case "P_RT_NRT":
				calib_coefficient_P_RT_NRT = properties.getFloatProperty("pu1_P_RT_NRT");
				processingTypes[schemaIndex] = ProcessingType.P_RT_NRT;
				break;
			default:
				processingTypes[schemaIndex] = ProcessingType.COPY;
			}
		}		

	}

	@Override
	protected List<Event> toEvents(TimestampSeries timestampSeries) {
		List<Event> eventList = new ArrayList<Event>(timestampSeries.entryList.size());
		for(TimeSeriesEntry entry:timestampSeries.entryList) {
			Float[] eventData = new Float[sourcePos.length];
			for(int schemaIndex=0;schemaIndex<sourcePos.length;schemaIndex++) {
				int sourceIndex = sourcePos[schemaIndex];
				if(sourceIndex==-1) {
					eventData[schemaIndex] = Float.NaN;
				} else {						
					switch(processingTypes[sourceIndex]) {
					case P_RT_NRT: // value <- raw * calib_coefficient
						eventData[schemaIndex] = entry.data[sourceIndex]*calib_coefficient_P_RT_NRT;
						break;					
					case COPY:
						eventData[schemaIndex] = entry.data[sourceIndex];
						break;
					default:
						log.warn("processingType unknown: "+processingTypes[sourceIndex]);
						eventData[schemaIndex] = Float.NaN;
					}						
				}
			}
			eventList.add(new Event(eventData, entry.timestamp));
		}
		return eventList;
	}

	

}
