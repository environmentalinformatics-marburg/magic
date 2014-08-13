package timeseriesdatabase.catalog;

import java.io.File;
import java.util.Collection;
import java.util.List;
import java.util.NavigableSet;
import java.util.Set;
import java.util.TreeSet;
import java.util.stream.Collector;
import java.util.stream.Collectors;

import org.mapdb.BTreeMap;
import org.mapdb.Bind;
import org.mapdb.Bind.MapWithModificationListener;
import org.mapdb.DB;
import org.mapdb.DBMaker;
import org.mapdb.Fun;
import org.mapdb.Fun.Function2;
import org.mapdb.Fun.Tuple2;

public class SourceCatalog {

	private static final String DB_FILENAME_PREFIX = "SourceCatalog";
	private static final String DB_NAME_SOURCE_CATALOG = "SourceCatalog";

	private DB db;
	private BTreeMap<String, SourceEntry> catalogMap;

	public SourceCatalog(String databasePath) {
		this.db = DBMaker.newFileDB(new File(databasePath+DB_FILENAME_PREFIX))
				         .closeOnJvmShutdown()
				         .make();

		if(db.getAll().containsKey(DB_NAME_SOURCE_CATALOG)) {
			System.out.println("open existing SourceCatalog");
			this.catalogMap = db.getTreeMap(DB_NAME_SOURCE_CATALOG);
		} else {
			System.out.println("create new SourceCatalog");
			this.catalogMap =  db.createTreeMap(DB_NAME_SOURCE_CATALOG).makeStringMap();
		}
	}

	public void clear() {
		catalogMap.clear();
	}

	public void insert(SourceEntry sourceEntry) {
		catalogMap.put(sourceEntry.filename.toString(), sourceEntry);
	}

	public Collection<SourceEntry> getEntries() {
		return catalogMap.values();
	}

	public List<SourceEntry> getEntriesWithStationName(String stationName) {		
		return getEntries().stream().filter((SourceEntry x)->x.stationName.equals(stationName)).collect(Collectors.toList());		
	}
	
	public void close() {
		db.commit();
		db.close();
	}

}
