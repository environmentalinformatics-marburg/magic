package dat_decode;

import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.PrintStream;
import java.io.RandomAccessFile;
import java.lang.reflect.Field;
import java.nio.MappedByteBuffer;
import java.nio.channels.FileChannel;
import java.nio.file.OpenOption;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;
import java.util.Map.Entry;
import java.util.function.Function;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

/**
 * Reads the UniversalDataBinFile File Format.
 * @author Wöllauer
 *
 */
public class UniversalDataBinFile {
	
	private static final Logger log = LogManager.getLogger("general");
	
	private final String filename;
	
	private FileInputStream fileInputStream;
	private FileChannel fileChannel;
	private MappedByteBuffer mappedByteBuffer;
	private int fileSize;

	private short variableCount;
	
	TimeConverter timeConverter;
	
	private SensorHeader[] sensorHeaders;
	
	private int dataSectionStartFilePosition;
	
	int badRowCount = 0;
	
	
	public UniversalDataBinFile(String fileName) throws IOException {
		this.filename = fileName;
		initFile();
		readHeader();
	}
	
	/**
	 * Opens a dat file for reading.
	 * @throws IOException
	 */
	private void initFile() throws IOException {
		fileInputStream = new FileInputStream(filename);
		fileChannel = fileInputStream.getChannel();
		if(fileChannel.size()>Integer.MAX_VALUE) {
			throw new RuntimeException("File > Integer.MAX_VALUE: "+fileChannel.size());
		}
		fileSize = (int) fileChannel.size();
		mappedByteBuffer = fileChannel.map(FileChannel.MapMode.READ_ONLY, 0, fileSize);
	}
	
	/**
	 * Reads header info of data file.
	 * @throws IOException
	 */
	private void readHeader() throws IOException {
		fileChannel.position(0);

		byte isBigEndian = mappedByteBuffer.get();
		//System.out.println(isBigEndian+"\tisBigEndian");
		if(isBigEndian!=1) {
			throw new RuntimeException("Universal-Data-Bin-File variant not implemented");
		}		
		short version = mappedByteBuffer.getShort();
		//System.out.println(version+"\tversion");
		if(version!=107) {
			throw new RuntimeException("just Universal-Data-Bin-File version 1.07 implemented");
		}
		short typeVendorLen  = mappedByteBuffer.getShort();
		//System.out.println(typeVendorLen+"\ttypeVendorLen");
		byte[] typeVendorBytes = new byte[typeVendorLen]; 
		mappedByteBuffer.get(typeVendorBytes);
		String typeVendor = new String(typeVendorBytes);
		//System.out.println(typeVendor+"\ttypeVendor");
		byte withCheckSum = mappedByteBuffer.get();
		//System.out.println(withCheckSum+"\twithCheckSum");
		short moduleAdditionalDataLen = mappedByteBuffer.getShort();
		//System.out.println(moduleAdditionalDataLen+"\tmoduleAdditionalDataLen");
		if(moduleAdditionalDataLen>0) {
			throw new RuntimeException("reading of additional optional data in header not implemented");
		}
		double startTimeToDayFactor = mappedByteBuffer.getDouble();
		//System.out.println(startTimeToDayFactor+"\tstartTimeToDayFactor");
		short dActTimeDataType = mappedByteBuffer.getShort();
		//System.out.println(dActTimeDataType+"\tdActTimeDataType");
		double dActTimeToSecondFactor = mappedByteBuffer.getDouble();
		//System.out.println(dActTimeToSecondFactor+"\tdActTimeToSecondFactor");
		double startTime = mappedByteBuffer.getDouble();
		//System.out.println(startTime+"\tstartTime");
		double sampleRate = mappedByteBuffer.getDouble();
		//System.out.println(sampleRate+"\tsampleRate");
		variableCount = mappedByteBuffer.getShort();
		//System.out.println(variableCount+" variableCount");
		
		timeConverter = new TimeConverter(startTimeToDayFactor, dActTimeToSecondFactor, startTime, sampleRate);
		
		readSensorHeaders();
		
		int headerEndPosition = mappedByteBuffer.position();
		
		//System.out.println(headerEndPosition+"\theaderEndPosition");
		
		final int MIN_SEPARATION_CHARACTERS = 8;
		
		int minDataStartPosition = headerEndPosition + MIN_SEPARATION_CHARACTERS;
		
		final int ALIGN_GRID_SIZE = 16;
		
		int offset = (minDataStartPosition % ALIGN_GRID_SIZE)==0?0:ALIGN_GRID_SIZE - (minDataStartPosition % ALIGN_GRID_SIZE);
		
		//System.out.println(offset+" offset");
		
		dataSectionStartFilePosition = minDataStartPosition + offset;
		
		//System.out.println(dataSectionStartFilePosition+"\tdataSectionStartFilePosition");
	
		
	}
	
	/**
	 * Reads header info for all sensor entries. 
	 */
	private void readSensorHeaders() {
		
		sensorHeaders = new SensorHeader[variableCount];
		
		for(int i=0;i<variableCount;i++) {
			short nameLen = mappedByteBuffer.getShort();
			//System.out.println(nameLen+"\tnameLen");
			byte[] nameBytes = new byte[nameLen-1];
			mappedByteBuffer.get(nameBytes);
			mappedByteBuffer.get();
			String name = new String(nameBytes);
			//System.out.println(name+"\tname");
			short dataDirection = mappedByteBuffer.getShort();
			//System.out.println(dataDirection+"\tdataDirection");
			short dataType = mappedByteBuffer.getShort();
			//System.out.println(dataType+"\tdataType");
			short fieldLen = mappedByteBuffer.getShort();
			//System.out.println(fieldLen+"\tfieldLen");
			short precision = mappedByteBuffer.getShort();
			//System.out.println(precision+"\tprecision");
			short unitLen = mappedByteBuffer.getShort();
			//System.out.println(unitLen+"\tunitLen");
			byte[] unitBytes = new byte[unitLen-1];
			mappedByteBuffer.get(unitBytes);
			String unit = new String(unitBytes);
			//System.out.println('"'+unit+"\"\tunit");
			short additionalDataLen = mappedByteBuffer.getShort();
			//System.out.println(additionalDataLen+"\tadditionalDataLen");
			if(additionalDataLen!=0) {
				throw new RuntimeException("reading of additional optional data in element header not implemented");
			}
			byte b = mappedByteBuffer.get();
			//System.out.println(b+"\t?");
			
			sensorHeaders[i] = new SensorHeader(name,unit,dataType);
			
			
			
		}
		
		int nullCount=0;
		for(int i=0;i<sensorHeaders.length;i++) {
			if(sensorHeaders[i].dataType==0) {
				nullCount++;
				//System.out.println("warning: header entry with no data: "+sensorHeaders[i].name+"\t"+sensorHeaders[i].unit);
			}
		}
		
		if(nullCount>0) {
			SensorHeader[] temp = new SensorHeader[sensorHeaders.length-nullCount];
			int c=0;
			for(int i=0;i<sensorHeaders.length;i++) {
				if(sensorHeaders[i].dataType!=0) {
					temp[c] = sensorHeaders[i];
					c++;
				}
			}
			sensorHeaders = temp;
			variableCount = (short) sensorHeaders.length;
		}
		
		
		
	}
	

	/**
	 * Reads all data rows from file without further processing.
	 * @return Array of Datarows
	 */
	public DataRow[] readDataRows() {
		mappedByteBuffer.position(dataSectionStartFilePosition);
		int dataRowByteSize = (variableCount+1)*4;
		
		if((fileSize-dataSectionStartFilePosition)%dataRowByteSize!=0){
			log.warn("file end not at boundary of data entry grid: "+filename+"\t"+fileSize+"\t"+dataSectionStartFilePosition+"\t"+dataRowByteSize+"\t"+(fileSize-dataSectionStartFilePosition)%dataRowByteSize+"\t"+timeConverter.getStartDateTime());
			//return null;
		}
		
		int dataEntryCount = (fileSize-dataSectionStartFilePosition)/dataRowByteSize;
		
		DataRow[] datarows = new DataRow[dataEntryCount];
		
		for(int i=0;i<dataEntryCount;i++) {
			float[] data = new float[variableCount];
			int rowID = mappedByteBuffer.getInt();
			for(int sensorID=0;sensorID<variableCount;sensorID++) {
				switch(sensorHeaders[sensorID].dataType) {
				case 8:
					data[sensorID] = mappedByteBuffer.getFloat(); 
					break;
				case 7:
					data[sensorID] = mappedByteBuffer.getInt();
					break;
				default:
					throw new RuntimeException("type not implemented:\t"+sensorHeaders[sensorID].dataType);
				}
				
			}
			datarows[i] = new DataRow(rowID, data);
		}
		return datarows;
	}
	
	/**
	 * Converts data rows to an array of temporal continuous data entries.
	 * @param datarows
	 * @return
	 */
	public float[][] consolidateDataRows(DataRow[] datarows) {
		
		final int MAX_VALID_ROWID = 30000;
		
		int notValidRowIdCount = 0;
		
		float[] NANrow = new float[variableCount];
		for(int i=0;i<variableCount;i++) {
			NANrow[i] = Float.NaN;
		}
		
		int maxRowID = -1;
		
		for(int i=0;i<datarows.length;i++) {
			int id = datarows[i].id;
			if(id>=0&&id<=MAX_VALID_ROWID) {
				if(maxRowID<id) {
					maxRowID = id; 
				}
			} else {
				notValidRowIdCount++;
			}
		}
		
		/*if(datarows[datarows.length-1].id<maxRowID) {
			log.warn("last id lower than maxID:"+datarows[datarows.length-1].id+"\t"+maxRowID);
		}*/
		
		if(notValidRowIdCount>0) {
			log.warn("some not valid ids (count="+notValidRowIdCount+") in "+filename);
		
		}
		
		float[][] data = new float[maxRowID+1][];
		
		for(int i=0;i<maxRowID+1;i++) {
			data[i] = NANrow;
		}
		
		int multipleEntryCount = 0;
		
		for(int i=0;i<datarows.length;i++) {
			int id = datarows[i].id;
			if(id>=0&&id<=MAX_VALID_ROWID) {
				if( data[id]!= null) {
					multipleEntryCount++;
				}
				data[id] = datarows[i].data;
			}
		}
		
		if(multipleEntryCount>0) {
			log.info("multiple entries (count="+multipleEntryCount+") in "+filename);
		}
		
		return data;
		
	}
	
	/**
	 * Converts file content to SensorData.
	 * @return
	 */
	public SensorData getConsolidatedSensorData() {
		DataRow[] datarows = readDataRows();
		if(datarows==null) {
			return null;
		}
		float[][] data = consolidateDataRows(datarows);
		if(data==null) {
			return null;
		}
		return new SensorData(timeConverter,sensorHeaders,data,badRowCount);
	}	
	
	/**
	 * prints header info of sensors.
	 */
	public void printSensorHeaders() {
		for(SensorHeader sensorHeader:sensorHeaders) {
			sensorHeader.printHeader();
		}
	}
	
	/**
	 * Gets an array of sensor header info.
	 * @return
	 */
	public SensorHeader[] getSensorHeaders() {
		return sensorHeaders;
	}
	
	/**
	 * Gets a converter object to calculate time stamps of this file.
	 * @return
	 */
	public TimeConverter getTimeConverter() {
		return timeConverter;
	}
	
	/**
	 * Writes the raw list of row id's to text file.
	 * @param datarows
	 * @param filename
	 */
	public void idListToFile(DataRow[] datarows, String filename) {
		try {
			Path path = Paths.get(filename);
			Path name = path.getName(path.getNameCount()-1);
			PrintStream printStream = new PrintStream("K:/csv/"+name+".txt");
			for(int i=0;i<datarows.length;i++) { 
				printStream.println(datarows[i].id);
			}
			printStream.close();
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		}
	}
	
	

}
