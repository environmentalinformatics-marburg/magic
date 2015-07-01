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
	
	public static <A,B> Pair<A, B> of(A a, B b) {
		return new Pair<A, B>(a,b);
	}
	
	public static <A,B> A projA(Pair<A,B> p) {
		return p.a;
	}
	
	public static <A,B> B projB(Pair<A, B> p) {
		return p.b;
	}

}
