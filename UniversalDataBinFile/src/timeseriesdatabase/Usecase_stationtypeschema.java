package timeseriesdatabase;

import java.io.File;
import java.io.IOException;

import org.ini4j.InvalidFileFormatException;
import org.ini4j.Profile.Section;
import org.ini4j.Wini;

public class Usecase_stationtypeschema {

	public static void main(String[] args) throws InvalidFileFormatException, IOException {
		System.out.println("begin...");
		
		Wini ini = new Wini(new File("config/station_type_schema.ini"));
		
		
		for(String key:ini.keySet()) {
			System.out.println(key);
			Section section = ini.get(key);
			System.out.println(section.keySet());
		}
		
		System.out.println();
		
		System.out.println("...end");
	}

}
