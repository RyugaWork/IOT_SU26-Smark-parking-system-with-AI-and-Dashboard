package model;

import java.sql.Timestamp;

public class ParkingOccupancy {

    private int occupancyId;
    private int capacity;
    private int vehiclesInside;
    private Timestamp updatedAt;

    public ParkingOccupancy() {
    }

    public ParkingOccupancy(int occupancyId,
                            int capacity,
                            int vehiclesInside,
                            Timestamp updatedAt) {

        this.occupancyId = occupancyId;
        this.capacity = capacity;
        this.vehiclesInside = vehiclesInside;
        this.updatedAt = updatedAt;
    }

    public int getOccupancyId() {
        return occupancyId;
    }

    public void setOccupancyId(int occupancyId) {
        this.occupancyId = occupancyId;
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

    public Timestamp getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(Timestamp updatedAt) {
        this.updatedAt = updatedAt;
    }

    public int getAvailableCapacity() {
        return capacity - vehiclesInside;
    }
}