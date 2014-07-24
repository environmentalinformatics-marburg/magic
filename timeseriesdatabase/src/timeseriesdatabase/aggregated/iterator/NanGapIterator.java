package timeseriesdatabase.aggregated.iterator;

import java.util.List;

import org.apache.logging.log4j.Logger;

import timeseriesdatabase.TimeConverter;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.aggregated.BaseAggregationTimeUtil;
import timeseriesdatabase.raw.TimeSeriesEntry;
import util.ProcessingChainEntry;
import util.TimeSeriesSchema;
import util.Util;
import util.iterator.MoveIterator;
import util.iterator.SchemaIterator;
import util.iterator.TimeSeriesIterator;

/**
 * This iterator fills gaps in input_iterator with NaN rows.
 * start and end of resulting iterator are set to the given parameters, and if needed filled with NaN rows.
 * input iterator needs aggregated data of constant time steps (may contain time gaps in it)
 * @author woellauer
 *
 */
public class NanGapIterator extends MoveIterator {

	private static final Logger log = Util.log;

	SchemaIterator<TimeSeriesEntry> input_iterator;
	/**
	 * timestamp of next Element to output
	 */
	long currTimestamp;
	TimeSeriesEntry nextElement;

	Long endTimestamp;

	public static TimeSeriesSchema createSchema(TimeSeriesSchema input_schema) {
		String[] schema = input_schema.schema;
		if(!input_schema.constantTimeStep) {
			throw new RuntimeException("input iterator needs to have constant time steps");
		}
		boolean constantTimeStep = true;
		int timeStep = input_schema.timeStep;
		boolean isContinuous = true;		
		boolean hasQualityFlags = input_schema.hasQualityFlags;
		boolean hasInterpolatedFlags = input_schema.hasInterpolatedFlags;
		boolean hasQualityCounters = input_schema.hasQualityCounters;
		return new TimeSeriesSchema(schema, constantTimeStep, timeStep, isContinuous, hasQualityFlags, hasInterpolatedFlags, hasQualityCounters) ;
	}


	/**
	 * 
	 * @param input_iterator
	 * @param start if null first element is start
	 * @param end if null last element is end
	 */
	public NanGapIterator(TimeSeriesIterator input_iterator, Long start, Long end) {
		super(createSchema(input_iterator.getOutputTimeSeriesSchema()));

		/*System.out.println("nan it start: "+TimeConverter.oleMinutesToLocalDateTime(start));
		System.out.println("nan it end: "+TimeConverter.oleMinutesToLocalDateTime(end));
		System.out.println("nan it timeStep: "+outputTimeSeriesSchema.timeStep);*/

		if(start!=null) {		
			if(!BaseAggregationTimeUtil.isBaseAggregationTimestamp(start)) {
				throw new RuntimeException("timestamp start not alligned: "+TimeConverter.oleMinutesToLocalDateTime(start));
			}
			if(start%outputTimeSeriesSchema.timeStep!=0) {
				throw new RuntimeException("timestamp start not alligned to timestep: "+TimeConverter.oleMinutesToLocalDateTime(start));
			}
		}

		if(end!=null) {
			if(!BaseAggregationTimeUtil.isBaseAggregationTimestamp(end)) {
				throw new RuntimeException("timestamp end not alligned: "+TimeConverter.oleMinutesToLocalDateTime(end));
			}		
			if(end%outputTimeSeriesSchema.timeStep!=0) {
				throw new RuntimeException("timestamp end not alligned to timestep: "+TimeConverter.oleMinutesToLocalDateTime(end));
			}
		}


		this.endTimestamp = end;
		this.input_iterator = input_iterator;		
		if(input_iterator.hasNext()) { //****************input iterator is not empty***************
			this.nextElement = input_iterator.next();
			if(start!=null) { //********************** with start timestamp *********************
				if(start<=nextElement.timestamp) { //************* next element timestamp higher than start **************
					currTimestamp = start;
				} else { //********* next element timestamp lower than start *************************
					while(nextElement.timestamp<start) { // loop up to first element in start - end range
						if(input_iterator.hasNext()) {
							nextElement = input_iterator.next();
						} else {
							nextElement = null;
						}

					}					
					currTimestamp = start;
				}
			} else { //*************** no start timestamp ***************************
				this.currTimestamp = this.nextElement.timestamp;
			}
		} else { //****************input iterator is empty***************
			if(start!=null) {
				input_iterator = null;			
				currTimestamp = start;
				nextElement = null;
			} else {
				input_iterator = null;			
				currTimestamp = -100;
				endTimestamp = (long)-200;
				nextElement = null;	
			}
		}

	}

	@Override
	protected TimeSeriesEntry getNext() {
		//System.out.println(this.getClass()+"  getNext()");
		if(nextElement==null) {// ******************  no elements left in input_iterator ********************************************
			if(endTimestamp==null) {
				return null;
			} else {
				if(currTimestamp<=endTimestamp) {
					TimeSeriesEntry nanElement = TimeSeriesEntry.createNaN(currTimestamp, input_iterator.getOutputSchema().length);
					currTimestamp += outputTimeSeriesSchema.timeStep;
					//System.out.println(this.getClass()+" "+currTimestamp+" "+nanElement);
					return nanElement;
				} else {
					return null;
				}
			}
		} else if(currTimestamp<nextElement.timestamp) { // ************** next element higher than current timestamp ****************
			TimeSeriesEntry nanElement = TimeSeriesEntry.createNaN(currTimestamp, input_iterator.getOutputSchema().length);
			currTimestamp += outputTimeSeriesSchema.timeStep;
			return nanElement;
		} else if(currTimestamp==nextElement.timestamp) { // ************* current element timestamp equal to current timestamp ******
			currTimestamp += outputTimeSeriesSchema.timeStep;
			TimeSeriesEntry currElement = nextElement;			
			if(input_iterator.hasNext()) {
				TimeSeriesEntry temp = input_iterator.next();
				if(temp.timestamp<=nextElement.timestamp) {
					log.error("timestamp error in input iterator");
				}
				nextElement = temp;
			} else {
				nextElement=null;
			}
			//System.out.println(this.getClass()+" "+currTimestamp+" "+currElement);
			return currElement;
		} else {// ******************** current timestamp higher than next timestamp
			throw new RuntimeException("timestamp error in NanGapIterator: currTimestamp    nextElement.timestamp   "+currTimestamp+"\t\t"+nextElement.timestamp+"\t\t"+TimeConverter.oleMinutesToLocalDateTime(currTimestamp)+"\t-\t"+TimeConverter.oleMinutesToLocalDateTime(nextElement.timestamp));
			//log.error("timestamp error in NanGapIterator: currTimestamp    nextElement.timestamp   "+currTimestamp+"\t\t"+nextElement.timestamp);
			//return null;
		}
	}


	@Override
	public String[] getOutputSchema() {
		return input_iterator.getOutputSchema();
	}

	@Override
	public String getIteratorName() {
		return "NanGapIterator";
	}

	@Override
	public List<ProcessingChainEntry> getProcessingChain() {
		List<ProcessingChainEntry> result = input_iterator.getProcessingChain();
		result.add(this);
		return result;
	}
}
