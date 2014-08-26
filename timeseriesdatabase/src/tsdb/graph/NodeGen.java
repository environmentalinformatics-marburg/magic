package tsdb.graph;

public interface NodeGen {
	public Node get(String stationID, String[] schema);
}
