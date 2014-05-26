package dat_decode;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.Arrays;

/**
 * Data entries of one sensor with title, unit and time.
 * @author Wöllauer
 *
 */
public class Sensor {
	
	TimeConverter timeConverter;
	SensorHeader metaData;
	double[] data;
	
	public Sensor(TimeConverter timeConverter, SensorHeader metaData,double[] data) {
		this.timeConverter = timeConverter;
		this.metaData = metaData;
		this.data = data;
	}
	
	public void print(int n) {
		System.out.print("sensor: "+metaData.getName()+"\tunit: "+metaData.getUnit()+" ("+data.length+" entries) @"+timeConverter.getStartDateTime()+" :  ");
		if(data.length<n) {
			n = data.length;
		}
		for(int i=0;i<n;i++) {
			System.out.format("%.2f  ",data[i]);
		}
		System.out.println();
	}
	
	public LocalDateTime getFirstDateTime() {
		return timeConverter.getStartDateTime();
	}
	
	public LocalDateTime getLastDateTime() {
		return timeConverter.offsetToDateTime(data.length-1);
	}
	
	public String getSensorName() {
		return metaData.name;
	}
	
	public String getSensorUnit() {
		return metaData.unit;
	}
	
	public double[] getData() {
		return data;
	}
	
	public Duration getTimeStep() {
		return timeConverter.getTimeStep();
	}
	
	public double getMin() {
		double min = Double.MAX_VALUE;
		for(double x:data) {
			if(x<min) {
				min = x;
			}
		}
		return min;
	}
	
	public double getMax() {
		double max = -Double.MAX_VALUE;
		for(double x:data) {
			if(x>max) {
				max = x;
			}
		}
		return max;
	}
	
	public double getAverage() {
		double sum = 0;
		for(double x:data) {
			sum += x;
		}
		return sum/data.length;
	}
	
	public int getSampleCount() {
		return data.length;
	}
	
	public double getStdDev() {		
		double sum = 0;
		double qsum = 0;
		for(double x:data) {
			sum += x;
			qsum += x*x;
		}
		return Math.sqrt((1d/(data.length-1d))*(qsum-(1d/data.length)*(sum*sum)));
	}
	
	public double getMean() {
		double[] temp = Arrays.copyOf(data,data.length);
		Arrays.sort(temp);
		if(data.length%2==0) {
			return (temp[data.length/2]+temp[data.length/2+1])/2;
		} else {
			return temp[(data.length+1)/2];
		}	
	}
	

}
