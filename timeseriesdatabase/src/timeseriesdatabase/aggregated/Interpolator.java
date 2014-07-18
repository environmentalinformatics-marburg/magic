package timeseriesdatabase.aggregated;

import java.util.ArrayList;
import java.util.List;

import org.apache.commons.math3.linear.SingularMatrixException;
import org.apache.commons.math3.stat.regression.OLSMultipleLinearRegression;
import org.apache.logging.log4j.Logger;

import timeseriesdatabase.TimeConverter;
import util.Util;

/**
 * GabFiller interpolates missing values (NaN-values) in time series with data of a set of other time series
 * @author woellauer
 *
 */
public class Interpolator {

	private static final Logger log = Util.log;

	/**
	 * count of values for training to fill one gap
	 */
	public static final int TRAINING_VALUE_COUNT = 4*7*24; // four weeks with one hour time interval
	
	/**
	 * maximum count of previous interpolated values in target training values
	 */
	//public static final int MAX_INTERPOLATED_IN_TRAINING_COUNT = 7*24;
	public static final int MAX_INTERPOLATED_IN_TRAINING_COUNT = TRAINING_VALUE_COUNT; //!! TODO
	
	/**
	 * minimum of different sources to interpolate from
	 */
	public static final int MIN_TRAINING_SOURCES = 2;

	/**
	 * Creates an array with size of TRAINING_VALUE_COUNT and checks count of previous interpolated data values
	 * @param gapPos
	 * @param data
	 * @param targetInterpolationFlags
	 * @return
	 */
	private static double[] createTargetTrainingArray(int gapPos, float[] data, boolean[] targetInterpolationFlags) {
		double[] result = new double[TRAINING_VALUE_COUNT];
		int startPos = gapPos-TRAINING_VALUE_COUNT;
		int interpolatedCounter = 0;
		for(int i=startPos;i<gapPos;i++) {
			if(Float.isNaN(data[i])) {
				return null;
			} else {
				if(targetInterpolationFlags[i]) {
					interpolatedCounter++;
					if(interpolatedCounter>MAX_INTERPOLATED_IN_TRAINING_COUNT) { // to much interpolated values in target
						return null;
					}
				}				
				result[i-startPos] = data[i];
			}
		}
		return result;
	}

	/**
	 * Creates an array with size of TRAINING_VALUE_COUNT + 1 of training data plus values for interpolation value calculation.
	 * @param gapPos
	 * @param data
	 * @return
	 */
	private static double[] createSourceTrainingArray(int gapPos, float[] data) {
		double[] result = new double[TRAINING_VALUE_COUNT+1];
		int startPos = gapPos-TRAINING_VALUE_COUNT;		
		for(int i=startPos;i<=gapPos;i++) {
			if(Float.isNaN(data[i])) {
				return null;
			} else {
				result[i-startPos] = data[i];
			}
		}
		return result;
	}

	/**
	 * Creates a matrix of all training arrays as input for OLSMultipleLinearRegression.
	 * @param trainingSourceList
	 * @return
	 */
	private static double[][] createTrainingMatrix(List<double[]> trainingSourceList) {		
		double[][] trainingMatrix = new double[TRAINING_VALUE_COUNT][trainingSourceList.size()];

		for(int sourceNr=0; sourceNr<trainingSourceList.size();sourceNr++) {
			double[] source = trainingSourceList.get(sourceNr);
			for(int rowNr=0;rowNr<TRAINING_VALUE_COUNT;rowNr++) {
				trainingMatrix[rowNr][sourceNr] = source[rowNr];
			}
		}		

		return trainingMatrix;
	}


	/**
	 * Tries to interpolate all nan-Values in target and sets for interpolated values flags in targetInterpolationFlags.
	 * @param inputSource
	 * @param target
	 * @param targetInterpolationFlags
	 * @return
	 */
	private static int processNew(float[][] inputSource, float[] target, boolean[] targetInterpolationFlags) {
		int interpolatedgapCount = 0;
		for(int gapPos=TRAINING_VALUE_COUNT;gapPos<target.length;gapPos++) {
			if(Float.isNaN(target[gapPos])) { // gap found at gapPos
				double[] trainingTarget = createTargetTrainingArray(gapPos,target, targetInterpolationFlags);
				if(trainingTarget!= null) { // valid training target
					ArrayList<double[]> trainingSourceList = new ArrayList<double[]>(inputSource.length);
					for(int sourceNr=0;sourceNr<inputSource.length;sourceNr++) {
						double[] trainingSource = createSourceTrainingArray(gapPos, inputSource[sourceNr]);
						if(trainingSource!=null) {
							trainingSourceList.add(trainingSource);
						}
					}
					if(trainingSourceList.size()>=MIN_TRAINING_SOURCES) { // enough training sources
						try {
							double[][] trainingMatrix = createTrainingMatrix(trainingSourceList);
							OLSMultipleLinearRegression olsMultipleLinearRegression = new OLSMultipleLinearRegression();
							olsMultipleLinearRegression.newSampleData(trainingTarget, trainingMatrix);
							double[] regressionParameters = olsMultipleLinearRegression.estimateRegressionParameters();
							//*** fill gap
							double gapValue = regressionParameters[0];
							for(int sourceIndex=0; sourceIndex<trainingSourceList.size(); sourceIndex++) {							
								gapValue += trainingSourceList.get(sourceIndex)[TRAINING_VALUE_COUNT]*regressionParameters[sourceIndex+1];							
							}
							target[gapPos] = (float) gapValue;
							targetInterpolationFlags[gapPos] = true;						
							interpolatedgapCount++;
							//***
						} catch(SingularMatrixException e) {
							log.warn("interpolation not possible: "+e.toString()+" at "+gapPos);
						}
					}
				}
			}
		}
		return interpolatedgapCount;
	}



	/**
	 * process gap filling of one target time series
	 * @param sourceStartTimestamp start time stamp of inputSource
	 * @param inputSource array of time series for interpolation training
	 * @param targetStartTimestamp start time stamp of target
	 * @param target target time series for interpolation
	 * @param targetInterpolationFlags 
	 * @param timeStep for all time series time difference between data values
	 */
	/*private static void process(long sourceStartTimestamp, float[][] inputSource, long targetStartTimestamp, float[] target, boolean[] targetInterpolationFlags, int timeStep) {

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

						double[] a;

						try {
							a = reg.estimateRegressionParameters();
						} catch(Exception e) {
							log.warn("interpolation error: "+e);
							//no interpolation possible; continue with next gap
							continue target_gap_check_loop;
						}
						//Util.printArray(a);

						//*** fill gap ***

						double gapValue = a[0];

						for(int stationIndex=0;stationIndex<source.length;stationIndex++) {
							gapValue += source[stationIndex][sourceGapPositionIndex]*a[1+stationIndex];
						}

						//System.out.println(targetIndex+" gapValue: "+gapValue+"\t"+TimeConverter.oleMinutesToLocalDateTime(targetStartTimestamp+(targetIndex*timeStep))+ " in "+TimeConverter.oleMinutesToLocalDateTime(targetStartTimestamp)+" - "+TimeConverter.oleMinutesToLocalDateTime(targetStartTimestamp+(target.length*timeStep)));

						target[targetIndex] = (float) gapValue;
						targetInterpolationFlags[targetIndex] = true;
						interpolatedgapCount++;

						//***
					} else {
						//System.out.println("data not valid: "+i);
					}
				}
			}
		}

		System.out.println("interpolatedgapCount: "+interpolatedgapCount);

	}*/

	/**
	 * Process gap filling of one target time series and one parameter. Some data in source time series is allowed to be
	 * left out.
	 * @param sourceTimeSeries
	 * @param targetTimeSeries
	 * @param parameterName the sensor name that should be gap filled
	 */
	public static int process(TimeSeries[] sourceTimeSeries, TimeSeries targetTimeSeries, String parameterName) {
		final int timeStep = targetTimeSeries.timeStep;
		long startTimestamp = targetTimeSeries.getFirstTimestamp();
		long endTimestamp = targetTimeSeries.getLastTimestamp();
		float[] target = targetTimeSeries.getValues(parameterName);
		boolean[] targetInterpolationFlags = targetTimeSeries.getInterpolationFlags(parameterName);

		//float[][] source = new float[sourceTimeSeries.length][];
		ArrayList<float[]> sourceList = new ArrayList<float[]>(sourceTimeSeries.length);
		for(int i=0;i<sourceTimeSeries.length;i++) {
			if(sourceTimeSeries[i]!=null && sourceTimeSeries[i].containsParamterName(parameterName)) {
				if(startTimestamp!=sourceTimeSeries[i].getFirstTimestamp()) {
					log.error("all sources need to have same startTimestamp");
					return 0;
				}
				if(endTimestamp!=sourceTimeSeries[i].getLastTimestamp()) {
					log.error("all sources need to have same endTimestamp");
					return 0;
				}
				if(timeStep!=sourceTimeSeries[i].timeStep) {
					log.error("all sources need to have same time step");
					return 0;
				}
				sourceList.add(sourceTimeSeries[i].getValues(parameterName));
			}
		}

		//process(startTimestamp, source, startTimestamp, target, targetInterpolationFlags, timeStep);
		int interpolatedCount = processNew(sourceList.toArray(new float[0][]),target,targetInterpolationFlags);
		System.out.println("interpolated in "+parameterName+": "+interpolatedCount);
		return interpolatedCount;
	}







}
