package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;

import model.ParkingLog;
import utils.ConnectDb;

public class ParkingLogDAO {

    public List<ParkingLog> getAll() {
        List<ParkingLog> list = new ArrayList<>();

        String sql = "SELECT pl.log_id, pl.license_plate, pl.rfid_card_id, "
                   + "pl.slot_id, s.slot_number, "
                   + "pl.entry_time, pl.exit_time, pl.status, pl.vehicle_type, "
                   + "pl.entry_image_url, pl.exit_image_url, pl.fee_amount "
                   + "FROM dbo.parking_logs pl "
                   + "INNER JOIN dbo.slots s ON pl.slot_id = s.slot_id "
                   + "ORDER BY pl.entry_time DESC";

        try (
            Connection conn = new ConnectDb().getConnection();
            PreparedStatement ps = conn.prepareStatement(sql);
            ResultSet rs = ps.executeQuery();
        ) {
            while (rs.next()) {
                ParkingLog log = new ParkingLog();

                log.setLogId(rs.getInt("log_id"));
                log.setLicensePlate(rs.getString("license_plate"));
                log.setRfidCardId(rs.getString("rfid_card_id"));
                log.setSlotId(rs.getInt("slot_id"));
                log.setSlotNumber(rs.getString("slot_number"));
                log.setEntryTime(rs.getTimestamp("entry_time"));
                log.setExitTime(rs.getTimestamp("exit_time"));
                log.setStatus(rs.getString("status"));
                log.setVehicleType(rs.getString("vehicle_type"));
                log.setEntryImageUrl(rs.getString("entry_image_url"));
                log.setExitImageUrl(rs.getString("exit_image_url"));
                log.setFeeAmount(rs.getBigDecimal("fee_amount"));

                list.add(log);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        return list;
    }
}