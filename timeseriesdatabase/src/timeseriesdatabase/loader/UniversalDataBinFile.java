package timeseriesdatabase.loader;

import java.io.FileInputStream;
import java.io.IOException;
import java.nio.MappedByteBuffer;
import java.nio.channels.FileChannel;
import java.nio.file.Path;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import timeseriesdatabase.TimeConverter;
import util.Util;

/**
 * UniversalDataBinFile reads, cleans and structures data of a UDBF-File.
 * @author woellauer
 *
 */
public class UniversalDataBinFile {
	
	private static final Logger log = Util.log;
	
	final int MAX_VALID_ROW_ID = 30000;
	
	private Path filename;
	private int fileSize;
	private MappedByteBuffer mappedByteBuffer;
	private FileChannel fileChannel;
	private FileInputStream fileInputStream;
	private short variableCount;
	private timeseriesdatabase.TimeConverter timeConverter;
	private int dataSectionStartFilePosition;
	private SensorHeader[] sensorHeaders;
	
	public class DataRow {
		
		public final int id;
		public final float[] data; 
		
		public DataRow(int id, float[] data) {
			this.id = id;
			this.data = data;
		}

	}
	
	public UniversalDataBinFile(Path fileName) throws IOException {
		this.filename = fileName;
		initFile();
		readHeader();
	}
	
	public void close() {
		try {
			fileChannel.close();
			fileInputStream.close();
		} catch (IOException e) {
			log.error(e);
		}
	}
	
	private void initFile() throws IOException {
		fileInputStream = new FileInputStream(filename.toString());
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
	
	public UDBFTimestampSeries getUDBFTimeSeries() {
		DataRow[] dataRows = readDataRows();
		
		int maxRowID = -1;
		
		for(int i=0;i<dataRows.length;i++) {
			int id = dataRows[i].id;
			if(id>=0&&id<=MAX_VALID_ROW_ID) {
				if(maxRowID<id) {
					maxRowID = id; 
				}
			}
		}		
		
		DataRow[] tempRows = new DataRow[maxRowID+1];
				
		int badRowCounter = 0;
		int idPos = -1;
		
		for(int r=0;r<dataRows.length;r++) {
			int id = dataRows[r].id;
			if(id>=0&&id<=MAX_VALID_ROW_ID) {
				tempRows[id] = dataRows[r];
			} else {
				badRowCounter++;
			}
		}
		
		int rowCount=0;
		int gapCount=0;
		for(int r=0;r<tempRows.length;r++) {
			if(tempRows[r]==null) {
				gapCount++;
			} else {
				rowCount++;
			}
		}
		
		long[] time = new long[rowCount];
		float[][] data = new float[rowCount][];
		for(int rowIndex=0; rowIndex<rowCount; rowIndex++) {
			data[rowIndex] = new float[sensorHeaders.length];
		}
		int dataRowIndex = 0;
		for(int tempRowsIndex=0; tempRowsIndex<tempRows.length; tempRowsIndex++) {
			if(tempRows[tempRowsIndex]!=null) {
				for(int sensorIndex=0;sensorIndex<sensorHeaders.length;sensorIndex++) {
					data[dataRowIndex][sensorIndex] = tempRows[tempRowsIndex].data[sensorIndex];
					
				}
				time[dataRowIndex] =  timeConverter.getStartTimeOleMinutes()+(tempRows[tempRowsIndex].id*timeConverter.getTimeStepMinutes());
				if(time[dataRowIndex]==58508670) {
					System.out.println("time 58508670 in "+filename);
				}
				dataRowIndex++;
			}
		}
		
		return new UDBFTimestampSeries(filename, sensorHeaders, timeConverter, time, data);
	}
}
