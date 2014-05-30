package dat_decode;

import java.io.IOException;
import java.time.Duration;
import java.time.LocalDateTime;
import java.time.temporal.TemporalAmount;

/**
 * Usecase to read a dat file.
 * @author Dogbert
 *
 */
public class UseCase1 {

	public static void main(String[] args) throws IOException {
		final String FILENAME = "K:/20130117_^b0_0016.dat";
		UniversalDataBinFile f = new UniversalDataBinFile(FILENAME);
		
		f.printSensorHeaders();
		
		f.getConsolidatedSensorData();
		
		TimeConverter timeConverter = f.getTimeConverter();
		
		for(int i=0;i<10;i++) {
			System.out.println(i+".\t"+timeConverter.offsetToOleAutomatonTime(i));
			System.out.println(i+".\t"+(timeConverter.offsetToOleAutomatonTime(i)*24*60*60));
		}
		
		System.out.println((timeConverter.offsetToOleAutomatonTime(11)-timeConverter.offsetToOleAutomatonTime(10)));
		System.out.println((timeConverter.offsetToOleAutomatonTime(11)-timeConverter.offsetToOleAutomatonTime(10))*24*60*60);
		
		LocalDateTime oleAutomationTimeStart = LocalDateTime.of(1899,12,30,0,0);
		
		System.out.println(oleAutomationTimeStart);
		
		
		long seconds = (long) ((timeConverter.offsetToOleAutomatonTime(11)-timeConverter.offsetToOleAutomatonTime(10))*24*60*60);
		TemporalAmount amountToAdd = Duration.ofSeconds(seconds);
		LocalDateTime newTime = oleAutomationTimeStart.plus(amountToAdd);
		
		System.out.println(newTime);
		
		
		System.out.println(timeConverter.offsetToOleAutomatonTime(0)*24*60*60);
		long sensorSeconds = (long) (timeConverter.offsetToOleAutomatonTime(0)*24*60*60);
		System.out.println(sensorSeconds);
		LocalDateTime sensorTime = oleAutomationTimeStart.plus(Duration.ofSeconds(sensorSeconds));
		
		System.out.println(sensorTime);
		
		
		SensorData sensorData = f.getConsolidatedSensorData();
		
		sensorData.getSensor(3).print(10);
		
	}

}
