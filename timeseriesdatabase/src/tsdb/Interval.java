package tsdb;

import java.io.DataInput;
import java.io.DataOutput;
import java.io.IOException;
import java.io.Serializable;

import org.mapdb.Serializer;

public class Interval {
	public final int start; // start <= end
	public final int end;
	
	protected Interval(int start, int end) {			
		this.start = start;
		this.end = end;
	}
	
	public static Interval of(int start, int end) {
		if(start>end) {
			throw new RuntimeException();
		}
		return new Interval(start, end);
	}
	
	public static boolean isAdjacentOrOverlap(Interval a, Interval b) {
		if(a.end+1==b.start || b.end+1==a.start) {
			return true;
		}
		return a.end >= b.start && a.start <= b.end;
	}
	
	public static Interval getEnvelope(Interval a, Interval b) {
		return Interval.of(Math.min(a.start, b.start),Math.max(a.end, b.end));
	}
	
	public boolean less(Interval other) {
		return this.end<other.start;
	}
	
	@Override
	public String toString() {
		return "["+TimeConverter.oleMinutesToText((long) start)+" .. "+TimeConverter.oleMinutesToText((long) end)+"]";
	}
	
	private static class IntervalSerializer implements Serializer<Interval>, Serializable {
		private static final long serialVersionUID = 5604613139076007495L;
		@Override
		public void serialize(DataOutput out, Interval value) throws IOException {
			out.writeInt(value.start);
			out.writeInt(value.end);
		}
		@Override
		public Interval deserialize(DataInput in, int available) throws IOException {
			int start = in.readInt();
			int end = in.readInt();
			return new Interval(start,end);
		}
		@Override
		public int fixedSize() {
			return 4+4;
		}
	};
	
	public static final Serializer<Interval> SERIALIZER = new IntervalSerializer();
}