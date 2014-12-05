package tsdb.util.gui;

import tsdb.TimeConverter;
import tsdb.raw.TimestampSeries;
import tsdb.raw.TsEntry;

public class TimeSeriesHeatMap {

	private final TimestampSeries ts;

	public TimeSeriesHeatMap(TimestampSeries ts) {
		this.ts = ts;
		/*if(ts.timeinterval!=60) {
			throw new RuntimeException("TimeSeriesHeatMap needs one hour time steps: "+ts.timeinterval);
		}*/
	}

	public void draw(TimeSeriesPainter tsp, String sensorName) {
		setRange(tsp,sensorName);
		tsp.setColorRectWater();
		long start = ts.entryList.get(0).timestamp-ts.entryList.get(0).timestamp%(60*24);
		for(TsEntry entry:ts.entryList) {
			float value = entry.data[0];
			if(!Float.isNaN(value)) {
				tsp.setIndexedColor(value);
				float x = (((entry.timestamp-start)/60)/24)*1;
				float y = (((entry.timestamp-start)/60)%24)*1;
				tsp.drawLine(x, y, x, y);
				//tsp.fillRect(x, y, x+4, y+4);
			}
		}
	}
	
	private static void setRange(TimeSeriesPainter tsp,String sensorName) {
		switch(sensorName) {
		case "Ta_200":
		case "Ta_10":
		case "Ts_5":
		case "Ts_10":
		case "Ts_20":
		case "Ts_50":
		case "Tsky":
		case "Tgnd":
		case "Trad":
			//tsp.setIndexedColorRange(-10, 30);
			tsp.setIndexedColorRange(-20, 45);
			break;
		case "Albedo":
			tsp.setIndexedColorRange(0.1f, 0.3f);
			break;
		case "rH_200":
			tsp.setIndexedColorRange(0, 100);
			break;
		case "SM_10":
		case "SM_15":
		case "SM_20":
		case "SM_30":
		case "SM_40":
		case "SM_50":
			tsp.setIndexedColorRange(20, 55);
			break;
		case "B_01":
		case "B_02":
		case "B_03":
		case "B_04":
		case "B_05":
		case "B_06":
		case "B_07":
		case "B_08":
		case "B_09":
		case "B_10":
		case "B_11":
		case "B_12":
		case "B_13":
		case "B_14":
		case "B_15":
		case "B_16":
		case "B_17":
		case "B_18":
		case "B_19":
		case "B_20":
		case "B_21":
		case "B_22":
		case "B_23":
		case "B_24":
		case "B_25":
		case "B_26":
		case "B_27":
		case "B_28":
		case "B_29":
		case "B_30":
		case "Rainfall":
			tsp.setIndexedColorRange(0, 3);
			break;
		case "Fog":
			tsp.setIndexedColorRange(0, 0.3f);
			break;
		case "SWDR_300":
			tsp.setIndexedColorRange(0, 1000);
			break;
		case "SWUR_300":
			tsp.setIndexedColorRange(0, 200);
			break;
		case "LWDR_300":
			tsp.setIndexedColorRange(250, 450);
			break;
		case "LWUR_300":
			tsp.setIndexedColorRange(300, 520);
			break;
		case "PAR_200": //no data
		case "PAR_300":
			tsp.setIndexedColorRange(0, 2000);
			break;
		case "P_RT_NRT":
			tsp.setIndexedColorRange(0, 0.2f);
			break;
		case "P_container_RT":
		case "P_container_NRT":
			tsp.setIndexedColorRange(0, 600);
			break;
		case "Rn_300":
			tsp.setIndexedColorRange(-70, 700);
			break;
		case "WD": //no data
			tsp.setIndexedColorRange(0, 360);
			break;
		case "WV":
			tsp.setIndexedColorRange(0, 9);
			break;
		case "WV_gust":
			tsp.setIndexedColorRange(0, 20);
			break;						
		case "p_QNH":
			tsp.setIndexedColorRange(980, 1040);
			break;
		case "P_RT_NRT_01": //few data?
		case "P_RT_NRT_02": //few data?
		case "F_RT_NRT_01": //few data?
		case "F_RT_NRT_02": //few data?
		case "T_RT_NRT_01": //few data?
		case "T_RT_NRT_02": //few data?
			tsp.setIndexedColorRange(0, 2);
			break;
		case "swdr_01": //range?
			tsp.setIndexedColorRange(0, 1200);
			break;
		case "swdr_02": //range?
			tsp.setIndexedColorRange(0, 30);
			break;

		case "par_01": //few data?
		case "par_02": //few data?
		case "p_200": // not in schema?
		case "T_CNR": // not in schema?						
		default:
			tsp.setIndexedColorRange(-10, 30);
		}		
	}

}
