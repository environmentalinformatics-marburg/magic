package tsdb.util;

import java.io.Serializable;
import java.util.Comparator;

import static tsdb.util.AssumptionCheck.*;

public class TimestampInterval<T extends Serializable> implements Serializable {

	private static final long serialVersionUID = 1733091691391404002L;
	public final T value; //not null
	public final Long start; //nullable
	public final Long end; //nullable

	public TimestampInterval(T value, Long start, Long end) {
		throwNull(value);
		throwGreater(start,end);
		this.value = value;
		this.start = start;
		this.end = end;
	}

	public boolean contains(long start, long end) {
		throwGreater(start,end);
		return (this.start==null?true:this.start<=start) && (this.end==null?true:end<=this.end);
	}

	@Override
	public String toString() {
		return value.toString()+" ["+start+" - "+end+"]";
	}

	public static final Comparator<TimestampInterval<?>> END_COMPARATOR = (t1,t2)->{
		if(t1.end==null) {
			if(t2.end==null) {
				return 0;
			} else {
				return 1;
			}
		} else {
			if(t2.end==null) {
				return -1;
			} else {
				return Long.compare(t1.end,t2.end);
			}
		}
	}; 
}
