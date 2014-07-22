package timeseriesdatabase.aggregated.iterator;

import java.util.List;

import org.apache.logging.log4j.Logger;

import timeseriesdatabase.TimeSeriesDatabase;
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
		this.endTimestamp = end;
		this.input_iterator = input_iterator;		
		if(input_iterator.hasNext()) {
			this.nextElement = input_iterator.next();
			if(start!=null) {
				if(start<=nextElement.timestamp) {
					currTimestamp = start;
				} else { // nextElement.timestamp < start
					while(nextElement.timestamp<start) {
						if(input_iterator.hasNext()) {
							nextElement = input_iterator.next();
						} else {
							nextElement = null;
						}
						
					}					
					currTimestamp = start;
				}
			} else {
				this.currTimestamp = this.nextElement.timestamp;
			}
		} else {
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
		if(nextElement==null) {
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
		} else if(currTimestamp<nextElement.timestamp) { // fill stream with NaN elements
			TimeSeriesEntry nanElement = TimeSeriesEntry.createNaN(currTimestamp, input_iterator.getOutputSchema().length);
			currTimestamp += outputTimeSeriesSchema.timeStep;
			return nanElement;
		} else if(currTimestamp==nextElement.timestamp) { // output current element
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
		} else {
			log.error("timestamp error in NanGapIterator: currTimestamp    nextElement.timestamp   "+currTimestamp+"\t\t"+nextElement.timestamp);
			return null;
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
