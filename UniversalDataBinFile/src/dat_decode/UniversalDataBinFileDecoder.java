package dat_decode;

import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.RandomAccessFile;
import java.nio.MappedByteBuffer;
import java.nio.channels.FileChannel;

/**
 * Testing.
 * @author Wöllauer
 *
 */
public class UniversalDataBinFileDecoder {
	
	MappedByteBuffer mappedByteBuffer;

	public static void main(String[] args) throws IOException {
		UniversalDataBinFileDecoder universalDataBinFileDecoder = new UniversalDataBinFileDecoder();
		universalDataBinFileDecoder.run();
	}
	
	public void run() throws IOException {
		RandomAccessFile randomAccessFile = new RandomAccessFile("20130117_^b0_0016.dat","rw");
		FileChannel fileChannel = randomAccessFile.getChannel();		
		mappedByteBuffer = fileChannel.map(FileChannel.MapMode.READ_ONLY, 0, Integer.MAX_VALUE);
		
		byte isBigEndian = mappedByteBuffer.get();
		System.out.println(isBigEndian+"\tisBigEndian");
		if(isBigEndian!=1) {
			throw new RuntimeException("Universal-Data-Bin-File variant not implemented");
		}		
		short version = mappedByteBuffer.getShort();
		System.out.println(version+"\tversion");
		if(version!=107) {
			throw new RuntimeException("just Universal-Data-Bin-File version 1.07 implemented");
		}
		short typeVendorLen  = mappedByteBuffer.getShort();
		System.out.println(typeVendorLen+"\ttypeVendorLen");
		byte[] typeVendorBytes = new byte[typeVendorLen]; 
		mappedByteBuffer.get(typeVendorBytes);
		String typeVendor = new String(typeVendorBytes);
		System.out.println(typeVendor+"\ttypeVendor");
		byte withCheckSum = mappedByteBuffer.get();
		System.out.println(withCheckSum+"\twithCheckSum");
		short moduleAdditionalDataLen = mappedByteBuffer.getShort();
		System.out.println(moduleAdditionalDataLen+"\tmoduleAdditionalDataLen");
		if(moduleAdditionalDataLen>0) {
			throw new RuntimeException("reading of additional optional data in header not implemented");
		}
		double startTimeToDayFactor = mappedByteBuffer.getDouble();
		System.out.println(startTimeToDayFactor+"\tstartTimeToDayFactor");
		short dActTimeDataType = mappedByteBuffer.getShort();
		System.out.println(dActTimeDataType+"\tdActTimeDataType");
		double dActTimeToSecondFactor = mappedByteBuffer.getDouble();
		System.out.println(dActTimeToSecondFactor+"\tdActTimeToSecondFactor");
		double startTime = mappedByteBuffer.getDouble();
		System.out.println(startTime+"\tstartTime");
		double sampleRate = mappedByteBuffer.getDouble();
		System.out.println(sampleRate+"\tsampleRate");
		short variableCount = mappedByteBuffer.getShort();
		System.out.println(variableCount+" variableCount");
		
		for(int i=0;i<variableCount;i++) {
			short nameLen = mappedByteBuffer.getShort();
			System.out.println(nameLen+"\tnameLen");
			byte[] nameBytes = new byte[nameLen-1];
			mappedByteBuffer.get(nameBytes);
			mappedByteBuffer.get();
			String name = new String(nameBytes);
			System.out.println(name+"\tname");
			short dataDirection = mappedByteBuffer.getShort();
			System.out.println(dataDirection+"\tdataDirection");
			short dataType = mappedByteBuffer.getShort();
			System.out.println(dataType+"\tdataType");
			short fieldLen = mappedByteBuffer.getShort();
			System.out.println(fieldLen+"\tfieldLen");
			short precision = mappedByteBuffer.getShort();
			System.out.println(precision+"\tprecision");
			short unitLen = mappedByteBuffer.getShort();
			System.out.println(unitLen+"\tunitLen");
			byte[] unitBytes = new byte[unitLen-1];
			mappedByteBuffer.get(unitBytes);
			String unit = new String(unitBytes);
			System.out.println('"'+unit+"\"\tunit");
			short additionalDataLen = mappedByteBuffer.getShort();
			System.out.println(additionalDataLen+"\tadditionalDataLen");
			if(additionalDataLen!=0) {
				throw new RuntimeException("reading of additional optional data in element header not implemented");
			}
			System.out.println(mappedByteBuffer.get()+"\t?");
			
		}
		System.out.println(mappedByteBuffer.limit()+" file limit");
		System.out.println(mappedByteBuffer.get()+" ");
		
	}

}
