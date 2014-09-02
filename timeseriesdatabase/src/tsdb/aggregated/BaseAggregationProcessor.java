package tsdb.aggregated;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.apache.logging.log4j.Logger;

import tsdb.Sensor;
import tsdb.TsDB;
import tsdb.raw.TimeSeriesEntry;
import tsdb.raw.TimestampSeries;
import tsdb.util.TimeSeriesSchema;
import tsdb.util.Util;
import de.umr.jepc.store.Event;

/**
 * processes raw sensor data to aggregated data in base time interval steps
 * 
 * implemented processing:
 * - check if query parameters are in station type schema
 * - database columns are projected to query parameters
 * - only data in query time interval is processed
 * - check if value is in physical valid range
 * - empty rows and gaps are not part of the result
 * - empty columns are not in the resulting TimeSeries Object
 * - all (valid) data in one base time interval is aggregated with special treatment for wind direction aggregate
 * 
 * @author woellauer
 *
 */
@Deprecated
public class BaseAggregationProcessor {

	private static final Logger log = Util.log;

	String[] parameterNames;
	Sensor[] sensors;
	int[] eventPos;// mapping of input event columns to output data columns
	boolean aggregate_wind_direction;	
	int wind_direction_pos;
	int wind_velocity_pos;

	//*** collector variables for aggregation
	int[] aggCnt;
	float[] aggSum;
	float[] aggMax;
	float wind_u_sum;
	float wind_v_sum;
	int wind_cnt;
	int[] columnEntryCounter;
	//***

	boolean checkPhysicalRange;
	boolean checkStepRange;

	public BaseAggregationProcessor(TsDB timeSeriesDatabase, String[] schemaSensorNames, String[] querySensorNames, boolean checkPhysicalRange, boolean checkStepRange) {
		this.checkPhysicalRange = checkPhysicalRange;
		this.checkStepRange = checkStepRange;
		parameterNames = getResultSchema(timeSeriesDatabase, schemaSensorNames, querySensorNames);
		sensors = timeSeriesDatabase.getSensors(new TimeSeriesSchema(parameterNames));		
		eventPos = Util.stringArrayToPositionIndexArray(parameterNames, schemaSensorNames, true, false);
		prepareWindDirectionAggregation();		
	}

	private void prepareWindDirectionAggregation() {
		wind_direction_pos=-1;
		wind_velocity_pos=-1;
		aggregate_wind_direction = false;
		for(int i=0;i<parameterNames.length;i++) {
			if(sensors[i].baseAggregationType==AggregationType.AVERAGE_WIND_DIRECTION) {
				if(wind_direction_pos==-1) {
					wind_direction_pos = i;
				} else {
					log.error("just one wind_direction sensor can be aggregated");
				}				
			}
			if(sensors[i].baseAggregationType==AggregationType.AVERAGE_WIND_VELOCITY) {
				if(wind_velocity_pos==-1) {
					wind_velocity_pos = i;
				} else {
					log.error("just one wind_velocity sensor can be aggregated");
				}				
			}			
		}

		if(wind_direction_pos>-1) {
			if(wind_velocity_pos>-1) {
				aggregate_wind_direction = true;
			} else {
				log.warn("wind_velocity sensor for wind_direction aggregation is missing");
			}
		}
	}

	private static String[] getResultSchema(TsDB timeSeriesDatabase, String[] schemaSensorNames, String[] querySensorNames) {
		if(querySensorNames==null) {// all available sensors are in result schema
			// create output schema of aggregated data in parameterNames
			ArrayList<String> parameterNameList = new ArrayList<String>();
			for(String sensorName:schemaSensorNames) {
				if(timeSeriesDatabase.baseAggregationExists(sensorName)) {
					parameterNameList.add(sensorName);				
				}
			}
			return (String[]) parameterNameList.toArray(new String[0]);			
		} else {		
			Map<String, Integer> schemaSensorNameMap = Util.stringArrayToMap(schemaSensorNames);
			ArrayList<String> parameterNameList = new ArrayList<String>();		
			for(String querySensorName:querySensorNames) {
				if(schemaSensorNameMap.containsKey(querySensorName)) {
					if(timeSeriesDatabase.baseAggregationExists(querySensorName)) {
						parameterNameList.add(querySensorName);
					} else {
						log.warn(querySensorName+" not available in base aggregation");
					}
				} else {
					log.warn(querySensorName+" not in schema: "+schemaSensorNameMap);
				}
			}
			return (String[]) parameterNameList.toArray(new String[0]);
		}
	}

	/**
	 * process collected data to aggregates
	 * @return result or null if there are no valid aggregates
	 */
	private float[] aggregateCollectedData() {
		float[] resultData = new float[parameterNames.length];	
		int validValueCounter=0; //counter of valid aggregates

		for(int i=0;i<parameterNames.length;i++) {					
			if(aggCnt[i]>0) {// at least one entry has been collected
				switch(sensors[i].baseAggregationType) {
				case AVERAGE:
				case AVERAGE_ZERO:	
				case AVERAGE_WIND_VELOCITY:	
					resultData[i] = aggSum[i]/aggCnt[i];
					validValueCounter++;
					columnEntryCounter[i]++;
					break;
				case SUM:
					resultData[i] = aggSum[i];
					validValueCounter++;
					columnEntryCounter[i]++;
					break;
				case MAXIMUM:
					resultData[i] = aggMax[i];
					validValueCounter++;
					columnEntryCounter[i]++;
					break;
				case NONE:
					resultData[i] = Float.NaN;							
					break;
				case AVERAGE_WIND_DIRECTION:
					if(aggregate_wind_direction) {
						if(wind_cnt>0) {
							float u = wind_u_sum/wind_cnt;
							float v = wind_v_sum/wind_cnt;
							float temp_radians = (float) (Math.atan2(u, v)+Math.PI); // +Math.PI added
							float temp_degrees = (float) ((temp_radians*180)/Math.PI);
							resultData[i] = temp_degrees;
							validValueCounter++;
							columnEntryCounter[i]++;
						}
					} else {
						resultData[i] = Float.NaN;
					}
					break;							
				default:
					resultData[i] = Float.NaN;
					log.warn("aggration type unknown");
				}							
			} else {// no entry in this aggregation time period
				resultData[i] = Float.NaN;
			}
		}
		if(validValueCounter>0) { // if there are some valid aggregates return result data
			return resultData;
		}
		return null; //no aggregates created
	}


	public TimestampSeries process(Iterator<Event> it) {
		initAggregates();

		//timestamp of aggreates of currently collected data
		long aggregation_timestamp = -1;

		//list of aggregated data entries
		List<TimeSeriesEntry> entryList = new ArrayList<TimeSeriesEntry>();

		while(it.hasNext()) { // begin of while-loop for raw input-events
			Event event = it.next();
			long timestamp = event.getTimestamp();
			Object[] payload = event.getPayload();

			long nextAggTimestamp = BaseAggregationTimeUtil.calcBaseAggregationTimestamp(timestamp);
			if(nextAggTimestamp>aggregation_timestamp) { // all values for aggregation_timestamp are collected
				if(aggregation_timestamp>-1) { // if not init timestamp
					float[] data = aggregateCollectedData();
					if(data!=null) {
						entryList.add(new TimeSeriesEntry(aggregation_timestamp,data));
					}
				}
				//reset values for next aggregate
				aggregation_timestamp = nextAggTimestamp;
				resetAggregates();	
			}


			//collect values for aggregation
			for(int i=0;i<parameterNames.length;i++) {
				float prevValue = 0;
				float value = (float) payload[eventPos[i]];
				if(sensors[i].baseAggregationType==AggregationType.AVERAGE_ZERO&&Float.isNaN(value)) { // special conversion of NaN values for aggregate AVERAGE_ZERO
					System.out.println("NaN...");
					value = 0;
				}
				if(!checkPhysicalRange || sensors[i].checkPhysicalRange(value)) {
					if(!checkStepRange || sensors[i].checkStepRange(prevValue, value)) {
						aggCnt[i] ++;					
						aggSum[i] += value;
						if(value>aggMax[i]) {
							aggMax[i] = value;
						}
					}
				}
			}			
			if(aggregate_wind_direction) {
				float wd_degrees = (float) payload[eventPos[wind_direction_pos]];				
				float ws = (float) payload[eventPos[wind_velocity_pos]];				
				if(sensors[wind_direction_pos].checkPhysicalRange(wd_degrees)&&sensors[wind_velocity_pos].checkPhysicalRange(ws)) {
					float wd_radian = (float) ((wd_degrees*Math.PI)/180f);
					float u = (float) (-ws * Math.sin(wd_radian));
					float v = (float) (-ws * Math.cos(wd_radian));
					wind_u_sum+=u;
					wind_v_sum+=v;
					wind_cnt++;			
				}				
			}			
		}  // end of while-loop for raw input-events

		//process last aggregate if there is some collected data left
		float[] data = aggregateCollectedData();
		if(data!=null) {
			entryList.add(new TimeSeriesEntry(aggregation_timestamp,data));
		}

		//create resulting TimeSeries Object
		TimestampSeries timeSeries = new TimestampSeries(parameterNames, entryList, 60); //TODO
		//check and remove empty columns
		for(int i=0;i<parameterNames.length;i++) {
			if(columnEntryCounter[i] == 0) {
				timeSeries.removeEmptyColumns();
				break;
			}
		}

		return timeSeries;
	}

	private void initAggregates() {
		aggCnt = new int[parameterNames.length];
		aggSum = new float[parameterNames.length];
		aggMax = new float[parameterNames.length];		
		columnEntryCounter = new int[parameterNames.length];
		for(int i=0;i<parameterNames.length;i++) {
			columnEntryCounter[i] = 0;
		}		
		resetAggregates();
	}

	private void resetAggregates() {
		for(int i=0;i<parameterNames.length;i++) {
			aggCnt[i] = 0;
			aggSum[i] = 0;
			aggMax[i] = Float.NEGATIVE_INFINITY;
		}
		wind_u_sum=0;
		wind_v_sum=0;
		wind_cnt=0;
	}


}
