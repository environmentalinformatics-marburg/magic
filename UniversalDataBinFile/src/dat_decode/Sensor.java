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
	float[] data;
	
	public Sensor(TimeConverter timeConverter, SensorHeader metaData, float[] data) {
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
	
	public double getStartOleAutomatonTime() {
		return timeConverter.getStartOleAutomatonTime();
	}
	
	public LocalDateTime getFirstDateTime() {
		return timeConverter.getStartDateTime();
	}
	
	public long getFirstEntryTimeOleMinutes() {
		return timeConverter.getStartTimeOleMinutes();
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
	
	public float[] getData() {
		return data;
	}
	
	public Duration getTimeStep() {
		return timeConverter.getTimeStep();
	}
	
	public long getTimeStepMinutes() {
		return timeConverter.getTimeStepMinutes();
	}
	
	public float getMin() {
		float min = Float.MAX_VALUE;
		for(float x:data) {
			if(!Float.isNaN(x)&&x<min) {
				min = x;
			}
		}
		return min;
	}
	
	public float getMax() {
		float max = -Float.MAX_VALUE;
		for(float x:data) {
			if(!Float.isNaN(x)&&x>max) {
				max = x;
			}
		}
		return max;
	}
	
	public float getAverage() {
		int count = 0;
		float sum = 0;
		for(float x:data) {
			if(!Float.isNaN(x)) {
				sum += x;
				count++;
			}
		}
		return sum/count;
	}
	
	public int getSampleCount() {
		return data.length;
	}
	
	public float getStdDev() {		
		float sum = 0;
		float qsum = 0;
		int count = 0;
		for(float x:data) {
			if(!Float.isNaN(x)) {
			sum += x;
			qsum += x*x;
			count++;
			}
		}
		return (float) Math.sqrt((1d/(count-1d))*(qsum-(1d/count)*(sum*sum)));
	}
	
	public float getMean() {
		int count = 0;
	
		for(float x:data) {
			if(!Float.isNaN(x)) {
				count++;
			}
		}
		
		float[] temp = new float[count];
		
		int c = 0;
		for(float x:data) {
			if(!Float.isNaN(x)) {
				temp[c] = x;
				c++;
			}
		}
		
		Arrays.sort(temp);
		if(data.length%2==0) {
			return (temp[data.length/2]+temp[data.length/2+1])/2;
		} else {
			return temp[(data.length+1)/2];
		}	
	}
	

}
