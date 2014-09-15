package tsdb.util;

import java.io.Serializable;

public class TimestampInterval<T extends Serializable> implements Serializable {
	
	private static final long serialVersionUID = 1733091691391404002L;
	public final T value; //not null
	public final Long start; //nullable
	public final Long end; //nullable
	
	public TimestampInterval(T value, Long start, Long end) {
		Util.throwNull(value);
		Util.throwGreater(start,end);
		this.value = value;
		this.start = start;
		this.end = end;
	}
	
	public boolean contains(long start, long end) {
		Util.throwGreater(start,end);
		return (this.start==null?true:this.start<=start) && (this.end==null?true:end<=this.end);
	}

	@Override
	public String toString() {
		return value.toString()+" ["+start+" - "+end+"]";
	}
}
