package tsdb.graph;

/**
 * Interface of generator functions of continuous nodes
 * @author woellauer
 *
 */
@FunctionalInterface
public interface ContinuousGen {	
	public Continuous get(String stationName, String... schema);
}
