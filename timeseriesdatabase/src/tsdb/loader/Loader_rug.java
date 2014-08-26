package tsdb.loader;

import java.util.ArrayList;
import java.util.List;

import tsdb.StationProperties;
import tsdb.raw.TimeSeriesEntry;
import tsdb.raw.TimestampSeries;
import de.umr.jepc.store.Event;

public class Loader_rug extends AbstractLoader {

	private enum ProcessingType {NONE,COPY};

	private ProcessingType[] processingTypes = null;

	public Loader_rug(String[] inputSchema, StationProperties properties, ASCTimeSeries csvtimeSeries) {
		super(inputSchema,properties, csvtimeSeries);
	}

	@Override
	protected void createResultSchema() {
		resultSchema = new String[inputSchema.length];
		for(int schemaIndex=0;schemaIndex<inputSchema.length;schemaIndex++) {
			switch(inputSchema[schemaIndex]) {
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
