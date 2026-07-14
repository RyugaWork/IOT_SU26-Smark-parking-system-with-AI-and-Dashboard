package controller;

import dao.ParkingOccupancyDAO;
import java.io.IOException;
import javax.servlet.RequestDispatcher;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import model.ParkingOccupancy;

@WebServlet(
        name = "ParkingOccupancyController",
        urlPatterns = {"/occupancy"}
)
public class ParkingOccupancyController extends HttpServlet {

    private final ParkingOccupancyDAO parkingOccupancyDAO
            = new ParkingOccupancyDAO();

    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response
    ) throws ServletException, IOException {

        showOccupancy(request, response);
    }

    @Override
    protected void doPost(
            HttpServletRequest request,
            HttpServletResponse response
    ) throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        response.setCharacterEncoding("UTF-8");

        String action = normalize(
                request.getParameter("action")
        );

        if (action == null) {
            response.sendError(
                    HttpServletResponse.SC_BAD_REQUEST,
                    "Missing occupancy action."
            );
            return;
        }

        switch (action) {
            case "INITIALIZE":
                initialize(request, response);
                break;

            case "UPDATE_CAPACITY":
                updateCapacity(request, response);
                break;

            case "SET_VEHICLES_INSIDE":
                setVehiclesInside(request, response);
                break;

            case "INCREMENT":
                increment(request, response);
                break;

            case "DECREMENT":
                decrement(request, response);
                break;

            default:
                response.sendError(
                        HttpServletResponse.SC_BAD_REQUEST,
                        "Invalid occupancy action."
                );
                break;
        }
    }

    private void showOccupancy(
            HttpServletRequest request,
            HttpServletResponse response
    ) throws ServletException, IOException {

        response.setContentType("text/html;charset=UTF-8");

        try {
            ParkingOccupancy occupancy
                    = parkingOccupancyDAO.getCurrent();

            request.setAttribute("occupancy", occupancy);

            if (occupancy != null) {
                request.setAttribute(
                        "capacity",
                        occupancy.getCapacity()
                );

                request.setAttribute(
                        "vehiclesInside",
                        occupancy.getVehiclesInside()
                );

                request.setAttribute(
                        "availableCapacity",
                        occupancy.getAvailableCapacity()
                );
            }

            RequestDispatcher dispatcher
                    = request.getRequestDispatcher(
                            "/occupancy.jsp"
                    );

            dispatcher.forward(request, response);

        } catch (Exception e) {
            log("Cannot load occupancy data", e);

            request.setAttribute(
                    "errorMessage",
                    "Cannot load occupancy data."
            );

            RequestDispatcher dispatcher
                    = request.getRequestDispatcher(
                            "/occupancy.jsp"
                    );

            dispatcher.forward(request, response);
        }
    }

    private void initialize(
            HttpServletRequest request,
            HttpServletResponse response
    ) throws IOException {

        Integer capacity = parseNonNegativeInteger(
                request.getParameter("capacity")
        );

        if (capacity == null) {
            sendInvalidNumber(response, "capacity");
            return;
        }

        boolean success
                = parkingOccupancyDAO.initialize(capacity);

        redirectAfterUpdate(
                request,
                response,
                success
        );
    }

    private void updateCapacity(
            HttpServletRequest request,
            HttpServletResponse response
    ) throws IOException {

        Integer capacity = parseNonNegativeInteger(
                request.getParameter("capacity")
        );

        if (capacity == null) {
            sendInvalidNumber(response, "capacity");
            return;
        }

        boolean success
                = parkingOccupancyDAO.updateCapacity(capacity);

        redirectAfterUpdate(
                request,
                response,
                success
        );
    }

    private void setVehiclesInside(
            HttpServletRequest request,
            HttpServletResponse response
    ) throws IOException {

        Integer vehiclesInside = parseNonNegativeInteger(
                request.getParameter("vehiclesInside")
        );

        if (vehiclesInside == null) {
            sendInvalidNumber(
                    response,
                    "vehiclesInside"
            );
            return;
        }

        boolean success
                = parkingOccupancyDAO.setVehiclesInside(
                        vehiclesInside
                );

        redirectAfterUpdate(
                request,
                response,
                success
        );
    }

    private void increment(
            HttpServletRequest request,
            HttpServletResponse response
    ) throws IOException {

        boolean success
                = parkingOccupancyDAO.incrementVehiclesInside();

        redirectAfterUpdate(
                request,
                response,
                success
        );
    }

    private void decrement(
            HttpServletRequest request,
            HttpServletResponse response
    ) throws IOException {

        boolean success
                = parkingOccupancyDAO.decrementVehiclesInside();

        redirectAfterUpdate(
                request,
                response,
                success
        );
    }

    private void redirectAfterUpdate(
            HttpServletRequest request,
            HttpServletResponse response,
            boolean success
    ) throws IOException {

        if (!success) {
            response.sendRedirect(
                    request.getContextPath()
                    + "/occupancy?updated=false"
            );
            return;
        }

        response.sendRedirect(
                request.getContextPath()
                + "/occupancy?updated=true"
        );
    }

    private Integer parseNonNegativeInteger(
            String value
    ) {
        if (value == null || value.trim().isEmpty()) {
            return null;
        }

        try {
            int number = Integer.parseInt(value.trim());

            if (number < 0) {
                return null;
            }

            return number;

        } catch (NumberFormatException e) {
            return null;
        }
    }

    private void sendInvalidNumber(
            HttpServletResponse response,
            String fieldName
    ) throws IOException {

        response.sendError(
                HttpServletResponse.SC_BAD_REQUEST,
                "Invalid " + fieldName + "."
        );
    }

    private String normalize(String value) {
        if (value == null) {
            return null;
        }

        return value.trim().toUpperCase();
    }
}