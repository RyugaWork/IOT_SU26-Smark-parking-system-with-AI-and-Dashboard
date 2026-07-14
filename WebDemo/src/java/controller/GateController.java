package controller;

import dao.GateDAO;
import java.io.IOException;
import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import javax.servlet.RequestDispatcher;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import model.Gate;

@WebServlet(name = "GateController", urlPatterns = {"/gates"})
public class GateController extends HttpServlet {

    private static final Set<String> VALID_GATE_IDS
            = new HashSet<>(Arrays.asList(
                    "ENTRY_GATE",
                    "EXIT_GATE"
            ));

    private static final Set<String> VALID_GATE_STATES
            = new HashSet<>(Arrays.asList(
                    "CLOSED",
                    "OPENING",
                    "OPEN",
                    "CLOSING",
                    "ERROR"
            ));

    private static final Set<String> VALID_DECISIONS
            = new HashSet<>(Arrays.asList(
                    "OPEN",
                    "CLOSE",
                    "NONE"
            ));

    private final GateDAO gateDAO = new GateDAO();

    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response
    ) throws ServletException, IOException {

        showGateList(request, response);
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

        if ("UPDATE_STATE".equals(action)) {
            updateGateState(request, response);
            return;
        }

        response.sendError(
                HttpServletResponse.SC_BAD_REQUEST,
                "Invalid gate action."
        );
    }

    private void showGateList(
            HttpServletRequest request,
            HttpServletResponse response
    ) throws ServletException, IOException {

        response.setContentType("text/html;charset=UTF-8");

        try {
            List<Gate> gates = gateDAO.getAll();

            Gate entryGate = gateDAO.getById("ENTRY_GATE");
            Gate exitGate = gateDAO.getById("EXIT_GATE");

            request.setAttribute("gates", gates);
            request.setAttribute("entryGate", entryGate);
            request.setAttribute("exitGate", exitGate);

            RequestDispatcher dispatcher
                    = request.getRequestDispatcher("/gates.jsp");

            dispatcher.forward(request, response);

        } catch (Exception e) {
            log("Cannot load gate data", e);

            request.setAttribute(
                    "errorMessage",
                    "Cannot load gate data."
            );

            RequestDispatcher dispatcher
                    = request.getRequestDispatcher("/gates.jsp");

            dispatcher.forward(request, response);
        }
    }

    private void updateGateState(
            HttpServletRequest request,
            HttpServletResponse response
    ) throws IOException {

        String gateId = normalize(
                request.getParameter("gateId")
        );

        String gateState = normalize(
                request.getParameter("gateState")
        );

        String lastDecision = normalize(
                request.getParameter("lastDecision")
        );

        if (!VALID_GATE_IDS.contains(gateId)) {
            response.sendError(
                    HttpServletResponse.SC_BAD_REQUEST,
                    "Invalid gate ID."
            );
            return;
        }

        if (!VALID_GATE_STATES.contains(gateState)) {
            response.sendError(
                    HttpServletResponse.SC_BAD_REQUEST,
                    "Invalid gate state."
            );
            return;
        }

        if (lastDecision == null
                || lastDecision.isEmpty()) {
            lastDecision = "NONE";
        }

        if (!VALID_DECISIONS.contains(lastDecision)) {
            response.sendError(
                    HttpServletResponse.SC_BAD_REQUEST,
                    "Invalid gate decision."
            );
            return;
        }

        boolean updated = gateDAO.updateState(
                gateId,
                gateState,
                lastDecision
        );

        if (!updated) {
            response.sendError(
                    HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "Cannot update gate state."
            );
            return;
        }

        response.sendRedirect(
                request.getContextPath()
                + "/gates?updated=true"
        );
    }

    private String normalize(String value) {
        if (value == null) {
            return null;
        }

        return value.trim().toUpperCase();
    }
}