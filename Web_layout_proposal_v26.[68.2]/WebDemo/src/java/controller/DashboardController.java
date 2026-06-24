package controller;

import dao.ParkingLogDAO;
import dao.SlotDAO;
import java.io.IOException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.List;
import javax.servlet.RequestDispatcher;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import model.ParkingLog;
import model.Slot;

@WebServlet(name = "DashboardController", urlPatterns = {"/dashboard"})
public class DashboardController extends HttpServlet {

    private final SlotDAO slotDAO = new SlotDAO();
    private final ParkingLogDAO parkingLogDAO = new ParkingLogDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processDashboard(request, response);
    }

    private void processDashboard(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        List<Slot> slots = slotDAO.getAll();
        List<ParkingLog> parkingLogs = parkingLogDAO.getAll();

        List<ParkingLog> parkedLogs = new ArrayList<>();
        List<ParkingLog> completedLogs = new ArrayList<>();

        ParkingLog latestEntry = null;
        ParkingLog latestExit = null;

        int entriesToday = 0;
        int exitsToday = 0;

        for (ParkingLog log : parkingLogs) {
            if ("PARKED".equalsIgnoreCase(log.getStatus())) {
                parkedLogs.add(log);
            }

            if ("COMPLETED".equalsIgnoreCase(log.getStatus())) {
                completedLogs.add(log);
            }

            if (latestEntry == null) {
                latestEntry = log;
            }

            if (latestExit == null && log.getExitTime() != null) {
                latestExit = log;
            }

            if (isToday(log.getEntryTime())) {
                entriesToday++;
            }

            if (log.getExitTime() != null && isToday(log.getExitTime())) {
                exitsToday++;
            }
        }

        int totalSlots = slots.size();
        int occupiedSlots = 0;
        int availableSlots = 0;

        for (Slot slot : slots) {
            if ("OCCUPIED".equalsIgnoreCase(slot.getStatus())) {
                occupiedSlots++;
            } else if ("AVAILABLE".equalsIgnoreCase(slot.getStatus())) {
                availableSlots++;
            }
        }

        // TODO: Chờ tích hợp AI thật.
        // Sau này latestEntry/latestExit có thể lấy từ camera + AI detection thay vì database mock.
        request.setAttribute("latestEntry", latestEntry);
        request.setAttribute("latestExit", latestExit);

        request.setAttribute("slots", slots);
        request.setAttribute("parkingLogs", parkingLogs);
        request.setAttribute("parkedLogs", parkedLogs);
        request.setAttribute("completedLogs", completedLogs);

        request.setAttribute("totalSlots", totalSlots);
        request.setAttribute("occupiedSlots", occupiedSlots);
        request.setAttribute("availableSlots", availableSlots);

        request.setAttribute("vehiclesInside", parkedLogs.size());
        request.setAttribute("entriesToday", entriesToday);
        request.setAttribute("exitsToday", exitsToday);

        // TODO: Gate status đang mock cứng.
        // Sau này lấy từ Arduino/ESP32 hoặc bảng gate_commands.
        request.setAttribute("gateStatus", "OPEN");

        RequestDispatcher rd = request.getRequestDispatcher("/dashboard.jsp");
        rd.forward(request, response);
    }

    private boolean isToday(Timestamp timestamp) {
        if (timestamp == null) {
            return false;
        }

        Calendar today = Calendar.getInstance();
        Calendar date = Calendar.getInstance();
        date.setTime(timestamp);

        return today.get(Calendar.YEAR) == date.get(Calendar.YEAR)
                && today.get(Calendar.DAY_OF_YEAR) == date.get(Calendar.DAY_OF_YEAR);
    }
}