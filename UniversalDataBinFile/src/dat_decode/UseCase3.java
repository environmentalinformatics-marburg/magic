package dat_decode;

import java.io.IOException;
import java.nio.file.FileVisitOption;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.stream.Stream;

/**
 * Use case to read all dat files in one directory.
 * @author Wöllauer
 *
 */
public class UseCase3 {
	
	public static void main(String[] args) throws IOException {
		String dat_extension = ".dat";
		Path rootPath = Paths.get("K:/HG12");
		System.out.println("Path: "+rootPath);
		Stream<Path> pathStream = Files.walk(rootPath);
		Stream<Path> filteredStream = pathStream.filter((x)->x.toString().endsWith(dat_extension));
		filteredStream.forEach(filePath -> {
			System.out.println("filePath: "+filePath);
			try {
				UniversalDataBinFile udbf = new UniversalDataBinFile(filePath.toString());
				SensorData sensorData = udbf.getSensorData();
				System.out.println("sensors:\t"+sensorData.getSensorCount());
				System.out.println(sensorData.getSensorNames());
				System.out.println("bad row count:\t"+sensorData.getBadRowCount());
				System.out.println(sensorData.getSensor(0).getFirstDateTime()+" - "+ sensorData.getSensor(0).getLastDateTime()+": "+sensorData.getSensor(0).getTimeStep());
			} catch (Exception e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
		});
		
	}

}
