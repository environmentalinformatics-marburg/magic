package timeseriesdatabase.aggregated.iterator;

import org.apache.logging.log4j.Logger;

import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.raw.TimestampSeriesEntry;
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

	SchemaIterator<TimestampSeriesEntry> input_iterator;
	long currTimestamp;
	TimestampSeriesEntry nextElement;
	
	Long endTimestamp;
	
	
	/**
	 * 
	 * @param input_iterator
	 * @param start if null first element is start
	 * @param end if null last element is end
	 */
	public NanGapIterator(TimeSeriesIterator input_iterator, Long start, Long end) {
		super(new TimeSeriesSchema(input_iterator.getOutputTimeSeriesSchema().schema,input_iterator.getOutputTimeSeriesSchema().timeStep, true));
		if(!input_iterator.getOutputTimeSeriesSchema().constantTimeStep) {
			log.error("input iterator needs to have constant time steps");
		}
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
	protected TimestampSeriesEntry getNext() {
		if(nextElement==null) {
			if(endTimestamp==null) {
			return null;
			} else {
				if(currTimestamp<=endTimestamp) {
					TimestampSeriesEntry nanElement = TimestampSeriesEntry.getNaN(currTimestamp, input_iterator.getOutputSchema().length);
					currTimestamp += outputTimeSeriesSchema.timeStep;
					return nanElement;
				} else {
					return null;
				}
			}
		} else if(currTimestamp<nextElement.timestamp) { // fill stream with NaN elements
			TimestampSeriesEntry nanElement = TimestampSeriesEntry.getNaN(currTimestamp, input_iterator.getOutputSchema().length);
			currTimestamp += outputTimeSeriesSchema.timeStep;
			return nanElement;
		} else if(currTimestamp==nextElement.timestamp) { // output current element
			currTimestamp += outputTimeSeriesSchema.timeStep;
			TimestampSeriesEntry currElement = nextElement;			
			if(input_iterator.hasNext()) {
				nextElement = input_iterator.next();
			} else {
				nextElement=null;
			}			
			return currElement;
		} else {
			log.error("timestamp error in NanGapIterator");
			return null;
		}
	}
	
	
	@Override
	public String[] getOutputSchema() {
		return input_iterator.getOutputSchema();
	}
}
