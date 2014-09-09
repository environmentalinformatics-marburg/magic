package tsdb.loader;

import java.util.ArrayList;
import java.util.List;

import tsdb.StationProperties;
import tsdb.raw.TimeSeriesEntry;
import tsdb.raw.TimestampSeries;
import de.umr.jepc.store.Event;

public class Loader_gp1 extends AbstractLoader {
	
	private enum ProcessingType {NONE,COPY,WD,WV};

	private ProcessingType[] processingTypes = null;
	private float calib_coefficient_wd = Float.NaN;
	private float calib_coefficient_wv = Float.NaN;

	public Loader_gp1(String[] inputSchema, StationProperties properties, ASCTimeSeries csvtimeSeries) {
		super(inputSchema,properties, csvtimeSeries);
	}

	@Override
	protected void createResultSchema() {
		resultSchema = new String[inputSchema.length];
		for(int schemaIndex=0;schemaIndex<inputSchema.length;schemaIndex++) {
			switch(inputSchema[schemaIndex]) {
			case "WD_R":
				resultSchema[schemaIndex] = "WD";
				break;
			case "WV_I":
				resultSchema[schemaIndex] = "WV";
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
			case "WD":
				calib_coefficient_wd = properties.getFloatProperty("pu2_1");
				processingTypes[schemaIndex] = ProcessingType.WD;
				break;
			case "WV":
				calib_coefficient_wv = properties.getFloatProperty("pu2_2");
				processingTypes[schemaIndex] = ProcessingType.WV;
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
					case WD: // value <- raw * calib_coefficient
						eventData[schemaIndex] = entry.data[sourceIndex]*calib_coefficient_wd;
						break;
					case WV: // value <- raw * calib_coefficient
						eventData[schemaIndex] = entry.data[sourceIndex]*calib_coefficient_wv;
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
