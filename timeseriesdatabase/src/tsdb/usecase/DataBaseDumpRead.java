package tsdb.usecase;

import java.io.BufferedInputStream;
import java.io.DataInput;
import java.io.DataInputStream;
import java.io.FileInputStream;
import java.io.IOException;
import java.nio.file.Path;
import java.nio.file.Paths;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import tsdb.TsDBFactory;
import tsdb.streamdb.DataEntry;
import tsdb.streamdb.StreamDB;

public class DataBaseDumpRead {

	private static final Logger log = LogManager.getLogger();

	public static void main(String[] args) throws IOException {

		System.out.println("open streamDB...");


		StreamDB streamdb = new StreamDB(TsDBFactory.STORAGE_PATH+"/streamdb");
		try {


			Path pathToFile = Paths.get(TsDBFactory.OUTPUT_PATH+"/dump/"+"dump.tss");
			BufferedInputStream fileInputStream = new BufferedInputStream(new FileInputStream(pathToFile.toFile()));
			DataInputStream dataInput = new DataInputStream(fileInputStream);

			int time_series_stream_header_marker = dataInput.readInt();
			if(DataBaseDumpWrite.TIME_SERIES_STREAM_HEADER_MARKER!=time_series_stream_header_marker) {
				dataInput.close();
				throw new RuntimeException("unknown file");
			}

			long timeStartImport = System.currentTimeMillis();

			while(dataInput.available()>0) {
				int time_series_stream_entry_marker = dataInput.readInt();
				if(DataBaseDumpWrite.TIME_SERIES_STREAM_ENTRY_MARKER!=time_series_stream_entry_marker) {
					dataInput.close();
					throw new RuntimeException("unknown entry marker");				
				}

				final String stationName = DataInputStream.readUTF(dataInput);
				final String sensorName = DataInputStream.readUTF(dataInput);
				final int valueCount = dataInput.readInt();

				System.out.println(stationName+" "+sensorName+" "+valueCount);
				
				DataEntry[] data = new DataEntry[valueCount];
				
				for(int i=0;i<valueCount;i++) {

					int timestamp = dataInput.readInt();
					float value = dataInput.readFloat();

					data[i] = new DataEntry(timestamp, value);
				}				
				streamdb.insertSensorData(stationName, sensorName, data);
			}

			long timeEndImport = System.currentTimeMillis();

			log.info((timeEndImport-timeStartImport)/1000+" s Import");

			dataInput.close();

		} finally {

			streamdb.close();

		}











	}

}
