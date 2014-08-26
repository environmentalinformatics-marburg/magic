package tsdb.util;

/**
 * general pair of two types
 * @author woellauer
 *
 * @param <A>
 * @param <B>
 */
public class Pair<A,B> {
	
	public final A a;
	public final B b;
	
	public Pair(A a, B b) {
		this.a = a;
		this.b = b;
	}

}
