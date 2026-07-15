package controller;

import dao.DashboardDAO;
import dao.DetectionEventDAO;
import dao.GateDAO;
import dao.ParkingOccupancyDAO;
import java.io.IOException;
import java.util.List;
import javax.servlet.RequestDispatcher;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import model.DashboardOverview;
import model.DetectionEvent;
import model.Gate;
import model.ParkingOccupancy;

@WebServlet(name = "DashboardController", urlPatterns = {"/dashboard"})
public class DashboardController extends HttpServlet {

    private final DashboardDAO dashboardDAO = new DashboardDAO();
    private final DetectionEventDAO detectionEventDAO
            = new DetectionEventDAO();
    private final GateDAO gateDAO = new GateDAO();
    private final ParkingOccupancyDAO parkingOccupancyDAO
            = new ParkingOccupancyDAO();

    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response
    ) throws ServletException, IOException {

        processDashboard(request, response);
    }

    private void processDashboard(
            HttpServletRequest request,
            HttpServletResponse response
    ) throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        response.setCharacterEncoding("UTF-8");
        response.setContentType("text/html;charset=UTF-8");

        try {
            DashboardOverview overview
                    = dashboardDAO.getOverview();

            DetectionEvent latestEntry
                    = detectionEventDAO.getLatestByDirection("ENTRY");

            DetectionEvent latestExit
                    = detectionEventDAO.getLatestByDirection("EXIT");

            List<DetectionEvent> recentEvents
                    = detectionEventDAO.getRecent(50);

            List<Gate> gates = gateDAO.getAll();

            Gate entryGate = gateDAO.getById("ENTRY_GATE");
            Gate exitGate = gateDAO.getById("EXIT_GATE");

            ParkingOccupancy occupancy
                    = parkingOccupancyDAO.getCurrent();

            request.setAttribute("overview", overview);
            request.setAttribute("latestEntry", latestEntry);
            request.setAttribute("latestExit", latestExit);
            request.setAttribute("recentEvents", recentEvents);
            request.setAttribute("gates", gates);
            request.setAttribute("entryGate", entryGate);
            request.setAttribute("exitGate", exitGate);
            request.setAttribute("occupancy", occupancy);

            if (overview != null) {
                request.setAttribute(
                        "capacity",
                        overview.getCapacity()
                );

                request.setAttribute(
                        "vehiclesInside",
                        overview.getVehiclesInside()
                );

                request.setAttribute(
                        "availableCapacity",
                        overview.getAvailableCapacity()
                );

                request.setAttribute(
                        "entriesToday",
                        overview.getEntriesToday()
                );

                request.setAttribute(
                        "exitsToday",
                        overview.getExitsToday()
                );

                request.setAttribute(
                        "entryGateStatus",
                        overview.getEntryGateState()
                );

                request.setAttribute(
                        "exitGateStatus",
                        overview.getExitGateState()
                );

                request.setAttribute(
                        "gateStatus",
                        buildGateStatus(
                                overview.getEntryGateState(),
                                overview.getExitGateState()
                        )
                );
            } else {
                setDefaultDashboardValues(request);
            }

            /*
             * Database hiện chưa có bảng heartbeat cho camera/sensor.
             * Vì vậy không được hiển thị ONLINE cố định.
             */
            request.setAttribute("entryCameraStatus", "UNKNOWN");
            request.setAttribute("exitCameraStatus", "UNKNOWN");
            request.setAttribute("entrySensorStatus", "UNKNOWN");
            request.setAttribute("exitSensorStatus", "UNKNOWN");

            RequestDispatcher dispatcher
                    = request.getRequestDispatcher("/dashboard.jsp");

            dispatcher.forward(request, response);

        } catch (Exception e) {
            log("DashboardController error", e);

            request.setAttribute(
                    "errorMessage",
                    "Cannot load dashboard data."
            );

            setDefaultDashboardValues(request);

            RequestDispatcher dispatcher
                    = request.getRequestDispatcher("/dashboard.jsp");

            dispatcher.forward(request, response);
        }
    }

    private void setDefaultDashboardValues(
            HttpServletRequest request
    ) {
        request.setAttribute("capacity", 0);
        request.setAttribute("vehiclesInside", 0);
        request.setAttribute("availableCapacity", 0);
        request.setAttribute("entriesToday", 0);
        request.setAttribute("exitsToday", 0);
        request.setAttribute("entryGateStatus", "UNKNOWN");
        request.setAttribute("exitGateStatus", "UNKNOWN");
        request.setAttribute("gateStatus", "UNKNOWN");
    }

    private String buildGateStatus(
            String entryGateState,
            String exitGateState
    ) {
        String entry = entryGateState == null
                ? "UNKNOWN"
                : entryGateState;

        String exit = exitGateState == null
                ? "UNKNOWN"
                : exitGateState;

        if (entry.equalsIgnoreCase(exit)) {
            return entry;
        }

        return "ENTRY: " + entry + " | EXIT: " + exit;
    }
}