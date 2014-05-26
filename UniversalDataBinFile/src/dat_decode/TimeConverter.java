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
	private final double sampleRate;
	
	public TimeConverter(double startTimeToDayFactor, double dActTimeToSecondFactor, double startTime, double sampleRate) {
		this.startTimeToDayFactor = startTimeToDayFactor;
		this.dActTimeToSecondFactor = dActTimeToSecondFactor;
		this.startTime = startTime;
		this.sampleRate = sampleRate;
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
	
	public Duration getTimeStep() {
		//System.out.println("sampleRate: "+sampleRate);
		//System.out.println("dActTimeToSecondFactor: "+dActTimeToSecondFactor/86400d);
		//double s = sampleRate*60*60*24;
		//System.out.println("samples per day: "+s);
		long oleAutomatonTimeSeconds = (long) Math.round((dActTimeToSecondFactor/86400d)*24*60*60);		
		return Duration.ofSeconds(oleAutomatonTimeSeconds);
	}
}
