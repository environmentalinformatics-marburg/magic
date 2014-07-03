package timeseriesdatabase.aggregated.iterator;

import java.time.LocalDateTime;
import java.time.Month;

import org.apache.logging.log4j.Logger;

import timeseriesdatabase.Sensor;
import timeseriesdatabase.TimeConverter;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.aggregated.AggregationInterval;
import timeseriesdatabase.aggregated.AggregationType;
import timeseriesdatabase.raw.TimestampSeriesEntry;
import util.TimeSeriesSchema;
import util.Util;
import util.iterator.MoveIterator;
import util.iterator.SchemaIterator;
import util.iterator.TimeSeriesIterator;

/**
 * Aggregates input to high aggregated data values
 * input elements need to be base aggregated data
 * @author woellauer
 *
 */
public class AggregationIterator extends MoveIterator {

	private static final Logger log = Util.log;

	private SchemaIterator<TimestampSeriesEntry> input_iterator;
	private AggregationInterval aggregationInterval;
	private Sensor[] sensors;

	private boolean aggregate_wind_direction;	
	private int wind_direction_pos;
	private int wind_velocity_pos;

	//*** collector variables for aggregation
	//timestamp of aggreates of currently collected data
	private long aggregation_timestamp;

	private int collectedRowsInCurrentAggregate;
	private int[] aggCnt;
	private float[] aggSum;
	private float[] aggMax;
	private float wind_u_sum;
	private float wind_v_sum;
	private int wind_cnt;
	private int[] columnEntryCounter;
	//***



	/**
	 * 
	 * @param timeSeriesDatabase
	 * @param input_iterator
	 * @param aggregationInterval interval of time that should be aggregated
	 */
	public AggregationIterator(TimeSeriesDatabase timeSeriesDatabase, TimeSeriesIterator input_iterator, AggregationInterval aggregationInterval) {
		super(new TimeSeriesSchema(input_iterator.getOutputSchema()));
		this.input_iterator = input_iterator;
		this.aggregationInterval = aggregationInterval;
		this.sensors = timeSeriesDatabase.getSensors(outputTimeSeriesSchema);		
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

	/**
	 * create aggregation variables
	 */
	private void initAggregates() {
		aggregation_timestamp = -1;
		aggCnt = new int[outputTimeSeriesSchema.columns];
		aggSum = new float[outputTimeSeriesSchema.columns];
		aggMax = new float[outputTimeSeriesSchema.columns];		
		columnEntryCounter = new int[outputTimeSeriesSchema.columns];
		for(int i=0;i<outputTimeSeriesSchema.columns;i++) {
			columnEntryCounter[i] = 0;
		}		
		resetAggregates();
	}

	/**
	 * set aggregation variables to initial state
	 */
	private void resetAggregates() {
		collectedRowsInCurrentAggregate = 0;
		for(int i=0;i<outputTimeSeriesSchema.columns;i++) {
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
	 */
	private void collectValues(float[] inputData) {
		//collect values for aggregation
		collectedRowsInCurrentAggregate++;		
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
	 * checks if enough values have been collected for one aggregation unit
	 * @param collectorCount
	 * @return
	 */
	private boolean isValidAggregate(int collectorCount) {
		//final int PERCENT = 50;
		final int PERCENT = 90;
		switch(aggregationInterval) {
		case DAY: {
			final int MIN_VALUES = (1*24*PERCENT)/100;
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
	private float[] aggregateCollectedData() {
		float[] resultData = new float[outputTimeSeriesSchema.columns];	
		int validValueCounter=0; //counter of valid aggregates

		for(int i=0;i<outputTimeSeriesSchema.columns;i++) {
			//if(aggCnt[i]>0) {// at least one entry has been collected
			if(isValidAggregate(aggCnt[i])) { // a minimum of values need to be collected
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
			resetAggregates();
			return resultData;
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
			System.out.println(aggregationDatetime);
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
			System.out.println(aggregationDatetime);
			return TimeConverter.DateTimeToOleMinutes(aggregationDatetime);
		}
		default:{
			log.error("unknown AggregationInterval: "+aggregationInterval);
			return timestamp;
		}
		}
	}

	@Override
	protected TimestampSeriesEntry getNext() {
		while(input_iterator.hasNext()) { // begin of while-loop for raw input-events
			TimestampSeriesEntry entry = input_iterator.next();
			long timestamp = entry.timestamp;
			float[] inputData = entry.data;

			long nextAggTimestamp = calcAggregationTimestamp(timestamp);
			if(nextAggTimestamp>aggregation_timestamp) { // aggregate aggregation_timestamp is ready for output
				if(aggregation_timestamp>-1) { // if not init timestamp
					boolean dataInAggregateCollection = collectedRowsInCurrentAggregate>0;
					float[] aggregatedData = aggregateCollectedData();
					if(aggregatedData!=null) {
						TimestampSeriesEntry resultElement = new TimestampSeriesEntry(aggregation_timestamp,aggregatedData);
						aggregation_timestamp = nextAggTimestamp;
						collectValues(inputData);
						return resultElement;
					} else {
						if(!dataInAggregateCollection) {
							aggregation_timestamp = nextAggTimestamp;
							collectValues(inputData);
						} else {	
							TimestampSeriesEntry resultElement = TimestampSeriesEntry.getNaN(aggregation_timestamp,outputTimeSeriesSchema.columns);
							aggregation_timestamp = nextAggTimestamp;
							collectValues(inputData);
							return resultElement;
						}
					}
				} else {
					aggregation_timestamp = nextAggTimestamp;
					collectValues(inputData);
				}
			} else {
				collectValues(inputData);
			}
		}  // end of while-loop for raw input-events

		//process last aggregate if there is some collected data left
		boolean dataInAggregateCollection = collectedRowsInCurrentAggregate>0;
		float[] aggregatedData = aggregateCollectedData();
		if(aggregatedData!=null) {
			return new TimestampSeriesEntry(aggregation_timestamp,aggregatedData);
		} else if(dataInAggregateCollection) { //insert NaN element at end //?? TODO testing
			return TimestampSeriesEntry.getNaN(aggregation_timestamp,outputTimeSeriesSchema.columns);
		} else {
			return null; //no elements left
		}

	}
}
