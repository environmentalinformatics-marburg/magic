package tsdb.util;

public class TimestampInterval<T> {
	
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
