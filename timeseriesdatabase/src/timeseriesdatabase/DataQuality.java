package timeseriesdatabase;

/**
 * for data values: highest passed quality check
 * for queries: lowest quality of data values
 * @author woellauer
 *
 */
public enum DataQuality { 
	Na,			//quality unknown 
	NO,			//no quality check passed 
	PHYSICAL,	//physical range check passed and step and empirical not passed
	STEP, 
	EMPIRICAL
}