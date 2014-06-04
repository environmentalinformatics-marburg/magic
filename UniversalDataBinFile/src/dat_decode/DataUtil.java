package dat_decode;

/**
* Helper methods.
* @author Wöllauer
*
*/
public class DataUtil {
	
	public static void printArray(float[] data, int maxPrint) {
		int n = data.length<maxPrint?data.length:maxPrint;
		for(int i=0;i<n;i++) {
			//System.out.print(data[i]+"\t");
			System.out.format("%.2f\t",data[i]);
		}
		System.out.println();
	}
	
	public static void printArray(int[] data) {
		int n = data.length<10?data.length:10;
		for(int i=0;i<n;i++) {
			//System.out.print(data[i]+"\t");
			System.out.format(data[i]+"\t");
		}
		System.out.println();
	}
	
	public static String arrayToString(int[] data) {
		String s="";
		int n = data.length<10?data.length:10;
		for(int i=0;i<n;i++) {
			//System.out.print(data[i]+"\t");
			s+=data[i]+"\t";
		}
		return s;
	}

}
