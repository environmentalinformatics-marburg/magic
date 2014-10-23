package tsdb.aggregated.iterator;

import static tsdb.util.AssumptionCheck.throwTrue;

import java.time.LocalDateTime;
import java.time.Month;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import tsdb.DataQuality;
import tsdb.Sensor;
import tsdb.TimeConverter;
import tsdb.TsDB;
import tsdb.aggregated.AggregationInterval;
import tsdb.aggregated.AggregationType;
import tsdb.raw.TsEntry;
import tsdb.util.Pair;
import tsdb.util.TsSchema;
import tsdb.util.TsSchema.Aggregation;
import tsdb.util.iterator.InputProcessingIterator;
import tsdb.util.iterator.TsIterator;

/**
 * Aggregates input to high aggregated data values
 * input elements need to be in base aggregated data
 * @author woellauer
 *
 */
@Deprecated
public class AggregationIterator extends InputProcessingIterator {
	
	private static final Logger log = LogManager.getLogger();

	private static final int QUALITY_COUNTERS = 5;
	
	private static final int QUALITY_NO_POS = 0;
	private static final int QUALITY_PHYSICAL_POS = 1;
	private static final int QUALITY_STEP_POS = 2;
	private static final int QUALITY_EMPIRICAL_POS = 3;
	private static final int QUALITY_INTERPOLATED_POS = 4;	

	private AggregationInterval aggregationInterval;
	private Sensor[] sensors;

	private boolean aggregate_wind_direction;	
	private int wind_direction_pos;
	private int wind_velocity_pos;

	//*** collector variables for aggregation
	//timestamp of aggreates of currently collected data
	private long aggregation_timestamp;

	//private boolean inputHasQualityFlags;
	private int[][] aggQualityCounter;

	private int collectedRowsInCurrentAggregate;
	private int[] aggCnt;
	private float[] aggSum;
	private float[] aggMax;
	private float wind_u_sum;
	private float wind_v_sum;
	private int wind_cnt;
	private int[] columnEntryCounter;
	//***
	
	
	public static TsSchema createSchema(TsSchema input_schema, AggregationInterval aggregationInterval) {		
		input_schema.throwNoAggregation();
		input_schema.throwNotContinuous();
		throwTrue(input_schema.hasQualityCounters,"quality counters are not usable as input");
		Aggregation aggregation = aggregationInterval.toAggregation();
		int timeStep = aggregationInterval.toTimeStep();
		boolean isContinuous = true;
		boolean hasQualityFlags = false;
		boolean hasInterpolatedFlags = false;
		boolean hasQualityCounters = false;
		return new TsSchema(input_schema.names, aggregation,timeStep ,isContinuous, hasQualityFlags, hasInterpolatedFlags, hasQualityCounters);
		

		/*boolean constantTimeStep = false;
		int timeStep = TimeSeriesSchema.NO_CONSTANT_TIMESTEP;
		boolean isContinuous = false; //??		
		boolean hasQualityFlags = false;
		boolean hasInterpolatedFlags = false; //??
		boolean hasQualityCounters = input_schema.hasQualityFlags;
		return new TimeSeriesSchema(schema, constantTimeStep, timeStep, isContinuous, hasQualityFlags, hasInterpolatedFlags, hasQualityCounters).toTsSchema();*/		
	}

	/**
	 * 
	 * @param timeSeriesDatabase
	 * @param input_iterator
	 * @param aggregationInterval interval of time that should be aggregated
	 */
	public AggregationIterator(TsDB timeSeriesDatabase, TsIterator input_iterator, AggregationInterval aggregationInterval) {
		super(input_iterator, createSchema(input_iterator.getSchema(), aggregationInterval));
		//this.inputHasQualityFlags = input_iterator.getOutputTimeSeriesSchema().hasQualityFlags;
		this.aggregationInterval = aggregationInterval;
		this.sensors = timeSeriesDatabase.getSensors(schema.names);		
		prepareWindDirectionAggregation();
		initAggregates();
	}		

	/**
	 * search for sensors of wind direction and wind velocity
	 */
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
	 * create aggregation variables
	 */
	private void initAggregates() {
		aggregation_timestamp = -1;
		aggQualityCounter = new int[schema.length][QUALITY_COUNTERS];
		aggCnt = new int[schema.length];
		aggSum = new float[schema.length];
		aggMax = new float[schema.length];		
		columnEntryCounter = new int[schema.length];
		for(int i=0;i<schema.length;i++) {
			columnEntryCounter[i] = 0;
		}		
		resetAggregates();
	}

	/**
	 * set aggregation variables to initial state
	 */
	private void resetAggregates() {
		collectedRowsInCurrentAggregate = 0;
		for(int i=0;i<schema.length;i++) {
			if(aggQualityCounter!=null) {
				for(int q=0;q<QUALITY_COUNTERS;q++) {
					aggQualityCounter[i][q] = 0;
				}
			}
			aggCnt[i] = 0;
			aggSum[i] = 0;
			aggMax[i] = Float.NEGATIVE_INFINITY;
		}
		wind_u_sum=0;
		wind_v_sum=0;
		wind_cnt=0;
	}

	/**
	 * adds one row of input into aggregation variables
	 * @param inputData
	 * @param inputInterpolated 
	 */
	private void collectValues(float[] inputData, DataQuality[] quality, boolean[] inputInterpolated) {
		//collect values for aggregation
		collectedRowsInCurrentAggregate++;		
		for(int i=0;i<schema.length;i++) {
			float value = (float) inputData[i];
			if(sensors[i].baseAggregationType==AggregationType.AVERAGE_ZERO&&Float.isNaN(value)) { // special conversion of NaN values for aggregate AVERAGE_ZERO
				//System.out.println("NaN...");
				value = 0;
			}
			if(!Float.isNaN(value)){
				aggCnt[i] ++;					
				aggSum[i] += value;
				if(value>aggMax[i]) {
					aggMax[i] = value;

				}

			}
			
		
			
			if(quality!=null) {
				
				if(inputInterpolated!=null&&inputInterpolated[i]) {
					aggQualityCounter[i][QUALITY_INTERPOLATED_POS]++;
				}
				
				switch(quality[i]) {
				case Na:
					break; // nothing to count
				case NO:
					aggQualityCounter[i][QUALITY_NO_POS]++;
					break;
				case PHYSICAL:
					aggQualityCounter[i][QUALITY_PHYSICAL_POS]++;
					break;
				case STEP:
					aggQualityCounter[i][QUALITY_STEP_POS]++;
				case EMPIRICAL:
					aggQualityCounter[i][QUALITY_EMPIRICAL_POS]++;
				}
			} else {
				aggQualityCounter = null;
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
	 * checks if enough values have been collected for one aggregation unit
	 * @param collectorCount
	 * @param aggregationType 
	 * @return
	 */
	private boolean isValidAggregate(int collectorCount, AggregationType aggregationType) {
		//final int PERCENT = 50;
		int PERCENT = 90;
		if(aggregationType == AggregationType.AVERAGE_ALBEDO) {
			PERCENT = (PERCENT*6)/24;
		}
		switch(aggregationInterval) {
		case HOUR: { // TODO prevent aggregation of one hour in high aggregates
			return collectorCount>0;
		}
		case DAY: {
			if(aggregationType == AggregationType.AVERAGE_ALBEDO) {
				final int MIN_VALUES = 5;
				return MIN_VALUES<=collectorCount;
			}
			//final int MIN_VALUES = (1*24*PERCENT)/100;
			final int MIN_VALUES = 22; // ~90%
			return MIN_VALUES<=collectorCount; 
		}
		case WEEK: {
			final int MIN_VALUES = (7*24*PERCENT)/100;
			return MIN_VALUES<=collectorCount; 
		}
		case MONTH: {
			final int MIN_VALUES = (28*24*PERCENT)/100;
			return MIN_VALUES<=collectorCount; 
		}
		case YEAR: {
			final int MIN_VALUES = (365*24*PERCENT)/100;
			return MIN_VALUES<=collectorCount; 
		}
		default: {
			log.error("unknown aggregate interval: "+aggregationInterval);
			return false;
		}
		}

	}

	/**
	 * process collected data to aggregates
	 * @return result or null if there are no valid aggregates
	 */
	private Pair<float[],int[][]> aggregateCollectedData() {
		float[] resultData = new float[schema.length];	
		int validValueCounter=0; //counter of valid aggregates

		for(int i=0;i<schema.length;i++) {
			//if(aggCnt[i]>0) {// at least one entry has been collected
			if(isValidAggregate(aggCnt[i], sensors[i].baseAggregationType)) { // a minimum of values need to be collected
				switch(sensors[i].baseAggregationType) {
				case AVERAGE:
				case AVERAGE_ZERO:	
				case AVERAGE_WIND_VELOCITY:
				case AVERAGE_ALBEDO:
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
			int[][] resultQualityCounter = null;
			if(aggQualityCounter!=null) {
				resultQualityCounter = new int[schema.length][QUALITY_COUNTERS]; 
				for(int c=0;c<schema.length;c++) {
					for(int q=0;q<QUALITY_COUNTERS;q++) {
						resultQualityCounter[c][q] = aggQualityCounter[c][q];
					}
				}
			}
			resetAggregates();
			return new Pair<float[],int[][]>(resultData,resultQualityCounter);
		} else { //no aggregates created
			resetAggregates();
			return null;
		}
	}

	private long calcAggregationTimestamp(long timestamp) {
		switch(aggregationInterval) {
		case HOUR: {
			final int HOUR_INTERVAL = 60;
			return timestamp - timestamp%HOUR_INTERVAL; // nothing to aggregate
		} 
		case DAY: {
			final int DAY_INTERVAL = 24*60;
			return timestamp - timestamp%DAY_INTERVAL;
		}
		case WEEK: {
			final int WEEK_INTERVAL = 7*24*60;
			final int WEEK_DAY_OFFSET = 5*24*60;
			return timestamp - timestamp%WEEK_INTERVAL - WEEK_DAY_OFFSET;
		} 
		case MONTH: {
			LocalDateTime datetime = TimeConverter.oleMinutesToLocalDateTime(timestamp);
			int year = datetime.getYear();
			Month month = datetime.getMonth();
			int dayOfMonth = 1;
			int hour = 0;
			int minute = 0;
			LocalDateTime aggregationDatetime = LocalDateTime.of(year,month,dayOfMonth,hour,minute);
			//System.out.println(aggregationDatetime);
			return TimeConverter.DateTimeToOleMinutes(aggregationDatetime);
		}
		case YEAR:{
			LocalDateTime datetime = TimeConverter.oleMinutesToLocalDateTime(timestamp);
			int year = datetime.getYear();
			Month month = Month.JANUARY;
			int dayOfMonth = 1;
			int hour = 0;
			int minute = 0;
			LocalDateTime aggregationDatetime = LocalDateTime.of(year,month,dayOfMonth,hour,minute);
			//System.out.println(aggregationDatetime);
			return TimeConverter.DateTimeToOleMinutes(aggregationDatetime);
		}
		default:{
			log.error("unknown AggregationInterval: "+aggregationInterval);
			return timestamp;
		}
		}
	}

	@Override
	protected TsEntry getNext() {
		while(input_iterator.hasNext()) { // begin of while-loop for raw input-events
			TsEntry entry = input_iterator.next();
			long timestamp = entry.timestamp;
			float[] inputData = entry.data;
			DataQuality[] inputQuality = entry.qualityFlag;
			boolean[] inputInterpolated = entry.interpolated;

			long nextAggTimestamp = calcAggregationTimestamp(timestamp);
			if(nextAggTimestamp>aggregation_timestamp) { // aggregate aggregation_timestamp is ready for output
				if(aggregation_timestamp>-1) { // if not init timestamp
					boolean dataInAggregateCollection = collectedRowsInCurrentAggregate>0;
					Pair<float[], int[][]> aggregatedPair = aggregateCollectedData();
					if(aggregatedPair!=null) {
						TsEntry resultElement = new TsEntry(aggregation_timestamp,null,aggregatedPair);
						aggregation_timestamp = nextAggTimestamp;
						collectValues(inputData, inputQuality, inputInterpolated);
						return resultElement;
					} else {
						if(!dataInAggregateCollection) {
							aggregation_timestamp = nextAggTimestamp;
							collectValues(inputData, inputQuality, inputInterpolated);
						} else {	
							TsEntry resultElement = TsEntry.createNaN(aggregation_timestamp,schema.length);
							aggregation_timestamp = nextAggTimestamp;
							collectValues(inputData, inputQuality, inputInterpolated);
							return resultElement;
						}
					}
				} else {
					aggregation_timestamp = nextAggTimestamp;
					collectValues(inputData, inputQuality, inputInterpolated);
				}
			} else {
				collectValues(inputData, inputQuality, inputInterpolated);
			}
		}  // end of while-loop for raw input-events

		//process last aggregate if there is some collected data left
		boolean dataInAggregateCollection = collectedRowsInCurrentAggregate>0;
		Pair<float[], int[][]> aggregatedPair = aggregateCollectedData();
		if(aggregatedPair!=null) {
			return new TsEntry(aggregation_timestamp, null, aggregatedPair);
		} else if(dataInAggregateCollection) { //insert NaN element at end //?? TODO testing
			return TsEntry.createNaN(aggregation_timestamp,schema.length);
		} else {
			return null; //no elements left
		}
	}
}
