package timeseriesdatabase;

import javax.naming.ldap.SortControl;

import org.apache.commons.math3.stat.regression.OLSMultipleLinearRegression;
import org.apache.logging.log4j.Logger;

import util.Util;

public class GapFiller {
	
	private static final Logger log = Util.log;
	
	public static final int TRAINING_VALUE_COUNT = 4*7*24; // four weeks with one hour time interval
	
	public static void process(long sourceStartTimestamp, float[][] source, long targetStartTimestamp, float[] target, int timeinterval) {
		
		int interpolatedgapCount = 0;
		
		if((targetStartTimestamp-sourceStartTimestamp)%timeinterval!=0) {
			log.error("wrong alignment between sourceStartTimestamp and targetStartTimestamp "+sourceStartTimestamp+"\t"+targetStartTimestamp+"\t"+timeinterval);
		}
		
		
		for(int i=0;i<target.length;i++) {
			
			if(Float.isNaN(target[i])) {
			
			int sourceGapPositionIndex = (int) (((targetStartTimestamp-sourceStartTimestamp)/timeinterval)+i);	
			int sourceTrainingStartIndex = sourceGapPositionIndex-TRAINING_VALUE_COUNT;
			int targetTrainingStartIndex = i-TRAINING_VALUE_COUNT;
			
			if(source[0].length<sourceTrainingStartIndex+TRAINING_VALUE_COUNT) {
				return;
			}
			
			//System.out.println("gap: "+i+" sourceTrainingStartIndex: "+sourceTrainingStartIndex+"\t targetTrainingStartIndex: "+targetTrainingStartIndex);

			if(sourceTrainingStartIndex>=0 && targetTrainingStartIndex>=0) {
				boolean vaildData = true;
				double[][] trainingSource = new double[TRAINING_VALUE_COUNT][source.length];
				loop:for(int stationIndex=0;stationIndex<source.length;stationIndex++) {
					for(int valueIndex=0;valueIndex<TRAINING_VALUE_COUNT;valueIndex++) {
						double value = source[stationIndex][sourceTrainingStartIndex+valueIndex];
						if(!Double.isNaN(value)) {
							trainingSource[valueIndex][stationIndex] = value;
						} else {
							vaildData = false;
							break loop;
						}
					}
				}
				double[] trainingTarget = new double[TRAINING_VALUE_COUNT];
				for(int valueIndex=0;valueIndex<TRAINING_VALUE_COUNT;valueIndex++) {
					double value = target[targetTrainingStartIndex+valueIndex];
					if(!Double.isNaN(value)) {
						trainingTarget[valueIndex] = value;
					} else {
						vaildData = false;
						break;
					}
				}				
				if(vaildData) {
					System.out.println("start interpolation");
					
					
					OLSMultipleLinearRegression reg = new OLSMultipleLinearRegression();
					reg.newSampleData(trainingTarget, trainingSource);
					
					double[] a = reg.estimateRegressionParameters();		
					Util.printArray(a);
					
					//*** fill gap ***
					
					double gapValue = a[0];
					
					for(int stationIndex=0;stationIndex<source.length;stationIndex++) {
						gapValue += source[stationIndex][sourceGapPositionIndex]*a[1+stationIndex];
					}
					
					System.out.println(i+" gapValue: "+gapValue+"\t"+TimeConverter.oleMinutesToLocalDateTime(targetStartTimestamp+i));
					
					target[i] = (float) gapValue;
					interpolatedgapCount++;
					
					//***
					
					
					
				} else {
					//System.out.println("data not valid");
				}
			}
			
			
				
			}
		}
		
		System.out.println("interpolatedgapCount: "+interpolatedgapCount);
		
	}
	
	public static void process(BaseTimeSeries[] sourceBaseTimeSeries, BaseTimeSeries targetBaseTimeSeries, String parameterName) {
		final int timeStep = targetBaseTimeSeries.timeStep;
		long sourceStartTimestamp = sourceBaseTimeSeries[0].startTimestamp;
		float[][] source = new float[sourceBaseTimeSeries.length][];
		for(int i=0;i<sourceBaseTimeSeries.length;i++) {
			if(sourceStartTimestamp!=sourceBaseTimeSeries[i].startTimestamp) {
				log.error("all sources need to have same startTimestamp");
				return;
			}
			if(timeStep!=sourceBaseTimeSeries[i].timeStep) {
				log.error("all sources need to have same time step");
				return;
			}
			source[i] = sourceBaseTimeSeries[i].getValues(parameterName);
		}
		long targetStartTimestamp = targetBaseTimeSeries.startTimestamp;
		float[] target = targetBaseTimeSeries.getValues(parameterName);
		
		process(sourceStartTimestamp, source, targetStartTimestamp, target, timeStep);
	}
	
	
	
	
	
	

}
