package timeseriesdatabase.aggregated;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.apache.logging.log4j.Logger;

import timeseriesdatabase.Sensor;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.raw.TimestampSeries;
import timeseriesdatabase.raw.TimestampSeriesEntry;
import util.MoveIterator;
import util.SchemaIterator;
import util.Util;
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
public class BaseAggregationIterator extends MoveIterator<TimestampSeriesEntry> implements SchemaIterator<TimestampSeriesEntry> {

	private static final Logger log = Util.log;

	String[] schema;
	SchemaIterator<TimestampSeriesEntry> input_iterator;

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

	public BaseAggregationIterator(TimeSeriesDatabase timeSeriesDatabase, SchemaIterator<TimestampSeriesEntry> input_iterator) {
		this.schema = input_iterator.getOutputSchema();
		this.input_iterator = input_iterator;
		this.sensors = timeSeriesDatabase.getSensors(schema);		
		prepareWindDirectionAggregation();		
	}

	private void prepareWindDirectionAggregation() {
		wind_direction_pos=-1;
		wind_velocity_pos=-1;
		aggregate_wind_direction = false;
		for(int i=0;i<schema.length;i++) {
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

	/**
	 * process collected data to aggregates
	 * @return result or null if there are no valid aggregates
	 */
	private float[] aggregateCollectedData() {
		float[] resultData = new float[schema.length];	
		int validValueCounter=0; //counter of valid aggregates

		for(int i=0;i<schema.length;i++) {					
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

	@Override
	protected TimestampSeriesEntry getNext() {
		initAggregates();

		//timestamp of aggreates of currently collected data
		long aggregation_timestamp = -1;


		while(input_iterator.hasNext()) { // begin of while-loop for raw input-events
			TimestampSeriesEntry entry = input_iterator.next();
			long timestamp = entry.timestamp;
			float[] payload = entry.data;

			long nextAggTimestamp = BaseAggregationTimeUtil.calcBaseAggregationTimestamp(timestamp);
			if(nextAggTimestamp>aggregation_timestamp) { // all values for aggregation_timestamp are collected
				if(aggregation_timestamp>-1) { // if not init timestamp
					float[] data = aggregateCollectedData();
					if(data!=null) {
						return new TimestampSeriesEntry(aggregation_timestamp,data);
					}
				}
				//reset values for next aggregate
				aggregation_timestamp = nextAggTimestamp;
				resetAggregates();	
			}


			//collect values for aggregation
			for(int i=0;i<schema.length;i++) {
				float prevValue = 0;
				float value = (float) payload[eventPos[i]];
				if(sensors[i].baseAggregationType==AggregationType.AVERAGE_ZERO&&Float.isNaN(value)) { // special conversion of NaN values for aggregate AVERAGE_ZERO
					System.out.println("NaN...");
					value = 0;
				}
				if(!Float.isNaN(value)){
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
			return new TimestampSeriesEntry(aggregation_timestamp,data);
		}
		return null; //no elements left
	}

	private void initAggregates() {
		aggCnt = new int[schema.length];
		aggSum = new float[schema.length];
		aggMax = new float[schema.length];		
		columnEntryCounter = new int[schema.length];
		for(int i=0;i<schema.length;i++) {
			columnEntryCounter[i] = 0;
		}		
		resetAggregates();
	}

	private void resetAggregates() {
		for(int i=0;i<schema.length;i++) {
			aggCnt[i] = 0;
			aggSum[i] = 0;
			aggMax[i] = Float.NEGATIVE_INFINITY;
		}
		wind_u_sum=0;
		wind_v_sum=0;
		wind_cnt=0;
	}

	@Override
	public String[] getOutputSchema() {
		return schema;
	}
}

