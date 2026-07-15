package model;

import java.sql.Timestamp;

public class DashboardOverview {

    private int capacity;
    private int vehiclesInside;
    private int availableCapacity;
    private int entriesToday;
    private int exitsToday;
    private String entryGateState;
    private String exitGateState;
    private Timestamp updatedAt;

    public DashboardOverview() {
    }

    public DashboardOverview(int capacity,
                             int vehiclesInside,
                             int availableCapacity,
                             int entriesToday,
                             int exitsToday,
                             String entryGateState,
                             String exitGateState,
                             Timestamp updatedAt) {

        this.capacity = capacity;
        this.vehiclesInside = vehiclesInside;
        this.availableCapacity = availableCapacity;
        this.entriesToday = entriesToday;
        this.exitsToday = exitsToday;
        this.entryGateState = entryGateState;
        this.exitGateState = exitGateState;
        this.updatedAt = updatedAt;
    }

    public int getCapacity() {
        return capacity;
    }

    public void setCapacity(int capacity) {
        this.capacity = capacity;
    }

    public int getVehiclesInside() {
        return vehiclesInside;
    }

    public void setVehiclesInside(int vehiclesInside) {
        this.vehiclesInside = vehiclesInside;
    }

    public int getAvailableCapacity() {
        return availableCapacity;
    }

    public void setAvailableCapacity(int availableCapacity) {
        this.availableCapacity = availableCapacity;
    }

    public int getEntriesToday() {
        return entriesToday;
    }

    public void setEntriesToday(int entriesToday) {
        this.entriesToday = entriesToday;
    }

    public int getExitsToday() {
        return exitsToday;
    }

    public void setExitsToday(int exitsToday) {
        this.exitsToday = exitsToday;
    }

    public String getEntryGateState() {
        return entryGateState;
    }

    public void setEntryGateState(String entryGateState) {
        this.entryGateState = entryGateState;
    }

    public String getExitGateState() {
        return exitGateState;
    }

    public void setExitGateState(String exitGateState) {
        this.exitGateState = exitGateState;
    }

    public Timestamp getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(Timestamp updatedAt) {
        this.updatedAt = updatedAt;
    }
}