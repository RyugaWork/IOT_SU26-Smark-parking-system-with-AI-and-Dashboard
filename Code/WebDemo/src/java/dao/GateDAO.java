package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;
import model.Gate;
import utils.ConnectDb;

public class GateDAO {

    /**
     * Lấy toàn bộ gate.
     */
    public List<Gate> getAll() {
        List<Gate> list = new ArrayList<>();

        String sql
                = "SELECT gate_id, direction, gate_state, "
                + "last_decision, last_updated "
                + "FROM dbo.gates "
                + "ORDER BY direction";

        try (
            Connection conn = new ConnectDb().getConnection();
            PreparedStatement ps = conn.prepareStatement(sql);
            ResultSet rs = ps.executeQuery()
        ) {
            while (rs.next()) {
                list.add(mapGate(rs));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        return list;
    }

    /**
     * Tìm gate theo gate_id.
     */
    public Gate getById(String gateId) {
        if (gateId == null || gateId.trim().isEmpty()) {
            return null;
        }

        String sql
                = "SELECT gate_id, direction, gate_state, "
                + "last_decision, last_updated "
                + "FROM dbo.gates "
                + "WHERE gate_id = ?";

        try (
            Connection conn = new ConnectDb().getConnection();
            PreparedStatement ps = conn.prepareStatement(sql)
        ) {
            ps.setString(1, gateId.trim().toUpperCase());

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapGate(rs);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        return null;
    }

    /**
     * Tìm gate theo direction: ENTRY hoặc EXIT.
     */
    public Gate getByDirection(String direction) {
        if (direction == null || direction.trim().isEmpty()) {
            return null;
        }

        String sql
                = "SELECT gate_id, direction, gate_state, "
                + "last_decision, last_updated "
                + "FROM dbo.gates "
                + "WHERE direction = ?";

        try (
            Connection conn = new ConnectDb().getConnection();
            PreparedStatement ps = conn.prepareStatement(sql)
        ) {
            ps.setString(1, direction.trim().toUpperCase());

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapGate(rs);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        return null;
    }

    /**
     * Thêm gate mới.
     */
    public boolean insert(Gate gate) {
        if (gate == null) {
            return false;
        }

        String sql
                = "INSERT INTO dbo.gates ("
                + "gate_id, direction, gate_state, last_decision"
                + ") VALUES (?, ?, ?, ?)";

        try (
            Connection conn = new ConnectDb().getConnection();
            PreparedStatement ps = conn.prepareStatement(sql)
        ) {
            ps.setString(1, gate.getGateId());
            ps.setString(2, gate.getDirection());
            ps.setString(3, gate.getGateState());
            ps.setString(4, gate.getLastDecision());

            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }

        return false;
    }

    /**
     * Cập nhật toàn bộ trạng thái gate.
     */
    public boolean update(Gate gate) {
        if (gate == null
                || gate.getGateId() == null
                || gate.getGateId().trim().isEmpty()) {
            return false;
        }

        String sql
                = "UPDATE dbo.gates "
                + "SET direction = ?, "
                + "gate_state = ?, "
                + "last_decision = ?, "
                + "last_updated = SYSDATETIME() "
                + "WHERE gate_id = ?";

        try (
            Connection conn = new ConnectDb().getConnection();
            PreparedStatement ps = conn.prepareStatement(sql)
        ) {
            ps.setString(1, gate.getDirection());
            ps.setString(2, gate.getGateState());
            ps.setString(3, gate.getLastDecision());
            ps.setString(4, gate.getGateId());

            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }

        return false;
    }

    /**
     * Cập nhật gate_state và last_decision.
     */
    public boolean updateState(
            String gateId,
            String gateState,
            String lastDecision
    ) {
        if (gateId == null || gateId.trim().isEmpty()) {
            return false;
        }

        String sql
                = "UPDATE dbo.gates "
                + "SET gate_state = ?, "
                + "last_decision = ?, "
                + "last_updated = SYSDATETIME() "
                + "WHERE gate_id = ?";

        try (
            Connection conn = new ConnectDb().getConnection();
            PreparedStatement ps = conn.prepareStatement(sql)
        ) {
            ps.setString(1, gateState);
            ps.setString(2, lastDecision);
            ps.setString(3, gateId.trim().toUpperCase());

            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }

        return false;
    }

    /**
     * Chỉ cập nhật trạng thái vật lý của gate.
     */
    public boolean updateGateState(
            String gateId,
            String gateState
    ) {
        if (gateId == null || gateId.trim().isEmpty()) {
            return false;
        }

        String sql
                = "UPDATE dbo.gates "
                + "SET gate_state = ?, "
                + "last_updated = SYSDATETIME() "
                + "WHERE gate_id = ?";

        try (
            Connection conn = new ConnectDb().getConnection();
            PreparedStatement ps = conn.prepareStatement(sql)
        ) {
            ps.setString(1, gateState);
            ps.setString(2, gateId.trim().toUpperCase());

            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }

        return false;
    }

    private Gate mapGate(ResultSet rs) throws Exception {
        Gate gate = new Gate();

        gate.setGateId(rs.getString("gate_id"));
        gate.setDirection(rs.getString("direction"));
        gate.setGateState(rs.getString("gate_state"));
        gate.setLastDecision(rs.getString("last_decision"));
        gate.setLastUpdated(rs.getTimestamp("last_updated"));

        return gate;
    }
}