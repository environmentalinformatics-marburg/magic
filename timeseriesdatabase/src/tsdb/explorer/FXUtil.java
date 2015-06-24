package tsdb.explorer;

import javafx.event.EventHandler;
import javafx.scene.control.TableCell;
import javafx.scene.control.TableColumn;
import javafx.scene.input.MouseEvent;
import javafx.util.Callback;

public final class FXUtil {
	
	private FXUtil(){}
	
	@SuppressWarnings("unchecked")
	public static <S,T> Callback<TableColumn<S,T>, TableCell<S,T>> cellFactoryWithOnClicked(EventHandler<? super MouseEvent> cb) {
		return col -> {
			TableCell<S,T> cell = (TableCell<S,T>) TableColumn.DEFAULT_CELL_FACTORY.call(col);
			cell.setOnMouseClicked(cb);
			Class<FXUtil> x = FXUtil.class;
			return cell;
		};
	}

}
