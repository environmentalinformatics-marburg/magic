package tsdb.util;

import java.io.Serializable;

public class TimestampInterval<T extends Serializable> implements Serializable {
	
	private static final long serialVersionUID = 1733091691391404002L;
	public final T value;
	public final Long start;
	public final Long end;
	
	public TimestampInterval(T value, Long start, Long end) {
		this.value = value;
		this.start = start;
		this.end = end;
	}

	@Override
	public String toString() {
		return value.toString()+" ["+start+" - "+end+"]";
	}
	
	 

}
