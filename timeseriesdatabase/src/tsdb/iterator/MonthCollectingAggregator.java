package tsdb.iterator;

import java.time.LocalDateTime;
import java.time.Month;
import java.util.ArrayList;

import tsdb.util.TimeConverter;

public class MonthCollectingAggregator {

	private DayCollectingAggregator dca;

	ArrayList<Float>[] nextInput;
	long nextInputAggregationTimestamp;

	public final ArrayList<Float>[] outputs;
	public final int[] outputCounters;
	public long outputTimestamp;

	public MonthCollectingAggregator(DayCollectingAggregator dca) {
		this.dca = dca;
		this.outputs = new ArrayList[dca.outputs.length];
		this.outputCounters = new int[dca.outputs.length];
		this.outputTimestamp = -1;
		for(int i=0;i<outputs.length;i++) {
			outputs[i] = new ArrayList<Float>(31);
		}
		calcNextInput();
	}

	private void calcNextInput() {
		dca.calcNextOutput();
		if(dca.outputTimestamp>=0) {
			nextInput = dca.outputs;
			nextInputAggregationTimestamp = calcAggregationTimestamp(dca.outputTimestamp);
		} else {
			nextInput = null;
			nextInputAggregationTimestamp = -1;
		}
	}

	public void calcNextOutput() {
		int validAttributesCount = 0;
		while(validAttributesCount==0) {
			for(ArrayList<Float> list:outputs) {
				list.clear();
			}
			for(int i=0;i<outputCounters.length;i++) {
				outputCounters[i] = 0;
			}
			long currentAggregationTimestamp = nextInputAggregationTimestamp;
			if(currentAggregationTimestamp<0) {
				outputTimestamp = -1;
				return;
			}
			for(int i=0;i<outputs.length;i++) {
				outputs[i].addAll(dca.outputs[i]);
			}
			calcNextInput();
			while(currentAggregationTimestamp==nextInputAggregationTimestamp) {
				for(int i=0;i<outputs.length;i++) {
					if(dca.outputs[i].size()>0) {
						outputs[i].addAll(dca.outputs[i]);
						outputCounters[i]++;
					}
				}
				calcNextInput();
			}


			for(int i=0;i<outputs.length;i++) {
				if(outputCounters[i]>=27) { // change per attribute type
					validAttributesCount++;
				} else {
					outputs[i].clear();
				}
			}
			if(validAttributesCount>0) {
				outputTimestamp = currentAggregationTimestamp;
			} else {
				outputTimestamp = -1;
			}
		}
	}

	private long calcAggregationTimestamp(long timestamp) {
		LocalDateTime datetime = TimeConverter.oleMinutesToLocalDateTime(timestamp);
		int year = datetime.getYear();
		Month month = datetime.getMonth();
		LocalDateTime aggregationDatetime = LocalDateTime.of(year,month,1,0,0);
		return TimeConverter.DateTimeToOleMinutes(aggregationDatetime);
	}

}
