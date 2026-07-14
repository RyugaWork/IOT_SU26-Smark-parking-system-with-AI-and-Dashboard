package controller;

import dao.DetectionEventDAO;
import java.io.IOException;
import java.util.List;
import javax.servlet.RequestDispatcher;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import model.DetectionEvent;

@WebServlet(
        name = "DetectionEventController",
        urlPatterns = {"/detections"}
)
public class DetectionEventController extends HttpServlet {

    private static final int DEFAULT_LIMIT = 50;
    private static final int MAX_LIMIT = 500;

    private final DetectionEventDAO detectionEventDAO
            = new DetectionEventDAO();

    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response
    ) throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        response.setCharacterEncoding("UTF-8");
        response.setContentType("text/html;charset=UTF-8");

        String action = request.getParameter("action");

        if (action == null || action.trim().isEmpty()) {
            action = "list";
        }

        switch (action.toLowerCase()) {
            case "detail":
                showDetail(request, response);
                break;

            case "list":
            default:
                showList(request, response);
                break;
        }
    }

    private void showList(
            HttpServletRequest request,
            HttpServletResponse response
    ) throws ServletException, IOException {

        try {
            int limit = parseLimit(request.getParameter("limit"));

            List<DetectionEvent> detectionEvents
                    = detectionEventDAO.getRecent(limit);

            DetectionEvent latestEntry
                    = detectionEventDAO.getLatestByDirection("ENTRY");

            DetectionEvent latestExit
                    = detectionEventDAO.getLatestByDirection("EXIT");

            request.setAttribute(
                    "detectionEvents",
                    detectionEvents
            );

            request.setAttribute(
                    "latestEntry",
                    latestEntry
            );

            request.setAttribute(
                    "latestExit",
                    latestExit
            );

            request.setAttribute("limit", limit);

            RequestDispatcher dispatcher
                    = request.getRequestDispatcher(
                            "/detection-events.jsp"
                    );

            dispatcher.forward(request, response);

        } catch (Exception e) {
            log("Cannot load detection events", e);

            request.setAttribute(
                    "errorMessage",
                    "Cannot load detection events."
            );

            RequestDispatcher dispatcher
                    = request.getRequestDispatcher(
                            "/detection-events.jsp"
                    );

            dispatcher.forward(request, response);
        }
    }

    private void showDetail(
            HttpServletRequest request,
            HttpServletResponse response
    ) throws ServletException, IOException {

        String idValue = request.getParameter("id");

        if (idValue == null || idValue.trim().isEmpty()) {
            response.sendRedirect(
                    request.getContextPath() + "/detections"
            );
            return;
        }

        try {
            long detectionId = Long.parseLong(idValue);

            DetectionEvent detectionEvent
                    = detectionEventDAO.getById(detectionId);

            if (detectionEvent == null) {
                response.sendError(
                        HttpServletResponse.SC_NOT_FOUND,
                        "Detection event not found."
                );
                return;
            }

            request.setAttribute(
                    "detectionEvent",
                    detectionEvent
            );

            RequestDispatcher dispatcher
                    = request.getRequestDispatcher(
                            "/detection-detail.jsp"
                    );

            dispatcher.forward(request, response);

        } catch (NumberFormatException e) {
            response.sendError(
                    HttpServletResponse.SC_BAD_REQUEST,
                    "Invalid detection ID."
            );
        } catch (Exception e) {
            log("Cannot load detection detail", e);

            response.sendError(
                    HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "Cannot load detection detail."
            );
        }
    }

    private int parseLimit(String value) {
        if (value == null || value.trim().isEmpty()) {
            return DEFAULT_LIMIT;
        }

        try {
            int limit = Integer.parseInt(value);

            if (limit < 1) {
                return DEFAULT_LIMIT;
            }

            if (limit > MAX_LIMIT) {
                return MAX_LIMIT;
            }

            return limit;

        } catch (NumberFormatException e) {
            return DEFAULT_LIMIT;
        }
    }
}