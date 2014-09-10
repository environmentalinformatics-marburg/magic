package tsdb;

import java.io.Serializable;
import java.time.Duration;
import java.time.LocalDateTime;

/**
 * This class convertes beween date and time systems and keeps timestamp info from a UDBF-File.
 * @author woellauer
 *
 */
public class TimeConverter implements Serializable {
	
	private static final long serialVersionUID = 4232805611076305334L;

	private static final LocalDateTime OLE_AUTOMATION_TIME_START = LocalDateTime.of(1899,12,30,0,0);
	
	private final double dActTimeToSecondFactor;
	private final double startTime;
	private final double startTimeToDayFactor;
	//private final double sampleRate;
	
	public TimeConverter(double startTimeToDayFactor, double dActTimeToSecondFactor, double startTime, double sampleRate) {
		this.startTimeToDayFactor = startTimeToDayFactor;
		this.dActTimeToSecondFactor = dActTimeToSecondFactor;
		this.startTime = startTime;
		//this.sampleRate = sampleRate;
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
	
	public long getStartTimeOleMinutes() {
		return (long) Math.round(getStartOleAutomatonTime()*24d*60d);
	}
	
	public Duration getTimeStep() {
		long oleAutomatonTimeSeconds = (long) Math.round((dActTimeToSecondFactor/86400d)*24*60*60);		
		return Duration.ofSeconds(oleAutomatonTimeSeconds);
	}
	
	public long getTimeStepMinutes() {
		return (long) Math.round((dActTimeToSecondFactor/86400d)*24d*60d);
	}
	
	public static LocalDateTime oleMinutesToLocalDateTime(long oleTimeMinutes) {
		return OLE_AUTOMATION_TIME_START.plus(Duration.ofMinutes(oleTimeMinutes));
	}
	
	public static Duration minutesToDuration(long minutes) {
		return Duration.ofMinutes(minutes);
	}
	
	public static long DateTimeToOleMinutes(LocalDateTime datetime) {
		return Duration.between(OLE_AUTOMATION_TIME_START, datetime).toMinutes();
	}
	
	public static String oleMinutesToText(Long oleTimeMinutes) {
		if(oleTimeMinutes==null) {
			return "---";
		}
		return oleMinutesToLocalDateTime(oleTimeMinutes).toString();
	}
	
	public static long parseTimestamp(String dateText, String timeText, boolean isISOdate) {		
		int dayOfMonth;
		int month;
		int year;
		
		if(isISOdate) {
			// 2012-06-15
			// 0123456789
			year = 1000*(dateText.charAt(0)-'0')+100*(dateText.charAt(1)-'0')+10*(dateText.charAt(2)-'0')+(dateText.charAt(3)-'0');
			month = 10*(dateText.charAt(5)-'0')+(dateText.charAt(6)-'0');
			dayOfMonth = 10*(dateText.charAt(8)-'0')+(dateText.charAt(9)-'0');
		} else {
			// 01.07.13
			dayOfMonth = 10*(dateText.charAt(0)-'0')+(dateText.charAt(1)-'0');
			month = 10*(dateText.charAt(3)-'0')+(dateText.charAt(4)-'0');
			year = 2000 + 10*(dateText.charAt(6)-'0')+(dateText.charAt(7)-'0');
		}	

		// 09:30:00
		int hour = 10*(timeText.charAt(0)-'0')+(timeText.charAt(1)-'0');
		int minute = 10*(timeText.charAt(3)-'0')+(timeText.charAt(4)-'0');
		int second = 10*(timeText.charAt(6)-'0')+(timeText.charAt(7)-'0');

		LocalDateTime datetime = LocalDateTime.of(year, month, dayOfMonth, hour, minute, second);
		return TimeConverter.DateTimeToOleMinutes(datetime);
	}
}
