package timeseriesdatabase.aggregated.iterator;

import timeseriesdatabase.raw.TimeSeriesEntry;
import util.TimeSeriesSchema;
import util.iterator.MoveIterator;
import util.iterator.TimeSeriesIterator;

public class NanRemoveIterator extends MoveIterator{
	
	TimeSeriesIterator input_iterator;

	public NanRemoveIterator(TimeSeriesIterator input_iterator) {
		super(new TimeSeriesSchema(input_iterator.getOutputSchema()));
		this.input_iterator = input_iterator;
	}

	@Override
	protected TimeSeriesEntry getNext() {
		while(input_iterator.hasNext()) {
			TimeSeriesEntry next = input_iterator.next();
			int counter = 0;
			for(float v:next.data) {
				if(!Float.isNaN(v)) {
					counter++;
				}
			}
			if(counter>0) {
				return next;
			}
		}
		return null;
	}

}
