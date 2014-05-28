package dat_decode;

import java.io.IOException;

public class UseCaseWriteTable {
	
	public static void main(String[] args) throws IOException {
		String basePath = "K:/incoming_ftp/adl-m/HEG/";
		String filename = "HG50/20100608_^b1_0006.dat";
		UniversalDataBinFile udbf = new UniversalDataBinFile(basePath+filename);
		SensorData sensorData = udbf.getSensorData();
		sensorData.writeTable("k:/csv/data1.data");
	}

}
