package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.sql.Types;
import java.util.ArrayList;
import java.util.List;
import model.DetectionEvent;
import utils.ConnectDb;

public class DetectionEventDAO {

    private static final String SELECT_COLUMNS
            = "detection_id, gate_id, direction, sequence_id, "
            + "distance_cm, object_detected, raw_image_path, "
            + "annotated_image_path, detected_class, confidence, "
            + "decision, event_status, count_before, count_after, "
            + "error_message, created_at ";

    /**
     * Lấy toàn bộ detection event, mới nhất trước.
     */
    public List<DetectionEvent> getAll() {
        List<DetectionEvent> list = new ArrayList<>();

        String sql = "SELECT " + SELECT_COLUMNS
                + "FROM dbo.detection_events "
                + "ORDER BY created_at DESC, detection_id DESC";

        try (
            Connection conn = new ConnectDb().getConnection();
            PreparedStatement ps = conn.prepareStatement(sql);
            ResultSet rs = ps.executeQuery()
        ) {
            while (rs.next()) {
                list.add(mapDetectionEvent(rs));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        return list;
    }

    /**
     * Lấy số detection event gần nhất.
     * limit được giới hạn từ 1 đến 500.
     */
    public List<DetectionEvent> getRecent(int limit) {
        List<DetectionEvent> list = new ArrayList<>();

        int safeLimit = limit;

        if (safeLimit < 1) {
            safeLimit = 1;
        }

        if (safeLimit > 500) {
            safeLimit = 500;
        }

        String sql = "SELECT TOP " + safeLimit + " "
                + SELECT_COLUMNS
                + "FROM dbo.detection_events "
                + "ORDER BY created_at DESC, detection_id DESC";

        try (
            Connection conn = new ConnectDb().getConnection();
            PreparedStatement ps = conn.prepareStatement(sql);
            ResultSet rs = ps.executeQuery()
        ) {
            while (rs.next()) {
                list.add(mapDetectionEvent(rs));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        return list;
    }

    /**
     * Lấy 50 detection event gần nhất.
     */
    public List<DetectionEvent> getRecent() {
        return getRecent(50);
    }

    /**
     * Tìm detection event theo primary key.
     */
    public DetectionEvent getById(long detectionId) {
        String sql = "SELECT " + SELECT_COLUMNS
                + "FROM dbo.detection_events "
                + "WHERE detection_id = ?";

        try (
            Connection conn = new ConnectDb().getConnection();
            PreparedStatement ps = conn.prepareStatement(sql)
        ) {
            ps.setLong(1, detectionId);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapDetectionEvent(rs);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        return null;
    }

    /**
     * Lấy detection mới nhất theo direction: ENTRY hoặc EXIT.
     */
    public DetectionEvent getLatestByDirection(String direction) {
        if (direction == null || direction.trim().isEmpty()) {
            return null;
        }

        String sql = "SELECT TOP 1 " + SELECT_COLUMNS
                + "FROM dbo.detection_events "
                + "WHERE direction = ? "
                + "ORDER BY created_at DESC, detection_id DESC";

        try (
            Connection conn = new ConnectDb().getConnection();
            PreparedStatement ps = conn.prepareStatement(sql)
        ) {
            ps.setString(1, direction.trim().toUpperCase());

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapDetectionEvent(rs);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        return null;
    }

    /**
     * Lấy detection mới nhất theo gate_id.
     */
    public DetectionEvent getLatestByGate(String gateId) {
        if (gateId == null || gateId.trim().isEmpty()) {
            return null;
        }

        String sql = "SELECT TOP 1 " + SELECT_COLUMNS
                + "FROM dbo.detection_events "
                + "WHERE gate_id = ? "
                + "ORDER BY created_at DESC, detection_id DESC";

        try (
            Connection conn = new ConnectDb().getConnection();
            PreparedStatement ps = conn.prepareStatement(sql)
        ) {
            ps.setString(1, gateId.trim().toUpperCase());

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapDetectionEvent(rs);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        return null;
    }

    /**
     * Thêm một detection event mới.
     *
     * @return detection_id vừa được tạo; trả về -1 nếu thất bại.
     */
    public long insert(DetectionEvent event) {
        if (event == null) {
            return -1;
        }

        String sql
                = "INSERT INTO dbo.detection_events ("
                + "gate_id, direction, sequence_id, distance_cm, "
                + "object_detected, raw_image_path, annotated_image_path, "
                + "detected_class, confidence, decision, event_status, "
                + "count_before, count_after, error_message"
                + ") VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

        try (
            Connection conn = new ConnectDb().getConnection();
            PreparedStatement ps = conn.prepareStatement(
                    sql,
                    Statement.RETURN_GENERATED_KEYS
            )
        ) {
            ps.setString(1, event.getGateId());
            ps.setString(2, event.getDirection());

            setNullableInteger(ps, 3, event.getSequenceId());

            if (event.getDistanceCm() != null) {
                ps.setBigDecimal(4, event.getDistanceCm());
            } else {
                ps.setNull(4, Types.DECIMAL);
            }

            if (event.getObjectDetected() != null) {
                ps.setBoolean(5, event.getObjectDetected());
            } else {
                ps.setNull(5, Types.BIT);
            }

            ps.setString(6, event.getRawImagePath());
            ps.setString(7, event.getAnnotatedImagePath());
            ps.setString(8, event.getDetectedClass());

            if (event.getConfidence() != null) {
                ps.setBigDecimal(9, event.getConfidence());
            } else {
                ps.setNull(9, Types.DECIMAL);
            }

            ps.setString(10, event.getDecision());
            ps.setString(11, event.getEventStatus());

            setNullableInteger(ps, 12, event.getCountBefore());
            setNullableInteger(ps, 13, event.getCountAfter());

            ps.setString(14, event.getErrorMessage());

            int affectedRows = ps.executeUpdate();

            if (affectedRows == 0) {
                return -1;
            }

            try (ResultSet keys = ps.getGeneratedKeys()) {
                if (keys.next()) {
                    return keys.getLong(1);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        return -1;
    }

    /**
     * Đếm event OPEN trong ngày theo direction.
     */
    public int countOpenEventsToday(String direction) {
        if (direction == null || direction.trim().isEmpty()) {
            return 0;
        }

        String sql
                = "SELECT COUNT(*) AS total "
                + "FROM dbo.detection_events "
                + "WHERE direction = ? "
                + "AND decision = 'OPEN' "
                + "AND CAST(created_at AS DATE) = CAST(GETDATE() AS DATE)";

        try (
            Connection conn = new ConnectDb().getConnection();
            PreparedStatement ps = conn.prepareStatement(sql)
        ) {
            ps.setString(1, direction.trim().toUpperCase());

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt("total");
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        return 0;
    }

    /**
     * Chuyển một ResultSet row thành DetectionEvent.
     */
    private DetectionEvent mapDetectionEvent(ResultSet rs) throws Exception {
        DetectionEvent event = new DetectionEvent();

        event.setDetectionId(rs.getLong("detection_id"));
        event.setGateId(rs.getString("gate_id"));
        event.setDirection(rs.getString("direction"));
        event.setSequenceId(getNullableInteger(rs, "sequence_id"));
        event.setDistanceCm(rs.getBigDecimal("distance_cm"));
        event.setObjectDetected(
                getNullableBoolean(rs, "object_detected")
        );
        event.setRawImagePath(rs.getString("raw_image_path"));
        event.setAnnotatedImagePath(
                rs.getString("annotated_image_path")
        );
        event.setDetectedClass(rs.getString("detected_class"));
        event.setConfidence(rs.getBigDecimal("confidence"));
        event.setDecision(rs.getString("decision"));
        event.setEventStatus(rs.getString("event_status"));
        event.setCountBefore(
                getNullableInteger(rs, "count_before")
        );
        event.setCountAfter(
                getNullableInteger(rs, "count_after")
        );
        event.setErrorMessage(rs.getString("error_message"));
        event.setCreatedAt(rs.getTimestamp("created_at"));

        return event;
    }

    private Integer getNullableInteger(
            ResultSet rs,
            String columnName
    ) throws Exception {

        Object value = rs.getObject(columnName);

        if (value == null) {
            return null;
        }

        return ((Number) value).intValue();
    }

    private Boolean getNullableBoolean(
            ResultSet rs,
            String columnName
    ) throws Exception {

        Object value = rs.getObject(columnName);

        if (value == null) {
            return null;
        }

        if (value instanceof Boolean) {
            return (Boolean) value;
        }

        if (value instanceof Number) {
            return ((Number) value).intValue() != 0;
        }

        return Boolean.valueOf(value.toString());
    }

    private void setNullableInteger(
            PreparedStatement ps,
            int parameterIndex,
            Integer value
    ) throws Exception {

        if (value != null) {
            ps.setInt(parameterIndex, value);
        } else {
            ps.setNull(parameterIndex, Types.INTEGER);
        }
    }
}