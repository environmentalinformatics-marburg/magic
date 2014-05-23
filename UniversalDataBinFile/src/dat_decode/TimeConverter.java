package dat_decode;

import java.time.Duration;
import java.time.LocalDateTime;

/**
 * Converts UniversalDataBinFile time format to Java LocalDateTime.
 * @author Wöllauer
 *
 */
public class TimeConverter {
	
	private static final LocalDateTime OLE_AUTOMATION_TIME_START = LocalDateTime.of(1899,12,30,0,0);
	
	private final double dActTimeToSecondFactor;
	private final double startTime;
	private final double startTimeToDayFactor;
	
	public TimeConverter(double startTimeToDayFactor, double dActTimeToSecondFactor, double startTime) {
		this.startTimeToDayFactor = startTimeToDayFactor;
		this.dActTimeToSecondFactor = dActTimeToSecondFactor;
		this.startTime = startTime;
	}	
	
	public LocalDateTime oleAutomatonTimeToDateTime(double oleAutomatonTimestamp) {
		long oleAutomatonTimeSeconds = (long) Math.round(oleAutomatonTimestamp*24*60*60);
		return OLE_AUTOMATION_TIME_START.plus(Duration.ofSeconds(oleAutomatonTimeSeconds));
	}
	
	public double offsetToOleAutomatonTime(int offset) {
		return startTime*startTimeToDayFactor + (offset*dActTimeToSecondFactor)/86400d;		
	}
	
	public LocalDateTime offsetToDateTime(int offset) {
		return oleAutomatonTimeToDateTime(offsetToOleAutomatonTime(offset));
	}
	
	public double getStartOleAutomatonTime() {
		return startTime*startTimeToDayFactor;
	}
	
	public LocalDateTime getStartDateTime() {
		return oleAutomatonTimeToDateTime(getStartOleAutomatonTime());
	}
}
