package dat_decode;

import java.io.IOException;
import java.time.Duration;
import java.time.LocalDateTime;
import java.time.temporal.TemporalAmount;

public class UseCase1 {

	public static void main(String[] args) throws IOException {
		final String FILENAME = "20130117_^b0_0016.dat";
		UniversalDataBinFile f = new UniversalDataBinFile(FILENAME);
		
		f.printSensorHeaders();
		
		f.readSensorData();
		
		for(int i=0;i<10;i++) {
			System.out.println(i+".\t"+f.offsetToOleAutomatonTime(i));
			System.out.println(i+".\t"+(f.offsetToOleAutomatonTime(i)*24*60*60));
		}
		
		System.out.println((f.offsetToOleAutomatonTime(11)-f.offsetToOleAutomatonTime(10)));
		System.out.println((f.offsetToOleAutomatonTime(11)-f.offsetToOleAutomatonTime(10))*24*60*60);
		
		LocalDateTime oleAutomationTimeStart = LocalDateTime.of(1899,12,30,0,0);
		
		System.out.println(oleAutomationTimeStart);
		
		
		long seconds = (long) ((f.offsetToOleAutomatonTime(11)-f.offsetToOleAutomatonTime(10))*24*60*60);
		TemporalAmount amountToAdd = Duration.ofSeconds(seconds);
		LocalDateTime newTime = oleAutomationTimeStart.plus(amountToAdd);
		
		System.out.println(newTime);
		
		
		System.out.println(f.offsetToOleAutomatonTime(0)*24*60*60);
		long sensorSeconds = (long) (f.offsetToOleAutomatonTime(0)*24*60*60);
		System.out.println(sensorSeconds);
		LocalDateTime sensorTime = oleAutomationTimeStart.plus(Duration.ofSeconds(sensorSeconds));
		
		System.out.println(sensorTime);
		
	}

}
