package structure;

import java.nio.file.Path;
import java.nio.file.Paths;


import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public class UseCaseLoadDirectory1 {
	
	private static final Logger log = LogManager.getLogger("general");
	
	public static void main(String[] args){
		
		/*
		log.trace("This is a trace message.");
		log.debug("This is  a debug message.");
		log.info("This is an info message.");
		log.error("This is an error message");
		*/
		
		
		Path rootPath = Paths.get("K:/incoming_ftp/adl-m/HEG");
		
		Database database = new Database();
		
		database.loadDirectoryOfOneExploratory(rootPath);
		
	}

}
