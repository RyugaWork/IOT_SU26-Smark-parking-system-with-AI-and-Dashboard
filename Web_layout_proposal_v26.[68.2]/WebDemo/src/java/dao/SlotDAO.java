package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;

import model.Slot;
import utils.ConnectDb;

public class SlotDAO {

    public List<Slot> getAll() {
        List<Slot> list = new ArrayList<>();

        String sql = "SELECT slot_id, slot_number, sensor_distance_cm, status, last_sensor_time "
                   + "FROM dbo.slots "
                   + "ORDER BY slot_number";

        try (
            Connection conn = new ConnectDb().getConnection();
            PreparedStatement ps = conn.prepareStatement(sql);
            ResultSet rs = ps.executeQuery();
        ) {
            while (rs.next()) {
                Slot slot = new Slot();

                slot.setSlotId(rs.getInt("slot_id"));
                slot.setSlotNumber(rs.getString("slot_number"));
                slot.setSensorDistanceCm(rs.getDouble("sensor_distance_cm"));
                slot.setStatus(rs.getString("status"));
                slot.setLastSensorTime(rs.getTimestamp("last_sensor_time"));

                list.add(slot);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        return list;
    }
}