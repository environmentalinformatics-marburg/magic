package processinggraph;

import timeseriesdatabase.DataQuality;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.raw.iterator.BadQualityToNanIterator;
import timeseriesdatabase.raw.iterator.QualityFlagIterator;
import util.iterator.TimeSeriesIterator;

public class QualityFilter extends Node{
	
	private Node source;
	private DataQuality dataQuality;

	protected QualityFilter(TimeSeriesDatabase timeSeriesDatabase, Node source) {
		super(timeSeriesDatabase);
		this.source = source;
	}
	
	public static QualityFilter create(TimeSeriesDatabase timeSeriesDatabase, Node source, DataQuality dataQuality) {
		if(DataQuality.Na==dataQuality) {
			throw new RuntimeException();
		}
		return new QualityFilter(timeSeriesDatabase, source);
	}

	@Override
	public TimeSeriesIterator get(Long start, Long end) {
		TimeSeriesIterator input_iterator = source.get(start, end);
		if(input_iterator==null||!input_iterator.hasNext()) {
			return null;
		}
		QualityFlagIterator qf = new QualityFlagIterator(timeSeriesDatabase,input_iterator);
		if(qf==null||!qf.hasNext()) {
			return null;
		}
		if(DataQuality.NO==dataQuality) {
			return qf;
		}
		BadQualityToNanIterator bqi = new BadQualityToNanIterator(qf, dataQuality);
		if(bqi==null||!bqi.hasNext()) {
			return null;
		}		
		return bqi;
	}

	@Override
	public boolean isContinuous() {
		return source.isContinuous();
	}
}
