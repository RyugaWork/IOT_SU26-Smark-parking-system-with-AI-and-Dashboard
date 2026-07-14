package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import model.ParkingOccupancy;
import utils.ConnectDb;

public class ParkingOccupancyDAO {

    /**
     * Lấy trạng thái sức chứa hiện tại.
     */
    public ParkingOccupancy getCurrent() {
        String sql
                = "SELECT occupancy_id, capacity, "
                + "vehicles_inside, updated_at "
                + "FROM dbo.parking_occupancy "
                + "WHERE occupancy_id = 1";

        try (
            Connection conn = new ConnectDb().getConnection();
            PreparedStatement ps = conn.prepareStatement(sql);
            ResultSet rs = ps.executeQuery()
        ) {
            if (rs.next()) {
                return mapParkingOccupancy(rs);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        return null;
    }

    /**
     * Khởi tạo dòng occupancy_id = 1 nếu chưa tồn tại.
     */
    public boolean initialize(int capacity) {
        if (capacity < 0) {
            return false;
        }

        String sql
                = "IF NOT EXISTS ("
                + "    SELECT 1 "
                + "    FROM dbo.parking_occupancy "
                + "    WHERE occupancy_id = 1"
                + ") "
                + "BEGIN "
                + "    INSERT INTO dbo.parking_occupancy ("
                + "        occupancy_id, capacity, vehicles_inside"
                + "    ) VALUES (1, ?, 0) "
                + "END";

        try (
            Connection conn = new ConnectDb().getConnection();
            PreparedStatement ps = conn.prepareStatement(sql)
        ) {
            ps.setInt(1, capacity);
            ps.executeUpdate();

            return true;
        } catch (Exception e) {
            e.printStackTrace();
        }

        return false;
    }

    /**
     * Cập nhật capacity và vehicles_inside.
     */
    public boolean update(ParkingOccupancy occupancy) {
        if (occupancy == null) {
            return false;
        }

        if (occupancy.getCapacity() < 0
                || occupancy.getVehiclesInside() < 0
                || occupancy.getVehiclesInside()
                > occupancy.getCapacity()) {
            return false;
        }

        String sql
                = "UPDATE dbo.parking_occupancy "
                + "SET capacity = ?, "
                + "vehicles_inside = ?, "
                + "updated_at = SYSDATETIME() "
                + "WHERE occupancy_id = 1";

        try (
            Connection conn = new ConnectDb().getConnection();
            PreparedStatement ps = conn.prepareStatement(sql)
        ) {
            ps.setInt(1, occupancy.getCapacity());
            ps.setInt(2, occupancy.getVehiclesInside());

            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }

        return false;
    }

    /**
     * Cập nhật capacity.
     *
     * Không cho capacity nhỏ hơn vehicles_inside hiện tại.
     */
    public boolean updateCapacity(int capacity) {
        if (capacity < 0) {
            return false;
        }

        String sql
                = "UPDATE dbo.parking_occupancy "
                + "SET capacity = ?, "
                + "updated_at = SYSDATETIME() "
                + "WHERE occupancy_id = 1 "
                + "AND vehicles_inside <= ?";

        try (
            Connection conn = new ConnectDb().getConnection();
            PreparedStatement ps = conn.prepareStatement(sql)
        ) {
            ps.setInt(1, capacity);
            ps.setInt(2, capacity);

            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }

        return false;
    }

    /**
     * Gán trực tiếp vehicles_inside.
     */
    public boolean setVehiclesInside(int vehiclesInside) {
        if (vehiclesInside < 0) {
            return false;
        }

        String sql
                = "UPDATE dbo.parking_occupancy "
                + "SET vehicles_inside = ?, "
                + "updated_at = SYSDATETIME() "
                + "WHERE occupancy_id = 1 "
                + "AND ? <= capacity";

        try (
            Connection conn = new ConnectDb().getConnection();
            PreparedStatement ps = conn.prepareStatement(sql)
        ) {
            ps.setInt(1, vehiclesInside);
            ps.setInt(2, vehiclesInside);

            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }

        return false;
    }

    /**
     * Tăng vehicles_inside lên 1.
     *
     * Chỉ tăng khi bãi chưa đầy.
     */
    public boolean incrementVehiclesInside() {
        String sql
                = "UPDATE dbo.parking_occupancy "
                + "SET vehicles_inside = vehicles_inside + 1, "
                + "updated_at = SYSDATETIME() "
                + "WHERE occupancy_id = 1 "
                + "AND vehicles_inside < capacity";

        try (
            Connection conn = new ConnectDb().getConnection();
            PreparedStatement ps = conn.prepareStatement(sql)
        ) {
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }

        return false;
    }

    /**
     * Giảm vehicles_inside xuống 1.
     *
     * Chỉ giảm khi vehicles_inside lớn hơn 0.
     */
    public boolean decrementVehiclesInside() {
        String sql
                = "UPDATE dbo.parking_occupancy "
                + "SET vehicles_inside = vehicles_inside - 1, "
                + "updated_at = SYSDATETIME() "
                + "WHERE occupancy_id = 1 "
                + "AND vehicles_inside > 0";

        try (
            Connection conn = new ConnectDb().getConnection();
            PreparedStatement ps = conn.prepareStatement(sql)
        ) {
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }

        return false;
    }

    private ParkingOccupancy mapParkingOccupancy(
            ResultSet rs
    ) throws Exception {

        ParkingOccupancy occupancy = new ParkingOccupancy();

        occupancy.setOccupancyId(rs.getInt("occupancy_id"));
        occupancy.setCapacity(rs.getInt("capacity"));
        occupancy.setVehiclesInside(
                rs.getInt("vehicles_inside")
        );
        occupancy.setUpdatedAt(rs.getTimestamp("updated_at"));

        return occupancy;
    }
}