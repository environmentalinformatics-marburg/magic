package timeseriesdatabase.aggregated.iterator;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.apache.logging.log4j.Logger;

import timeseriesdatabase.DataQuality;
import timeseriesdatabase.Sensor;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.aggregated.AggregationType;
import timeseriesdatabase.aggregated.BaseAggregationTimeUtil;
import timeseriesdatabase.raw.TimestampSeries;
import timeseriesdatabase.raw.TimeSeriesEntry;
import util.Pair;
import util.ProcessingChainEntry;
import util.TimeSeriesSchema;
import util.Util;
import util.iterator.MoveIterator;
import util.iterator.SchemaIterator;
import util.iterator.TimeSeriesIterator;
import de.umr.jepc.store.Event;

/**
 * BaseAggregationIterator aggregates input elements to aggregated output elements with base aggregation time intervals
 * @author woellauer
 *
 */
public class BaseAggregationIterator extends MoveIterator {

	private static final Logger log = Util.log;

	//String[] schema;
	SchemaIterator<TimeSeriesEntry> input_iterator;

	Sensor[] sensors;
	boolean aggregate_wind_direction;	
	int wind_direction_pos;
	int wind_velocity_pos;

	//*** collector variables for aggregation
	//timestamp of aggreates of currently collected data
	long aggregation_timestamp;

	boolean useQualityFlags;
	DataQuality[] aggQuality;

	int[] aggCnt;
	float[] aggSum;
	float[] aggMax;
	float wind_u_sum;
	float wind_v_sum;
	int wind_cnt;
	int[] columnEntryCounter;
	//***
	
	public static TimeSeriesSchema createSchema(TimeSeriesSchema input_schema, int timeStep) {
		String[] schema = input_schema.schema;
		boolean constantTimeStep = true;
		boolean isContinuous = input_schema.isContinuous;		
		boolean hasQualityFlags = input_schema.hasQualityFlags;
		boolean hasInterpolatedFlags = false;
		boolean hasQualityCounters = false;
		return new TimeSeriesSchema(schema, constantTimeStep, timeStep, isContinuous, hasQualityFlags, hasInterpolatedFlags, hasQualityCounters) ;
		
	}

	public BaseAggregationIterator(TimeSeriesDatabase timeSeriesDatabase, TimeSeriesIterator input_iterator) {
		super(createSchema(input_iterator.getOutputTimeSeriesSchema(), BaseAggregationTimeUtil.AGGREGATION_TIME_INTERVAL));
		this.useQualityFlags = input_iterator.getOutputTimeSeriesSchema().hasQualityFlags; 
		this.input_iterator = input_iterator;
		this.sensors = timeSeriesDatabase.getSensors(outputTimeSeriesSchema);		
		prepareWindDirectionAggregation();
		initAggregates();
	}

	private void prepareWindDirectionAggregation() {
		wind_direction_pos=-1;
		wind_velocity_pos=-1;
		aggregate_wind_direction = false;
		for(int i=0;i<outputTimeSeriesSchema.columns;i++) {
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

	private void initAggregates() {
		aggregation_timestamp = -1;
		aggQuality = new DataQuality[outputTimeSeriesSchema.columns];
		aggCnt = new int[outputTimeSeriesSchema.columns];
		aggSum = new float[outputTimeSeriesSchema.columns];
		aggMax = new float[outputTimeSeriesSchema.columns];		
		columnEntryCounter = new int[outputTimeSeriesSchema.columns];
		for(int i=0;i<outputTimeSeriesSchema.columns;i++) {
			columnEntryCounter[i] = 0;
		}		
		resetAggregates();
	}

	private void resetAggregates() {
		for(int i=0;i<outputTimeSeriesSchema.columns;i++) {
			if(aggQuality!=null)  {			
				aggQuality[i] = DataQuality.Na;
			}
			aggCnt[i] = 0;
			aggSum[i] = 0;
			aggMax[i] = Float.NEGATIVE_INFINITY;
		}
		wind_u_sum=0;
		wind_v_sum=0;
		wind_cnt=0;
	}

	private void collectQuality(DataQuality[] inputQuality) {
		if(inputQuality==null) {
			//System.out.println("inputQuality==null");
			aggQuality = null;
		} else {		
			for(int i=0;i<outputTimeSeriesSchema.columns;i++) {
				switch(aggQuality[i]) {
				case Na:
					aggQuality[i] = inputQuality[i]; // Na, NO, PHYSICAL, STEP, EMPIRICAL 
					break;
				case NO: // aggQuality[i] is lowest quality
					break;
				case PHYSICAL:
					if(inputQuality[i] == DataQuality.NO) {
						aggQuality[i] = DataQuality.NO; 
					}
					break;
				case STEP:
					if(inputQuality[i] == DataQuality.NO) {
						aggQuality[i] = DataQuality.NO; 
					} else if(inputQuality[i] == DataQuality.PHYSICAL) {
						aggQuality[i] = DataQuality.PHYSICAL;
					}
					break;
				case EMPIRICAL:
					if(inputQuality[i] == DataQuality.NO) {
						aggQuality[i] = DataQuality.NO; 
					} else if(inputQuality[i] == DataQuality.PHYSICAL) {
						aggQuality[i] = DataQuality.PHYSICAL;
					} else if(inputQuality[i] == DataQuality.STEP) {
						aggQuality[i] = DataQuality.STEP;
					}
					break;
				default:
					log.warn("quality not found");
				}

			}
		}
	}

	private void collectValues(float[] inputData) {
		//collect values for aggregation
		for(int i=0;i<outputTimeSeriesSchema.columns;i++) {
			float value = (float) inputData[i];
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
			float wd_degrees = (float) inputData[wind_direction_pos];				
			float ws = (float) inputData[wind_velocity_pos];				
			if(sensors[wind_direction_pos].checkPhysicalRange(wd_degrees)&&sensors[wind_velocity_pos].checkPhysicalRange(ws)) {
				float wd_radian = (float) ((wd_degrees*Math.PI)/180f);
				float u = (float) (-ws * Math.sin(wd_radian));
				float v = (float) (-ws * Math.cos(wd_radian));
				wind_u_sum+=u;
				wind_v_sum+=v;
				wind_cnt++;			
			}				
		}					
	}

	/**
	 * process collected data to aggregates
	 * @return result or null if there are no valid aggregates
	 */
	private Pair<float[],DataQuality[]> aggregateCollectedData() {
		float[] resultData = new float[outputTimeSeriesSchema.columns];	
		int validValueCounter=0; //counter of valid aggregates

		for(int i=0;i<outputTimeSeriesSchema.columns;i++) {
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
			DataQuality[] resultQuality = null;
			if(aggQuality!=null) {
				resultQuality = Arrays.copyOf(aggQuality, aggQuality.length);
			} 
			resetAggregates();
			return new Pair<float[], DataQuality[]>(resultData, resultQuality);
		} else {
			resetAggregates();
			return null; //no aggregates created
		}
	}

	@Override
	protected TimeSeriesEntry getNext() {
		while(input_iterator.hasNext()) { // begin of while-loop for raw input-events
			TimeSeriesEntry entry = input_iterator.next();
			long timestamp = entry.timestamp;
			float[] inputData = entry.data;

			long nextAggTimestamp = BaseAggregationTimeUtil.calcBaseAggregationTimestamp(timestamp);
			if(nextAggTimestamp>aggregation_timestamp) { // aggregate aggregation_timestamp is ready for output
				if(aggregation_timestamp>-1) { // if not init timestamp
					Pair<float[], DataQuality[]> aggregatedPair = aggregateCollectedData();
					if(aggregatedPair!=null) {
						TimeSeriesEntry resultElement = new TimeSeriesEntry(aggregation_timestamp,aggregatedPair);					
						aggregation_timestamp = nextAggTimestamp;
						collectQuality(entry.qualityFlag);
						collectValues(inputData);
						return resultElement;
					} else {
						aggregation_timestamp = nextAggTimestamp;
						collectQuality(entry.qualityFlag);
						collectValues(inputData);
					}
				} else {
					aggregation_timestamp = nextAggTimestamp;
					collectQuality(entry.qualityFlag);
					collectValues(inputData);
				}
			} else {
				collectQuality(entry.qualityFlag);
				collectValues(inputData);
			}
		}  // end of while-loop for raw input-events

		//process last aggregate if there is some collected data left
		Pair<float[], DataQuality[]> aggregatedPair = aggregateCollectedData();
		if(aggregatedPair!=null) {
			return new TimeSeriesEntry(aggregation_timestamp,aggregatedPair);
		}
		return null; //no elements left
	}

	@Override
	public String getIteratorName() {
		return "BaseAggregationIterator";
	}
	
	@Override
	public List<ProcessingChainEntry> getProcessingChain() {
		List<ProcessingChainEntry> result = input_iterator.getProcessingChain();
		result.add(this);
		return result;
	}
}

