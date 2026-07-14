package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import model.DashboardOverview;
import utils.ConnectDb;

public class DashboardDAO {

    /**
     * Lấy dữ liệu tổng quan cho dashboard.
     */
    public DashboardOverview getOverview() {
        String sql
                = "SELECT capacity, vehicles_inside, "
                + "available_capacity, entries_today, exits_today, "
                + "entry_gate_state, exit_gate_state, updated_at "
                + "FROM dbo.v_dashboard_overview";

        try (
            Connection conn = new ConnectDb().getConnection();
            PreparedStatement ps = conn.prepareStatement(sql);
            ResultSet rs = ps.executeQuery()
        ) {
            if (rs.next()) {
                return mapDashboardOverview(rs);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        return null;
    }

    private DashboardOverview mapDashboardOverview(
            ResultSet rs
    ) throws Exception {

        DashboardOverview overview = new DashboardOverview();

        overview.setCapacity(rs.getInt("capacity"));
        overview.setVehiclesInside(
                rs.getInt("vehicles_inside")
        );
        overview.setAvailableCapacity(
                rs.getInt("available_capacity")
        );
        overview.setEntriesToday(
                rs.getInt("entries_today")
        );
        overview.setExitsToday(
                rs.getInt("exits_today")
        );
        overview.setEntryGateState(
                rs.getString("entry_gate_state")
        );
        overview.setExitGateState(
                rs.getString("exit_gate_state")
        );
        overview.setUpdatedAt(
                rs.getTimestamp("updated_at")
        );

        return overview;
    }
}