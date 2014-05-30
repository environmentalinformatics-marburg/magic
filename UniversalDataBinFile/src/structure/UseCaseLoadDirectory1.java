package structure;

import java.nio.file.Path;
import java.nio.file.Paths;


import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public class UseCaseLoadDirectory1 {
	
	private static final Logger log = LogManager.getLogger("general");
	
	public static void main(String[] args){
		
		Path rootPath = Paths.get("K:/incoming_ftp/adl-m/HEG");
		
		Database database = new Database();
		
		System.gc();
		Runtime runtime = Runtime.getRuntime();
		
		System.out.println("total memory: "+runtime.totalMemory()+" Bytes");
		
		System.out.println("read "+rootPath+" ...");
		database.loadDirectoryOfOneExploratory(rootPath);
		System.out.println("... end");
		
		System.gc();
		System.out.println("total memory: "+runtime.totalMemory()+" Bytes");
		
		database.printInfo();
		
	}

}
