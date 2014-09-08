package gui.util;

import java.beans.PropertyChangeEvent;
import java.beans.PropertyChangeListener;
import java.beans.PropertyChangeSupport;

import tsdb.remote.GeneralStationInfo;

public abstract class AbstractModel {
	
	@FunctionalInterface
	public interface CallBack<T>{
		public void call(T v);
	}
	
	@FunctionalInterface
	public interface Notify {
		public void call();
	}
	
	public PropertyChangeSupport changeSupport = new PropertyChangeSupport(this);
	
	public void addPropertyChangeListener(String propertyName, PropertyChangeListener listener) {
		changeSupport.addPropertyChangeListener(propertyName, listener);
	}
	
	public void removePropertyChangeListener(String propertyName, PropertyChangeListener listener) {
		changeSupport.removePropertyChangeListener(propertyName, listener);
	}
	
	public <T> void addPropertyChangeCallback(String propertyName, CallBack<T> changeCallBack) {
		addPropertyChangeListener(propertyName,  event -> changeCallBack.call((T)event.getNewValue()));
	}
	
	public void addPropertyChangeNotify(String propertyName, Notify notify) {
		addPropertyChangeListener(propertyName,  event -> notify.call());
	}
	
	/*public void fireRefresh(String propertyName) {
		PropertyChangeListener[] listeners = changeSupport.getPropertyChangeListeners(propertyName);
		for(PropertyChangeListener listener:listeners) {
			PropertyChangeEvent evt = new PropertyChangeEvent(this, propertyName, oldValue, newValue);
			listener.propertyChange(evt);
		}
	}*/
}