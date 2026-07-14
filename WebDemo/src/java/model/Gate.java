package model;

import java.sql.Timestamp;

public class Gate {

    private String gateId;
    private String direction;
    private String gateState;
    private String lastDecision;
    private Timestamp lastUpdated;

    public Gate() {
    }

    public Gate(String gateId,
                String direction,
                String gateState,
                String lastDecision,
                Timestamp lastUpdated) {

        this.gateId = gateId;
        this.direction = direction;
        this.gateState = gateState;
        this.lastDecision = lastDecision;
        this.lastUpdated = lastUpdated;
    }

    public String getGateId() {
        return gateId;
    }

    public void setGateId(String gateId) {
        this.gateId = gateId;
    }

    public String getDirection() {
        return direction;
    }

    public void setDirection(String direction) {
        this.direction = direction;
    }

    public String getGateState() {
        return gateState;
    }

    public void setGateState(String gateState) {
        this.gateState = gateState;
    }

    public String getLastDecision() {
        return lastDecision;
    }

    public void setLastDecision(String lastDecision) {
        this.lastDecision = lastDecision;
    }

    public Timestamp getLastUpdated() {
        return lastUpdated;
    }

    public void setLastUpdated(Timestamp lastUpdated) {
        this.lastUpdated = lastUpdated;
    }
}