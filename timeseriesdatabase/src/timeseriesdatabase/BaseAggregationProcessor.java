package timeseriesdatabase;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.apache.logging.log4j.Logger;

import timeseriesdatabase.Sensor.AggregationType;
import de.umr.jepc.store.Event;

public class BaseAggregationProcessor {

	private static final Logger log = Util.log;

	String[] parameterNames;
	Sensor[] sensors;
	int[] eventPos;

	int[] aggCnt;
	float[] aggSum;
	float[] aggMax;

	boolean aggregate_wind_direction;
	float wind_u_sum;
	float wind_v_sum;
	int wind_cnt;
	int wind_direction_pos;
	int wind_velocity_pos;

	int[] columnEntryCounter;	

	public BaseAggregationProcessor(String[] schemaSensorNames, Set<String> baseAggregatonSensorNameSet, Map<String, Sensor> sensorMap) {
		
		// create output schema of aggregated data in parameterNames
		ArrayList<String> parameterNameList = new ArrayList<String>();
		for(String sensorName:schemaSensorNames) {
			if(baseAggregatonSensorNameSet.contains(sensorName)) {
				parameterNameList.add(sensorName);				
			}
		}
		parameterNames = (String[]) parameterNameList.toArray(new String[0]);

		// create mapping of input event columns to output data columns
		eventPos = new int[parameterNames.length];
		for(int i=0;i<eventPos.length;i++) {
			eventPos[i] = -1;
			for(int pos=0;pos<schemaSensorNames.length;pos++) {
				if(parameterNames[i].equals(schemaSensorNames[pos])) {
					eventPos[i] = pos;
					break;
				}
			}			
		}
		
		//process sensor metadata
		wind_direction_pos=-1;
		wind_velocity_pos=-1;
		aggregate_wind_direction = false;
		sensors = new Sensor[parameterNames.length];
		for(int i=0;i<parameterNames.length;i++) {
			sensors[i] = sensorMap.get(parameterNames[i]);
			if(sensors[i].baseAggregationType==AggregationType.WIND_DIRECTION) {
				if(wind_direction_pos==-1) {
					wind_direction_pos = i;
				} else {
					log.error("just one wind_direction sensor can be aggregated");
				}				
			}
			if(sensors[i].baseAggregationType==AggregationType.WIND_VELOCITY) {
				if(wind_velocity_pos==-1) {
					wind_velocity_pos = i;
				} else {
					log.error("just one wind_velocity sensor can be aggregated");
				}				
			}			
		}
		
		//check if wind direction parameter should be aggregated
		if(wind_velocity_pos>-1&&wind_direction_pos>-1) {
			aggregate_wind_direction = true;
		} else if(wind_velocity_pos>-1||wind_direction_pos>-1) {
			log.error("either wind_direction or wind_velocity sensor missing");
		}

		

		

		

		


	}
	
	private float[] aggregateCollectedData() {
		// result aggregate data
		float[] data = new float[parameterNames.length];

		//counter of valid aggregates
		int validValueCounter=0;
		for(int i=0;i<data.length;i++) {					
			//System.out.print(aggCnt[i]+" ");
			if(aggCnt[i]>0) {// at least one entry has been collected
				switch(sensors[i].baseAggregationType) {
				case AVERAGE:
				case WIND_VELOCITY:	
					data[i] = aggSum[i]/aggCnt[i];
					validValueCounter++;
					columnEntryCounter[i]++;
					break;
				case SUM:
					data[i] = aggSum[i];
					validValueCounter++;
					columnEntryCounter[i]++;
					break;
				case MAXIMUM:
					data[i] = aggMax[i];
					validValueCounter++;
					columnEntryCounter[i]++;
					break;
				case NONE:
					data[i] = Float.NaN;							
					//log.error("no aggeration for this sensor");
					break;
				case WIND_DIRECTION:
					if(aggregate_wind_direction) {
						if(wind_cnt>0) {
							//System.out.println("wind_cnt: "+wind_cnt);
							float u = wind_u_sum/wind_cnt;
							float v = wind_v_sum/wind_cnt;
							float temp_radians = (float) (Math.atan2(v, u)+Math.PI); // + Math.PI added
							float temp_degrees = (float) ((temp_radians*180)/Math.PI);
							data[i] = temp_degrees;
							validValueCounter++;
							columnEntryCounter[i]++;
						}
					} else {
						data[i] = Float.NaN;
					}
					break;							
				default:
					data[i] = Float.NaN;
					log.error("aggration type unknown");
				}							
			} else {// no entry in this period
				data[i] = Float.NaN;
			}
		}
		//System.out.println();
		if(validValueCounter>0) { // if there are some valid aggregates => push entry
			//entryList.add(new TimeSeriesEntry(aggregation_timestamp,data));
			return data;
		}
		return null;
	}


	public TimeSeries process(Iterator<Event> it) {		
		initAggregates();
		
		//timestamp of aggreates of currently collected data
		long aggregation_timestamp = -1;
		
		//list of aggregated data entries
		List<TimeSeriesEntry> entryList = new ArrayList<TimeSeriesEntry>();

		while(it.hasNext()) { // begin of while-loop for raw input-events
			Event event = it.next();
			long timestamp = event.getTimestamp();
			Object[] payload = event.getPayload();

			long nextAggTimestamp = calcAggregationTimestamp(timestamp);
			if(nextAggTimestamp>aggregation_timestamp) { // all values for aggregation_timestamp are collected
				if(aggregation_timestamp>-1) {
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
				float value = (float) payload[eventPos[i]];				
				if(Float.isNaN(value)||value<sensors[i].min||sensors[i].max<value) { // physical range check
					//not valid value
				} else {
					aggCnt[i] ++;					
					aggSum[i] += value;
					if(value>aggMax[i]) {
						aggMax[i] = value;
					}
				}
			}
			if(aggregate_wind_direction) {
				float wd_degrees = (float) payload[eventPos[wind_direction_pos]];				
				float ws = (float) payload[eventPos[wind_velocity_pos]];
				if(!(Float.isNaN(wd_degrees)||Float.isNaN(ws))) {
					//System.out.println("wd_degrees: "+wd_degrees);
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
		TimeSeries timeSeries = new TimeSeries(parameterNames, entryList);
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

	public static long calcAggregationTimestamp(long timestamp) {
		final int AGGREGATION_TIME_INTERVAL = 24*60; // aggregation for standard timeseriesdatabase base aggregation with one hour
		//final int TIME_OFFSET = 0; // !! aggregation for standard timeseriesdatabase
		//final int TIME_OFFSET = 30; // !! aggregation for compatiblity with julendat processing

		if(timestamp%AGGREGATION_TIME_INTERVAL==0) {
			return timestamp-AGGREGATION_TIME_INTERVAL;
		} else {
			return timestamp-timestamp%AGGREGATION_TIME_INTERVAL;
		}		
	}
}
