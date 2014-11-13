package tsdb.loader.ki.type;

import java.util.ArrayList;
import java.util.List;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import tsdb.StationProperties;
import tsdb.loader.ki.ASCTimeSeries;
import tsdb.raw.TsEntry;
import tsdb.raw.TimestampSeries;
import de.umr.jepc.store.Event;

class Loader_wxt extends AbstractLoader {
	
	private static final Logger log = LogManager.getLogger();

	private enum ProcessingType {NONE,COPY,SWDR_300,SWUR_300,LWDR_300,LWUR_300};
	
	private ProcessingType[] processingTypes = null;

	private float calib_coefficient_SWDR_300 = Float.NaN;
	private float calib_coefficient_SWUR_300 = Float.NaN;
	private float calib_coefficient_LWDR_300 = Float.NaN;
	private float calib_coefficient_LWUR_300 = Float.NaN;
	
	private int pos_T_CNR = -1;	

	public Loader_wxt(String[] inputSchema, StationProperties properties, String sourceInfo) {
		super(inputSchema,properties, sourceInfo);
	}

	@Override
	protected void createResultSchema() {
		final String PLACE_HOLDER_W_R_300_U = "PLACE_HOLDER_W_R_300_U";
		resultSchema = new String[inputSchema.length];
		int PLACE_HOLDER_W_R_300_U_count = 0;
		for(int schemaIndex=0;schemaIndex<inputSchema.length;schemaIndex++) {
			switch(inputSchema[schemaIndex]) {
			case PLACE_HOLDER_W_R_300_U:
				//TODO: reverse entries for some time interval
				PLACE_HOLDER_W_R_300_U_count++;
				switch(PLACE_HOLDER_W_R_300_U_count) {
				case 1:
					resultSchema[schemaIndex] = "SWDR_300";
					break;
				case 2:
					resultSchema[schemaIndex] = "SWUR_300";
					break;
				case 3:
					resultSchema[schemaIndex] = "LWDR_300";
					break;
				case 4:
					resultSchema[schemaIndex] = "LWUR_300";
					break;
				default:
					log.warn("no real name for column "+schemaIndex+"  "+inputSchema[schemaIndex]);
					resultSchema[schemaIndex] = inputSchema[schemaIndex];
				}
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
			case "SWDR_300":
				calib_coefficient_SWDR_300 = properties.getFloatProperty("wxt_SWDR_300");
				processingTypes[schemaIndex] = ProcessingType.SWDR_300;
				break;
			case "SWUR_300":
				calib_coefficient_SWUR_300 = properties.getFloatProperty("wxt_SWUR_300");
				processingTypes[schemaIndex] = ProcessingType.SWUR_300;
				break;
			case "LWDR_300":
				calib_coefficient_LWDR_300 = properties.getFloatProperty("wxt_LWDR_300");
				processingTypes[schemaIndex] = ProcessingType.LWDR_300;
				break;
			case "LWUR_300":
				calib_coefficient_LWUR_300 = properties.getFloatProperty("wxt_LWUR_300");
				processingTypes[schemaIndex] = ProcessingType.LWUR_300;
				break;
			case "T_CNR":
				pos_T_CNR = schemaIndex;
				processingTypes[schemaIndex] = ProcessingType.COPY; //TODO: maybe change
				break;
			default:
				processingTypes[schemaIndex] = ProcessingType.COPY;
			}
		}
	}

	@Override
	protected List<Event> toEvents(TimestampSeries timestampSeries) {
		List<Event> eventList = new ArrayList<Event>(timestampSeries.entryList.size());
		for(TsEntry entry:timestampSeries.entryList) {
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
					case SWDR_300: //value <- (raw * 1000) / calib_coefficient
						eventData[schemaIndex] = (entry.data[sourceIndex]*1000f)/calib_coefficient_SWDR_300;
						break;
					case SWUR_300: //value <- (raw * 1000) / calib_coefficient
						eventData[schemaIndex] = (entry.data[sourceIndex]*1000f)/calib_coefficient_SWUR_300;
						break; 
					case LWDR_300: //value <- ((raw * 1000) / calib_coefficient) + (5.672E-08 * (T_CNR + 273.15)**4)
						eventData[schemaIndex] = (entry.data[sourceIndex]*1000f)/calib_coefficient_LWDR_300 + (5.672E-08f*((float)Math.pow(entry.data[pos_T_CNR] + 273.15, 4)));
						break;
					case LWUR_300: //value <- ((raw * 1000) / calib_coefficient) + (5.672E-08 * (T_CNR + 273.15)**4)
						eventData[schemaIndex] = (entry.data[sourceIndex]*1000f)/calib_coefficient_LWUR_300 + (5.672E-08f*((float)Math.pow(entry.data[pos_T_CNR] + 273.15, 4)));
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
