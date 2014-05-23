package dat_decode;

import java.io.*;
import java.nio.*;
import java.nio.channels.*;
import java.util.Arrays;
import java.io.RandomAccessFile;

/**
 * testing
 * @author Wöllauer
 *
 */
public class Main {
	
	private static class DataEntry {
		
		public final String title;
		public final String unit;
		
		public DataEntry(String title, String unit) {
			this.title = title;
			this.unit = unit;
		}
	}
	
	
	final static int RAW_HEADER_ENTRY_ONE_SIZE = 5;
	final static int RAW_HEADER_ENTRY_TWO_SIZE = 10;
	
	/*
	 * Gesamtheader: 688 Bytes
	 * 
	 * 
	*/
	
	MappedByteBuffer mappedByteBuffer;

	public static void main(String[] args) throws IOException {
		Main main = new Main();
		main.run();
	}
	
	public void run() throws IOException {
		
		
		
		RandomAccessFile randomAccessFile = new RandomAccessFile("20130117_^b0_0016.dat","rw");
		FileChannel fileChannel = randomAccessFile.getChannel();
		mappedByteBuffer = fileChannel.map(FileChannel.MapMode.READ_ONLY, 0, Integer.MAX_VALUE);
		printRaw(RAW_HEADER_ENTRY_ONE_SIZE);
		String signatur = new String(readBytes(42));
		System.out.println(signatur);
		printRaw(41);
		System.out.println("----------------------");		
		/*byte z0 = mappedByteBuffer.get();
		String CycleCounter = new String(readBytes(z0-1));
		System.out.println("CycleCounter: "+CycleCounter);
		printRaw(RAW_HEADER_ENTRY_TWO_SIZE);
		byte s0 = mappedByteBuffer.get();
		String einheit0 = new String(readBytes(s0-1));
		System.out.println("einheit0: "+einheit0);		
		printRaw(RAW_HEADER_ENTRY_ONE_SIZE);
		//parameter start
		System.out.println("----------------------");
		String LF_200_MIN = new String(readBytes(10));
		System.out.println("LF_200_MIN: "+LF_200_MIN);
		printRaw(RAW_HEADER_ENTRY_TWO_SIZE);
		byte s1 = mappedByteBuffer.get();
		String einheit1 = new String(readBytes(s1-1));
		System.out.println("einheit1: "+einheit1);		
		printRaw(RAW_HEADER_ENTRY_ONE_SIZE);
		System.out.println("----------------------");
		String v3 = new String(readBytes(10));
		System.out.println(v3);
		printRaw(RAW_HEADER_ENTRY_TWO_SIZE);
		byte s2 = mappedByteBuffer.get();
		String einheit2 = new String(readBytes(s2-1));
		System.out.println("einheit2: "+einheit2);		
		printRaw(RAW_HEADER_ENTRY_ONE_SIZE);
		System.out.println("----------------------");
		String v4 = new String(readBytes(10));
		System.out.println(v4);
		printRaw(RAW_HEADER_ENTRY_TWO_SIZE);
		byte s3 = mappedByteBuffer.get();
		String einheit3 = new String(readBytes(s3-1));
		System.out.println("einheit3: "+einheit3);		
		printRaw(RAW_HEADER_ENTRY_ONE_SIZE);
		System.out.println("----------------------");
		String v5 = new String(readBytes(10));
		System.out.println(v5);
		printRaw(RAW_HEADER_ENTRY_TWO_SIZE);
		byte s4 = mappedByteBuffer.get();
		String einheit4 = new String(readBytes(s4-1));
		System.out.println("einheit4: "+einheit4);		
		printRaw(RAW_HEADER_ENTRY_ONE_SIZE);
		System.out.println("----------------------");*/	
		
		
	
		int entries=0;
		while(true) {
			boolean next = readHeaderEntry();
			entries++;
			if(!next) {
				break;
			}
		}
		
		System.out.println("Entries: "+entries);
		
		System.out.println();
		
		printRaw(17);
		
		System.out.println();
		
		for(int i=0;i<10;i++) {
			printData(entries);
		}

	}
	
	public byte[] readBytes(int n) {		
		byte[] dst = new byte[n];
		mappedByteBuffer.get(dst);
		return dst;
	}
	
	public void printRaw(int n) {
		System.out.println("\t\t\t\t"+Arrays.toString(readBytes(n)));
	}
	
	
	public boolean readHeaderEntry() {
		byte s2 = mappedByteBuffer.get();
		String title = new String(readBytes(s2-1));
		System.out.println("title:\t"+title);
		printRaw(10);
		byte s4 = mappedByteBuffer.get();
		String unit = new String(readBytes(s4-1));
		System.out.println("unit:\t"+unit);
		int int0 = mappedByteBuffer.getInt();
		
		
		DataEntry dataEntry = new DataEntry(title,unit);
		
		
		if(int0==42) {
			System.out.println("----------------------(last entry)");
			return false;
		} else if(int0==0){
			System.out.println("----------------------");
			return true;
		} else {
			System.out.println("----------------------(unknown value: "+int0);
			return false;
		}
	}
	
	public void printData(int entries) {
		//String s="";
		for(int i=0;i<entries+1;i++) {
			if(i<2) {
				int v = mappedByteBuffer.getInt();
				//s += v + " ";
				System.out.print(v+"\t");
			} else {
				float v = mappedByteBuffer.getFloat();
				//s += v + "\t";
				System.out.format("%.2f\t", v);
			}
			
		}
		//System.out.println(s);
		System.out.println();
	}
	

}
