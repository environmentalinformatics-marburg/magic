package tsdb.util;

public interface ProcessingChainEntry {	
	String getProcessingTitle();
	
	public static ProcessingChainTitle createUnknown() {
		return ProcessingChainTitle.createUnknown();
	}
	
	public static ProcessingChainTitle of(String title) {
		return ProcessingChainTitle.of(title);
	}	
}
