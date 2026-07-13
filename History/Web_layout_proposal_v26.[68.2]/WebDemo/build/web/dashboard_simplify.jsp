<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.Date"%>
<%@taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt"%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Smart Parking Dashboard</title>

    <style>
        body {
            margin: 0;
            padding: 0;
            background: #07111f;
            color: #e5edf7;
            font-family: Arial, Helvetica, sans-serif;
        }

        .page {
            padding: 22px;
        }

        .header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 16px;
            margin-bottom: 22px;
        }

        .brand {
            font-weight: bold;
            color: #ff7a1a;
            line-height: 1.3;
            min-width: 160px;
        }

        .brand span {
            display: block;
            color: #36a3ff;
            font-size: 14px;
        }

        .title {
            font-size: 28px;
            font-weight: bold;
            text-align: center;
            flex: 1;
        }

        .system-status {
            display: flex;
            gap: 12px;
            align-items: center;
        }

        .status-pill {
            background: #102033;
            border: 1px solid #1e344f;
            border-radius: 10px;
            padding: 10px 14px;
            font-size: 14px;
            white-space: nowrap;
        }

        .online {
            color: #31d06b;
            font-weight: bold;
        }

        .offline {
            color: #ff6b6b;
            font-weight: bold;
        }

        .kpi-grid {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 14px;
            margin-bottom: 16px;
        }

        .card {
            background: #0f1d2d;
            border: 1px solid #1e344f;
            border-radius: 12px;
            box-shadow: 0 8px 18px rgba(0, 0, 0, 0.25);
        }

        .kpi-card {
            padding: 18px;
        }

        .kpi-title {
            color: #b9c7d8;
            font-size: 14px;
        }

        .kpi-number {
            font-size: 30px;
            font-weight: bold;
            margin-top: 6px;
        }

        .kpi-note {
            color: #93a4b8;
            font-size: 13px;
            margin-top: 6px;
        }

        .main-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 16px;
            margin-bottom: 16px;
        }

        .section {
            padding: 16px;
        }

        .section-title {
            font-size: 18px;
            font-weight: bold;
            margin-bottom: 14px;
        }

        .device-grid {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 14px;
            margin-bottom: 16px;
        }

        .device-card {
            padding: 16px;
        }

        .device-name {
            color: #b9c7d8;
            font-size: 14px;
            margin-bottom: 8px;
        }

        .device-state {
            font-size: 20px;
            font-weight: bold;
        }

        .capture-layout {
            display: grid;
            grid-template-columns: 1.3fr 1fr;
            gap: 14px;
        }

        .image-box {
            background: #07111f;
            border: 1px solid #28425e;
            border-radius: 8px;
            overflow: hidden;
            position: relative;
            min-height: 230px;
        }

        .image-box img {
            width: 100%;
            height: 100%;
            object-fit: cover;
            display: block;
        }

        .image-label {
            position: absolute;
            top: 10px;
            left: 10px;
            background: #07111f;
            border: 1px solid #28425e;
            border-radius: 6px;
            padding: 6px 10px;
            color: #ffffff;
            font-size: 12px;
            font-weight: bold;
        }

        .info-card {
            background: #0b1828;
            border: 1px solid #1e344f;
            border-radius: 10px;
            padding: 14px;
        }

        .info-title {
            font-weight: bold;
            margin-bottom: 14px;
        }

        .info-row {
            display: flex;
            justify-content: space-between;
            gap: 12px;
            border-bottom: 1px solid #182b42;
            padding: 10px 0;
            font-size: 14px;
        }

        .info-row:last-child {
            border-bottom: none;
        }

        .text-muted {
            color: #a8b6c8;
        }

        .text-green {
            color: #31d06b;
            font-weight: bold;
        }

        .text-red {
            color: #ff6b6b;
            font-weight: bold;
        }

        .badge {
            border-radius: 6px;
            padding: 5px 10px;
            font-size: 12px;
            font-weight: bold;
            display: inline-block;
        }

        .badge-green {
            background: #123d26;
            color: #31d06b;
            border: 1px solid #1f8b48;
        }

        .badge-red {
            background: #49201f;
            color: #ff6b6b;
            border: 1px solid #a92b2b;
        }

        .empty-image {
            height: 100%;
            min-height: 160px;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #7f91a7;
        }

        .slot-grid {
            display: grid;
            grid-template-columns: repeat(6, 1fr);
            gap: 10px;
        }

        .slot {
            padding: 12px;
            border-radius: 8px;
            text-align: center;
            font-weight: bold;
        }

        .slot-available {
            background: #123d26;
            color: #31d06b;
            border: 1px solid #1f8b48;
        }

        .slot-occupied {
            background: #49201f;
            color: #ff6b6b;
            border: 1px solid #a92b2b;
        }

        .table-card {
            padding: 16px;
            margin-top: 16px;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            font-size: 14px;
        }

        th {
            background: #17283c;
            color: #dce7f5;
            padding: 12px;
            text-align: left;
        }

        td {
            padding: 11px 12px;
            border-bottom: 1px solid #1e344f;
            color: #d8e3f0;
        }

        tr:hover td {
            background: #132236;
        }

        @media screen and (max-width: 1100px) {
            .kpi-grid,
            .device-grid,
            .main-grid,
            .capture-layout {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>

<body>
<div class="page">

    <div class="header">
        <div class="brand">
            <span>FPT Education</span>
            FPT UNIVERSITY
        </div>

        <div class="title">Smart Parking Dashboard</div>

        <div class="system-status">
            <div class="status-pill online">System Online</div>
            <div class="status-pill">
                <fmt:formatDate value="<%= new Date() %>" pattern="dd/MM/yyyy HH:mm"/>
            </div>
        </div>
    </div>

    <div class="kpi-grid">
        <div class="card kpi-card">
            <div class="kpi-title">Vehicles Inside</div>
            <div class="kpi-number">
                <c:choose>
                    <c:when test="${not empty vehiclesInside}">${vehiclesInside}</c:when>
                    <c:otherwise>0</c:otherwise>
                </c:choose>
            </div>
            <div class="kpi-note">Current active parking count</div>
        </div>

        <div class="card kpi-card">
            <div class="kpi-title">Entries Today</div>
            <div class="kpi-number">
                <c:choose>
                    <c:when test="${not empty entriesToday}">${entriesToday}</c:when>
                    <c:otherwise>0</c:otherwise>
                </c:choose>
            </div>
            <div class="kpi-note">Entry events recorded today</div>
        </div>

        <div class="card kpi-card">
            <div class="kpi-title">Exits Today</div>
            <div class="kpi-number">
                <c:choose>
                    <c:when test="${not empty exitsToday}">${exitsToday}</c:when>
                    <c:otherwise>0</c:otherwise>
                </c:choose>
            </div>
            <div class="kpi-note">Exit events recorded today</div>
        </div>

        <div class="card kpi-card">
            <div class="kpi-title">Gate Status</div>
            <div class="kpi-number text-green">
                <c:choose>
                    <c:when test="${not empty gateStatus}">${gateStatus}</c:when>
                    <c:otherwise>CLOSED</c:otherwise>
                </c:choose>
            </div>
            <div class="kpi-note">Controlled by Master Arduino</div>
        </div>
    </div>

    <div class="device-grid">
        <div class="card device-card">
            <div class="device-name">Entry Camera</div>
            <div class="device-state">
                <c:choose>
                    <c:when test="${not empty entryCameraStatus}">${entryCameraStatus}</c:when>
                    <c:otherwise>UNKNOWN</c:otherwise>
                </c:choose>
            </div>
        </div>

        <div class="card device-card">
            <div class="device-name">Exit Camera</div>
            <div class="device-state">
                <c:choose>
                    <c:when test="${not empty exitCameraStatus}">${exitCameraStatus}</c:when>
                    <c:otherwise>UNKNOWN</c:otherwise>
                </c:choose>
            </div>
        </div>

        <div class="card device-card">
            <div class="device-name">Entry Sensor</div>
            <div class="device-state">
                <c:choose>
                    <c:when test="${not empty entrySensorStatus}">${entrySensorStatus}</c:when>
                    <c:otherwise>UNKNOWN</c:otherwise>
                </c:choose>
            </div>
        </div>

        <div class="card device-card">
            <div class="device-name">Exit Sensor</div>
            <div class="device-state">
                <c:choose>
                    <c:when test="${not empty exitSensorStatus}">${exitSensorStatus}</c:when>
                    <c:otherwise>UNKNOWN</c:otherwise>
                </c:choose>
            </div>
        </div>
    </div>

    <div class="main-grid">

        <div class="card section">
            <div class="section-title">Latest Entry Capture</div>

            <div class="capture-layout">
                <div class="image-box">
                    <span class="image-label">ENTRY IMAGE</span>
                    <c:choose>
                        <c:when test="${not empty latestEntry and not empty latestEntry.entryImageUrl}">
                            <img src="${pageContext.request.contextPath}/${latestEntry.entryImageUrl}" alt="Latest entry image">
                        </c:when>
                        <c:otherwise>
                            <div class="empty-image">No entry image</div>
                        </c:otherwise>
                    </c:choose>
                </div>

                <div class="info-card">
                    <div class="info-title">Entry Result</div>

                    <div class="info-row">
                        <span class="text-muted">Time</span>
                        <span>
                            <c:if test="${not empty latestEntry}">
                                <fmt:formatDate value="${latestEntry.entryTime}" pattern="dd/MM/yyyy HH:mm"/>
                            </c:if>
                        </span>
                    </div>

                    <div class="info-row">
                        <span class="text-muted">Detected Object</span>
                        <span>
                            <c:choose>
                                <c:when test="${not empty latestEntry.detectedClass}">${latestEntry.detectedClass}</c:when>
                                <c:otherwise>N/A</c:otherwise>
                            </c:choose>
                        </span>
                    </div>

                    <div class="info-row">
                        <span class="text-muted">AI Decision</span>
                        <span>
                            <c:choose>
                                <c:when test="${latestEntry.aiDecision == 'OPEN'}"><span class="badge badge-green">OPEN</span></c:when>
                                <c:when test="${latestEntry.aiDecision == 'CLOSE'}"><span class="badge badge-red">CLOSE</span></c:when>
                                <c:otherwise>N/A</c:otherwise>
                            </c:choose>
                        </span>
                    </div>

                    <div class="info-row">
                        <span class="text-muted">Status</span>
                        <span>
                            <c:choose>
                                <c:when test="${not empty latestEntry.status}">${latestEntry.status}</c:when>
                                <c:otherwise>N/A</c:otherwise>
                            </c:choose>
                        </span>
                    </div>
                </div>
            </div>
        </div>

        <div class="card section">
            <div class="section-title">Latest Exit Capture</div>

            <div class="capture-layout">
                <div class="image-box">
                    <span class="image-label">EXIT IMAGE</span>
                    <c:choose>
                        <c:when test="${not empty latestExit and not empty latestExit.exitImageUrl}">
                            <img src="${pageContext.request.contextPath}/${latestExit.exitImageUrl}" alt="Latest exit image">
                        </c:when>
                        <c:otherwise>
                            <div class="empty-image">No exit image</div>
                        </c:otherwise>
                    </c:choose>
                </div>

                <div class="info-card">
                    <div class="info-title">Exit Result</div>

                    <div class="info-row">
                        <span class="text-muted">Time</span>
                        <span>
                            <c:if test="${not empty latestExit}">
                                <fmt:formatDate value="${latestExit.exitTime}" pattern="dd/MM/yyyy HH:mm"/>
                            </c:if>
                        </span>
                    </div>

                    <div class="info-row">
                        <span class="text-muted">Detected Object</span>
                        <span>
                            <c:choose>
                                <c:when test="${not empty latestExit.detectedClass}">${latestExit.detectedClass}</c:when>
                                <c:otherwise>N/A</c:otherwise>
                            </c:choose>
                        </span>
                    </div>

                    <div class="info-row">
                        <span class="text-muted">AI Decision</span>
                        <span>
                            <c:choose>
                                <c:when test="${latestExit.aiDecision == 'OPEN'}"><span class="badge badge-green">OPEN</span></c:when>
                                <c:when test="${latestExit.aiDecision == 'CLOSE'}"><span class="badge badge-red">CLOSE</span></c:when>
                                <c:otherwise>N/A</c:otherwise>
                            </c:choose>
                        </span>
                    </div>

                    <div class="info-row">
                        <span class="text-muted">Status</span>
                        <span>
                            <c:choose>
                                <c:when test="${not empty latestExit.status}">${latestExit.status}</c:when>
                                <c:otherwise>N/A</c:otherwise>
                            </c:choose>
                        </span>
                    </div>
                </div>
            </div>
        </div>

    </div>

    <div class="card section">
        <div class="section-title">Parking Slot Status</div>

        <div class="slot-grid">
            <c:forEach var="slot" items="${slots}">
                <div class="slot ${slot.status == 'AVAILABLE' ? 'slot-available' : 'slot-occupied'}">
                    <div>${slot.slotNumber}</div>
                    <div style="font-size: 12px; margin-top: 5px;">${slot.status}</div>
                </div>
            </c:forEach>

            <c:if test="${empty slots}">
                <div class="text-muted">No slot data available.</div>
            </c:if>
        </div>
    </div>

    <div class="card table-card">
        <div class="section-title">Recent Parking Logs</div>

        <table>
            <thead>
            <tr>
                <th>#</th>
                <th>Gate</th>
                <th>Detected Object</th>
                <th>Entry Time</th>
                <th>Exit Time</th>
                <th>AI Decision</th>
                <th>Status</th>
            </tr>
            </thead>

            <tbody>
            <c:forEach var="log" items="${parkingLogs}" varStatus="st">
                <tr>
                    <td>${st.index + 1}</td>
                    <td>${log.gateName}</td>
                    <td>${log.detectedClass}</td>
                    <td><fmt:formatDate value="${log.entryTime}" pattern="dd/MM/yyyy HH:mm"/></td>
                    <td><fmt:formatDate value="${log.exitTime}" pattern="dd/MM/yyyy HH:mm"/></td>
                    <td>
                        <c:choose>
                            <c:when test="${log.aiDecision == 'OPEN'}"><span class="badge badge-green">OPEN</span></c:when>
                            <c:when test="${log.aiDecision == 'CLOSE'}"><span class="badge badge-red">CLOSE</span></c:when>
                            <c:otherwise>${log.aiDecision}</c:otherwise>
                        </c:choose>
                    </td>
                    <td>${log.status}</td>
                </tr>
            </c:forEach>

            <c:if test="${empty parkingLogs}">
                <tr>
                    <td colspan="7">No parking log data available.</td>
                </tr>
            </c:if>
            </tbody>
        </table>
    </div>

</div>
</body>
</html>
