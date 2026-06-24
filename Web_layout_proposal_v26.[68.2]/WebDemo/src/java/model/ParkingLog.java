package model;

import java.math.BigDecimal;
import java.sql.Timestamp;

public class ParkingLog {

    private int logId;
    private String licensePlate;
    private String rfidCardId;
    private int slotId;
    private String slotNumber; // Lấy thêm từ bảng slots bằng JOIN, không phải cột gốc trong parking_logs
    private Timestamp entryTime;
    private Timestamp exitTime;
    private String status;
    private String vehicleType;
    private String entryImageUrl;
    private String exitImageUrl;
    private BigDecimal feeAmount;

    public ParkingLog() {
    }

    public ParkingLog(int logId, String licensePlate, String rfidCardId, int slotId, String slotNumber,
                      Timestamp entryTime, Timestamp exitTime, String status, String vehicleType,
                      String entryImageUrl, String exitImageUrl, BigDecimal feeAmount) {
        this.logId = logId;
        this.licensePlate = licensePlate;
        this.rfidCardId = rfidCardId;
        this.slotId = slotId;
        this.slotNumber = slotNumber;
        this.entryTime = entryTime;
        this.exitTime = exitTime;
        this.status = status;
        this.vehicleType = vehicleType;
        this.entryImageUrl = entryImageUrl;
        this.exitImageUrl = exitImageUrl;
        this.feeAmount = feeAmount;
    }

    public int getLogId() {
        return logId;
    }

    public void setLogId(int logId) {
        this.logId = logId;
    }

    public String getLicensePlate() {
        return licensePlate;
    }

    public void setLicensePlate(String licensePlate) {
        this.licensePlate = licensePlate;
    }

    public String getRfidCardId() {
        return rfidCardId;
    }

    public void setRfidCardId(String rfidCardId) {
        this.rfidCardId = rfidCardId;
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

    public Timestamp getEntryTime() {
        return entryTime;
    }

    public void setEntryTime(Timestamp entryTime) {
        this.entryTime = entryTime;
    }

    public Timestamp getExitTime() {
        return exitTime;
    }

    public void setExitTime(Timestamp exitTime) {
        this.exitTime = exitTime;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public String getVehicleType() {
        return vehicleType;
    }

    public void setVehicleType(String vehicleType) {
        this.vehicleType = vehicleType;
    }

    public String getEntryImageUrl() {
        return entryImageUrl;
    }

    public void setEntryImageUrl(String entryImageUrl) {
        this.entryImageUrl = entryImageUrl;
    }

    public String getExitImageUrl() {
        return exitImageUrl;
    }

    public void setExitImageUrl(String exitImageUrl) {
        this.exitImageUrl = exitImageUrl;
    }

    public BigDecimal getFeeAmount() {
        return feeAmount;
    }

    public void setFeeAmount(BigDecimal feeAmount) {
        this.feeAmount = feeAmount;
    }
}