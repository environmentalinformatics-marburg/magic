package dat_decode;

import java.io.IOException;

/**
 * Use case to use data of one sensor.
 * @author Wöllauer
 *
 */
public class UseCase2 {

	public static void main(String[] args) throws IOException {
		//final String FILENAME = "K:/20080516_^b0_0002.dat";
		//final String FILENAME = "K:/20130117_^b0_0016.dat";
		final String FILENAME = "K:/HG12/20080509_^b0_0001.dat";
		UniversalDataBinFile udbf = new UniversalDataBinFile(FILENAME);
		SensorData sensorData = udbf.getSensorData();
		
		Sensor sensor = sensorData.getSensor(3);
		
		System.out.println("----------------------");
		System.out.println("sensor name:\t"+sensor.getSensorName());
		System.out.println("sensor unit:\t"+sensor.getSensorUnit());
		System.out.println("sample count:\t"+sensor.getSampleCount());
		System.out.println("first entry:\t"+sensor.getFirstDateTime());
		System.out.println("last entry:\t"+sensor.getLastDateTime());
		System.out.println("time step:\t"+sensor.getTimeStep());		
		System.out.println("data: ");
		DataUtil.printArray(sensor.getData());
		System.out.println("----------------------");
		System.out.format("min: %.2f\n",sensor.getMin());
		System.out.format("max: %.2f\n",sensor.getMax());
		System.out.format("average: %.2f\n",sensor.getAverage());
		System.out.format("stddev: %.2f\n",sensor.getStdDev());
		System.out.format("mean: %.2f\n",sensor.getMean());
	}

}
