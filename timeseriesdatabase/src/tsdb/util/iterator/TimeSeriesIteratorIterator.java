package tsdb.util.iterator;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Set;
import java.util.function.Function;

import tsdb.raw.TimeSeriesEntry;
import tsdb.util.ProcessingChainEntry;
import tsdb.util.TimeSeriesSchema;

public class TimeSeriesIteratorIterator<T> extends MoveIterator {

	private Iterator<TimeSeriesIterator> input_iterator;
	private SchemaConverterIterator current_iterator;
	
	public static <T> TimeSeriesIteratorIterator<T> create(Iterable<T> input, Function<T,TimeSeriesIterator> function) {
		return create(input.iterator(),function);
	}

	public static <T> TimeSeriesIteratorIterator<T> create(Iterator<T> input_iterator, Function<T,TimeSeriesIterator> function) {
		Set<String> schemaSet = new HashSet<String>();
		List<TimeSeriesIterator> list = new ArrayList<TimeSeriesIterator>();
		while(input_iterator.hasNext()) {
			TimeSeriesIterator timeSeriesIterator = function.apply(input_iterator.next());
			List<String> schemalist = Arrays.asList(timeSeriesIterator.getOutputSchema());
			System.out.println("schemalist: "+schemalist);
			schemaSet.addAll(schemalist);
			System.out.println("schemaSet: "+schemaSet);
			list.add(timeSeriesIterator);
		}			
		return new TimeSeriesIteratorIterator<T>(list,schemaSet.toArray(new String[0]));
	}
	
	public TimeSeriesIteratorIterator(Iterable<TimeSeriesIterator> input, String[] outputSchema) {
		this(input.iterator(),outputSchema);
	}

	public TimeSeriesIteratorIterator(Iterator<TimeSeriesIterator> input_iterator, String[] outputSchema) {
		super(new TimeSeriesSchema(outputSchema));
		this.input_iterator = input_iterator;
		current_iterator = null;
	}

	@Override
	protected TimeSeriesEntry getNext() {			
		if(current_iterator==null) {
			if(input_iterator.hasNext()) {
				TimeSeriesIterator next = input_iterator.next();
				current_iterator = new SchemaConverterIterator(next, outputTimeSeriesSchema.schema, true);
				System.out.println("get next iterator");
				return getNext();
			} else {
				return null;
			}
		} else if(current_iterator.hasNext()) {
			return current_iterator.next();
		} else {
			current_iterator = null;
			return getNext();
		}
	}

	@Override
	public String getIteratorName() {
		return "TimeSeriesIteratorIterator";
	}
	
	@Override
	public List<ProcessingChainEntry> getProcessingChain() {
		ArrayList<ProcessingChainEntry> result = new ArrayList<ProcessingChainEntry>();
		result.add(this);
		return result;
	}	
	
}