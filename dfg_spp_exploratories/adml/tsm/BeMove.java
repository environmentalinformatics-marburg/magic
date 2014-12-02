import java.io.File;
import java.io.IOException;
import java.nio.file.FileSystems;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;



public class BeMove {

	public void listDir(File dir) {
		  File[] files = dir.listFiles();
		  if (files != null) { // Erforderliche Berechtigungen etc. sind vorhanden
		    for (int i = 0; i < files.length; i++) {
		      System.out.print(files[i].getAbsolutePath());
		      if (files[i].isDirectory()) {
		        System.out.println(" (Ordner)\n");
		      }
		      else {
		    	  Path oldName = files[i].getAbsoluteFile().toPath();
		          Path newName = FileSystems.getDefault().getPath( oldName.getParent() + 
		        		  "/backup/" + files[i].getName());
		          System.out.println(newName);
		          try {
		        	  Files.move(oldName, newName, StandardCopyOption.REPLACE_EXISTING);
		          } catch (IOException e) {
		              System.err.println(e);
		          }
		      }
		    }
		  }
		}
	
	
	public static String substringBetween(String str, String open, String close) {
	      if (str == null || open == null || close == null) {
	          return null;
	      }
	      int start = str.indexOf(open);
	      if (start != -1) {
	          int end = str.indexOf(close, start + open.length());
	          if (end != -1) {
	              return str.substring(start + open.length(), end);
	          }
	      }
	      return null;
	  }
	
	/**
	 * @param args
	 */
	public static void main(String[] args) {
		BeMove test = new BeMove();
		//String station = substringBetween(oldName, "/", "/backup");

		File[] files = new File(args[0]).listFiles();
		if (files != null) { // Erforderliche Berechtigungen etc. sind vorhanden
		    for (int i = 0; i < files.length; i++) {
		      System.out.print(files[i].getAbsolutePath());
		      if (files[i].isDirectory()) {
		    	  test.listDir(files[i]);
		      }
		    }
		 }
		
	}

}
