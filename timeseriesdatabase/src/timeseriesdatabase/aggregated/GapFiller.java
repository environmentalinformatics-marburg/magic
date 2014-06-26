package timeseriesdatabase.aggregated;

import java.util.ArrayList;
import java.util.List;

import org.apache.commons.math3.stat.regression.OLSMultipleLinearRegression;
import org.apache.logging.log4j.Logger;

import timeseriesdatabase.TimeConverter;
import util.Util;

/**
 * GabFiller interpolates missing values (NaN-values) in time series with data of a set of other time series
 * @author woellauer
 *
 */
public class GapFiller {

	private static final Logger log = Util.log;

	/**
	 * count of values for training to fill one gap
	 */
	public static final int TRAINING_VALUE_COUNT = 4*7*24; // four weeks with one hour time interval

	/**
	 * process gap filling of one target time series
	 * @param sourceStartTimestamp start time stamp of inputSource
	 * @param inputSource array of time series for interpolation training
	 * @param targetStartTimestamp start time stamp of target
	 * @param target target time series for interpolation
	 * @param timeStep for all time series time difference between data values
	 */
	public static void process(long sourceStartTimestamp, float[][] inputSource, long targetStartTimestamp, float[] target, int timeStep) {

		int interpolatedgapCount = 0;

		if((targetStartTimestamp-sourceStartTimestamp)%timeStep!=0) {
			log.error("wrong alignment between sourceStartTimestamp and targetStartTimestamp "+sourceStartTimestamp+"\t"+targetStartTimestamp+"\t"+timeStep);
		}


		target_gap_check_loop: for(int targetIndex=0;targetIndex<target.length;targetIndex++) {

			if(Float.isNaN(target[targetIndex])) { // gap in target time series
				
				float[][] source = new float[inputSource.length][];
				for(int i=0;i<inputSource.length;i++) {
					source[i] = inputSource[i];
				}

				int sourceGapPositionIndex = (int) (((targetStartTimestamp-sourceStartTimestamp)/timeStep)+targetIndex);	
				int sourceTrainingStartIndex = sourceGapPositionIndex-TRAINING_VALUE_COUNT;
				int targetTrainingStartIndex = targetIndex-TRAINING_VALUE_COUNT;

				if(source[0].length<sourceTrainingStartIndex+TRAINING_VALUE_COUNT) {
					return;
				}

				//System.out.println("gap: "+i+" sourceTrainingStartIndex: "+sourceTrainingStartIndex+"\t targetTrainingStartIndex: "+targetTrainingStartIndex);

				if(sourceTrainingStartIndex>=0 && targetTrainingStartIndex>=0) {
					//boolean vaildData = true;
					boolean[] validData = new boolean[source.length];
					double[][] trainingSource = new double[TRAINING_VALUE_COUNT][source.length];
					station_loop:for(int stationIndex=0;stationIndex<source.length;stationIndex++) {
						validData[stationIndex] = true; // source time series i contains valid training data if no NaN value is found
						value_loop:for(int valueIndex=0;valueIndex<TRAINING_VALUE_COUNT;valueIndex++) {
							double value = source[stationIndex][sourceTrainingStartIndex+valueIndex];
							if(!Double.isNaN(value)) {
								trainingSource[valueIndex][stationIndex] = value;
							} else {
								validData[stationIndex] = false;
								break value_loop;
							}
						}
					}
					double[] trainingTarget = new double[TRAINING_VALUE_COUNT];
					tagret_value_loop:for(int valueIndex=0;valueIndex<TRAINING_VALUE_COUNT;valueIndex++) {
						double value = target[targetTrainingStartIndex+valueIndex];
						if(!Double.isNaN(value)) {
							trainingTarget[valueIndex] = value;
						} else {
							validData = null; // interpolation no possible
							break tagret_value_loop;
						}
					}				
					if(validData!=null) {

						List<Integer> validSourceIndexList = new ArrayList<Integer>();

						for(int stationIndex=0;stationIndex<source.length;stationIndex++) {
							if(validData[stationIndex]) {
								validSourceIndexList.add(stationIndex);
							}
						}

						final int MIN_TRAINING_SOURCE_STATIONS=2;

						if(validSourceIndexList.size()<MIN_TRAINING_SOURCE_STATIONS) {
							//no interpolation possible; continue with next gap
							continue target_gap_check_loop;
							//return;
						}

						if(validSourceIndexList.size()<source.length) { //some source stations need to be excluded from training
							System.out.println("training stations: "+validSourceIndexList.size()+" of "+source.length+"\t\t"+TimeConverter.oleMinutesToLocalDateTime(targetStartTimestamp+(targetIndex*timeStep)));
							double[][] tempTrainingSource = trainingSource;
							float[][] tempSource = source;
							trainingSource = new double[tempTrainingSource.length][validSourceIndexList.size()];
							source = new float[validSourceIndexList.size()][];
							for(int validSourceIndex=0;validSourceIndex<validSourceIndexList.size();validSourceIndex++) {
								int stationIndex = validSourceIndexList.get(validSourceIndex);
								source[validSourceIndex] = tempSource[stationIndex];
								for(int valueIndex=0;valueIndex<tempTrainingSource.length;valueIndex++) {
									//System.out.println("valueIndex: "+valueIndex);
									trainingSource[valueIndex][validSourceIndex] = tempTrainingSource[valueIndex][stationIndex];
								}

							}
						}

						//System.out.println("start interpolation");

						OLSMultipleLinearRegression reg = new OLSMultipleLinearRegression();
						reg.newSampleData(trainingTarget, trainingSource);

						double[] a = reg.estimateRegressionParameters();		
						//Util.printArray(a);

						//*** fill gap ***

						double gapValue = a[0];

						for(int stationIndex=0;stationIndex<source.length;stationIndex++) {
							gapValue += source[stationIndex][sourceGapPositionIndex]*a[1+stationIndex];
						}

						//System.out.println(targetIndex+" gapValue: "+gapValue+"\t"+TimeConverter.oleMinutesToLocalDateTime(targetStartTimestamp+(targetIndex*timeStep))+ " in "+TimeConverter.oleMinutesToLocalDateTime(targetStartTimestamp)+" - "+TimeConverter.oleMinutesToLocalDateTime(targetStartTimestamp+(target.length*timeStep)));

						target[targetIndex] = (float) gapValue;
						interpolatedgapCount++;

						//***
					} else {
						//System.out.println("data not valid: "+i);
					}
				}
			}
		}

		System.out.println("interpolatedgapCount: "+interpolatedgapCount);

	}

	/**
	 * process gap filling of one target time series
	 * @param sourceBaseTimeSeries
	 * @param targetBaseTimeSeries
	 * @param parameterName the sensor name that should be gap filled
	 */
	public static void process(TimeSeries[] sourceBaseTimeSeries, TimeSeries targetBaseTimeSeries, String parameterName) {
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
