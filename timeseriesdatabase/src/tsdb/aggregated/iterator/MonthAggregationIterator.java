package tsdb.aggregated.iterator;

import java.time.LocalDateTime;
import java.time.Month;

import tsdb.TimeConverter;
import tsdb.TsDB;
import tsdb.aggregated.AggregationType;
import tsdb.util.TsSchema.Aggregation;
import tsdb.util.iterator.TsIterator;

public class MonthAggregationIterator extends AbstractAggregationIterator  {

	public MonthAggregationIterator(TsDB tsdb, TsIterator input_iterator) {
		super(tsdb, input_iterator, createSchemaFromConstantToVariableStep(input_iterator.getSchema(), 24*60, Aggregation.MONTH));
	}
	
	@Override
	protected long calcAggregationTimestamp(long timestamp) {
		LocalDateTime datetime = TimeConverter.oleMinutesToLocalDateTime(timestamp);
		int year = datetime.getYear();
		Month month = datetime.getMonth();
		LocalDateTime aggregationDatetime = LocalDateTime.of(year,month,1,0,0);
		return TimeConverter.DateTimeToOleMinutes(aggregationDatetime);
	}

	@Override
	protected boolean isValidAggregate(int collectorCount, AggregationType aggregationType) {
		return 27<=collectorCount;
	}
}