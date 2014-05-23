package dat_decode;

import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.RandomAccessFile;
import java.lang.reflect.Field;
import java.nio.MappedByteBuffer;
import java.nio.channels.FileChannel;
import java.nio.file.OpenOption;
import java.nio.file.StandardOpenOption;
import java.time.Duration;
import java.time.LocalDateTime;

/**
 * Reads the UniversalDataBinFile File Format.
 * @author Wöllauer
 *
 */
public class UniversalDataBinFile {
	
	private final String filename;
	
	private FileInputStream fileInputStream;
	private FileChannel fileChannel;
	private MappedByteBuffer mappedByteBuffer;
	private int fileSize;

	private short variableCount;
	
	TimeConverter timeConverter;
	
	private SensorHeader[] sensorHeaders;
	
	private int dataSectionStartFilePosition;
	
	
	public UniversalDataBinFile(String fileName) throws IOException {
		this.filename = fileName;
		initFile();
		readHeader();
	}
	
	private void initFile() throws IOException {
		fileInputStream = new FileInputStream(filename);
		fileChannel = fileInputStream.getChannel();
		if(fileChannel.size()>Integer.MAX_VALUE) {
			throw new RuntimeException("File > Integer.MAX_VALUE: "+fileChannel.size());
		}
		fileSize = (int) fileChannel.size();
		mappedByteBuffer = fileChannel.map(FileChannel.MapMode.READ_ONLY, 0, fileSize);
	}
	
	private void readHeader() throws IOException {
		fileChannel.position(0);

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
		variableCount = mappedByteBuffer.getShort();
		System.out.println(variableCount+" variableCount");
		
		timeConverter = new TimeConverter(startTimeToDayFactor, dActTimeToSecondFactor, startTime);
		
		readSensorHeaders();
		
		int headerEndPosition = mappedByteBuffer.position();
		
		System.out.println(headerEndPosition+"\theaderEndPosition");
		
		final int MIN_SEPARATION_CHARACTERS = 8;
		
		int minDataStartPosition = headerEndPosition + MIN_SEPARATION_CHARACTERS;
		
		final int ALIGN_GRID_SIZE = 16;
		
		int offset = ALIGN_GRID_SIZE - (minDataStartPosition % ALIGN_GRID_SIZE);
		
		System.out.println(offset+" offset");
		
		dataSectionStartFilePosition = minDataStartPosition + offset;
		
		System.out.println(dataSectionStartFilePosition+"\tdataSectionStartFilePosition");
	
		
	}
	
	private void readSensorHeaders() {
		
		sensorHeaders = new SensorHeader[variableCount];
		
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
			
			sensorHeaders[i] = new SensorHeader(name,unit,dataType);
			
		}
		
		
		
	}
	
	public void printSensorHeaders() {
		for(SensorHeader sensorHeader:sensorHeaders) {
			sensorHeader.printHeader();
		}
	}
	
	public double[][] readSensorData() {
		mappedByteBuffer.position(dataSectionStartFilePosition);
		
		int dataRowByteSize = (variableCount+1)*4; 
		
		
		System.out.println("filesize\t"+fileSize);
		System.out.println("dataSectionStartFilePosition\t"+dataSectionStartFilePosition);
		System.out.println("dataRowByteSize\t"+dataRowByteSize);

		
		if((fileSize-dataSectionStartFilePosition)%dataRowByteSize!=0){
			throw new RuntimeException("wrong data entry calculation");
		}
		
		int dataEntryCount = (fileSize-dataSectionStartFilePosition)/dataRowByteSize;
		
		
		double[][] rows = new double[dataEntryCount][];
		
		
		for(int i=0;i<dataEntryCount;i++) {			
			
			double[] row = readDataRow(i);
			
			rows[i] = row;
			
			/*
			System.out.print(oleAutomatonTimeToDateTime(offsetToOleAutomatonTime(i))+"\t");
			
			System.out.print(i+".\t");
			
			for(int c=0;c<variableCount;c++) {
				System.out.print(row[c]+"\t");
			}
			System.out.println();
			
			System.out.println(fileSize+"     "+mappedByteBuffer.position());
			*/
		}
		
		return rows;
	}
	
	public double[] readDataRow(int checkRowID) {
		double[] row = new double[variableCount];
		int rowID = mappedByteBuffer.getInt();
		if(rowID!=checkRowID) {
			throw new RuntimeException("not expected row ID: "+rowID+" should be "+checkRowID);
		}
		for(int sensorID=0;sensorID<variableCount;sensorID++) {
			switch(sensorHeaders[sensorID].dataType) {
			case 8:
				row[sensorID] = mappedByteBuffer.getFloat(); 
				break;
			case 7:
				row[sensorID] = mappedByteBuffer.getInt();
				break;
			default:
				throw new RuntimeException("type not implemented");
			}
			
		}		
		return row;
	}
	
	
	private static final LocalDateTime OLE_AUTOMATION_TIME_START = LocalDateTime.of(1899,12,30,0,0);
	
	public LocalDateTime oleAutomatonTimeToDateTime(double oleAutomatonTimestamp) {
		long oleAutomatonTimeSeconds = (long) Math.round(oleAutomatonTimestamp*24*60*60);
		return OLE_AUTOMATION_TIME_START.plus(Duration.ofSeconds(oleAutomatonTimeSeconds));
	}
	
	public SensorHeader[] getSensorHeaders() {
		return sensorHeaders;
	}
	
	public TimeConverter getTimeConverter() {
		return timeConverter;
	}
	
	

}
