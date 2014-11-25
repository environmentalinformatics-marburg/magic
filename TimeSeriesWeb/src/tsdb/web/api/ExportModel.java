package tsdb.web.api;

import tsdb.DataQuality;
import tsdb.Region;
import tsdb.aggregated.AggregationInterval;

public class ExportModel{

	public String[] plots;
	public String[] sensors;
	public boolean interpolate;
	public boolean desc_sensor;
	public boolean desc_plot;
	public boolean desc_settings;
	public boolean allinone;
	public AggregationInterval aggregationInterval;
	public DataQuality quality;
	public Region region;
	public boolean col_plotid;
	public boolean col_timestamp;
	public boolean col_datetime;
	public boolean write_header;
	public int timespan;

	public ExportModel() {
		this.plots = new String[]{"plot1","plot2","plot3"};
		this.sensors = new String[]{"sensor1","sensor2","sensor3","sensor4"};
		this.interpolate = false;
		this.desc_sensor = true;
		this.desc_plot = true;
		this.desc_settings = true;
		this.allinone = false;
		this.aggregationInterval = AggregationInterval.DAY;
		this.quality = DataQuality.STEP;
		this.region = null;
		this.col_plotid = true;
		this.col_timestamp = true;
		this.col_datetime = true;
		this.write_header = true;
		this.timespan = 0; // all
	}
}