package tsdb.graph;

import static tsdb.util.AssumptionCheck.throwNull;
import tsdb.Station;
import tsdb.aggregated.iterator.PeakSmoothIterator;
import tsdb.util.iterator.TsIterator;

/**
 * Special node for manual precipitation sensors.
 * @author woellauer
 *
 */
public class PeakSmoothed implements Base {
	
	private Node source;

	protected PeakSmoothed(Node source) {
		throwNull(source);
		this.source = source;
	}
	
	public static PeakSmoothed of(Node source) {
		return new PeakSmoothed(source);
	}	

	@Override
	public TsIterator get(Long start, Long end) {		
		TsIterator input_iterator = source.get(start, end);
		if(input_iterator==null||!input_iterator.hasNext()) {
			return null;
		}
		PeakSmoothIterator manual_fill_iterator = new PeakSmoothIterator(input_iterator);
		if(manual_fill_iterator==null||!manual_fill_iterator.hasNext()) {
			return null;
		}
		return manual_fill_iterator;
	}

	@Override
	public Station getSourceStation() {
		return source.getSourceStation();
	}

	@Override
	public boolean isContinuous() { //TODO
		return false;
	}

	@Override
	public String[] getSchema() {
		return source.getSchema();
	}

}
