package timeseriesdatabase;

/**
 * for data values: highest passed quality check
 * for queries: lowest quality of data values
 * @author woellauer
 *
 */
public enum DataQuality { 
	Na,			//quality unknown    for query: no check, no flag creation
	NO,			//no quality check passed    for query: no check, but flag creation
	PHYSICAL,	//physical range check passed and step and empirical not passed
	STEP,       //physical range check and step passed and empirical not passed
	EMPIRICAL   //physical range check and step and empirical passed
}