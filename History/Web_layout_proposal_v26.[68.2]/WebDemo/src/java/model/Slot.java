package model;

import java.sql.Timestamp;

public class Slot {

    private int slotId;
    private String slotNumber;
    private double sensorDistanceCm;
    private String status;
    private Timestamp lastSensorTime;

    public Slot() {
    }

    public Slot(int slotId, String slotNumber, double sensorDistanceCm, String status, Timestamp lastSensorTime) {
        this.slotId = slotId;
        this.slotNumber = slotNumber;
        this.sensorDistanceCm = sensorDistanceCm;
        this.status = status;
        this.lastSensorTime = lastSensorTime;
    }

    public int getSlotId() {
        return slotId;
    }

    public void setSlotId(int slotId) {
        this.slotId = slotId;
    }

    public String getSlotNumber() {
        return slotNumber;
    }

    public void setSlotNumber(String slotNumber) {
        this.slotNumber = slotNumber;
    }

    public double getSensorDistanceCm() {
        return sensorDistanceCm;
    }

    public void setSensorDistanceCm(double sensorDistanceCm) {
        this.sensorDistanceCm = sensorDistanceCm;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public Timestamp getLastSensorTime() {
        return lastSensorTime;
    }

    public void setLastSensorTime(Timestamp lastSensorTime) {
        this.lastSensorTime = lastSensorTime;
    }
}