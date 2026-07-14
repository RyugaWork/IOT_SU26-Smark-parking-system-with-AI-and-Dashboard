<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.Date"%>
<%@taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt"%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Smart Parking Dashboard</title>

    <style>
        * {
            box-sizing: border-box;
        }

        body {
            margin: 0;
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
            min-width: 160px;
            color: #ff7a1a;
            font-weight: bold;
            line-height: 1.3;
        }

        .brand span {
            display: block;
            color: #36a3ff;
            font-size: 14px;
        }

        .title {
            flex: 1;
            text-align: center;
            font-size: 28px;
            font-weight: bold;
        }

        .system-status {
            display: flex;
            gap: 12px;
            align-items: center;
        }

        .status-pill {
            padding: 10px 14px;
            border: 1px solid #1e344f;
            border-radius: 10px;
            background: #102033;
            white-space: nowrap;
            font-size: 14px;
        }

        .online {
            color: #31d06b;
            font-weight: bold;
        }

        .offline {
            color: #ff6b6b;
            font-weight: bold;
        }

        .card {
            border: 1px solid #1e344f;
            border-radius: 12px;
            background: #0f1d2d;
            box-shadow: 0 8px 18px rgba(0, 0, 0, 0.25);
        }

        .kpi-grid {
            display: grid;
            grid-template-columns: repeat(4, minmax(0, 1fr));
            gap: 14px;
            margin-bottom: 16px;
        }

        .kpi-card {
            padding: 18px;
        }

        .kpi-title {
            color: #b9c7d8;
            font-size: 14px;
        }

        .kpi-number {
            margin-top: 6px;
            font-size: 30px;
            font-weight: bold;
        }

        .kpi-note {
            margin-top: 6px;
            color: #93a4b8;
            font-size: 13px;
        }

        .device-grid {
            display: grid;
            grid-template-columns: repeat(4, minmax(0, 1fr));
            gap: 14px;
            margin-bottom: 16px;
        }

        .device-card {
            padding: 16px;
        }

        .device-name {
            margin-bottom: 8px;
            color: #b9c7d8;
            font-size: 14px;
        }

        .device-state {
            font-size: 20px;
            font-weight: bold;
        }

        .main-grid {
            display: grid;
            grid-template-columns: repeat(2, minmax(0, 1fr));
            gap: 16px;
            margin-bottom: 16px;
        }

        .section {
            padding: 16px;
        }

        .section-title {
            margin-bottom: 14px;
            font-size: 18px;
            font-weight: bold;
        }

        .capture-layout {
            display: grid;
            grid-template-columns: 1.25fr 1fr;
            gap: 14px;
        }

        .image-box {
            position: relative;
            min-height: 230px;
            overflow: hidden;
            border: 1px solid #28425e;
            border-radius: 8px;
            background: #07111f;
        }

        .image-box img {
            display: block;
            width: 100%;
            height: 230px;
            object-fit: cover;
        }

        .image-label {
            position: absolute;
            z-index: 2;
            top: 10px;
            left: 10px;
            padding: 6px 10px;
            border: 1px solid #28425e;
            border-radius: 6px;
            background: rgba(7, 17, 31, 0.9);
            font-size: 12px;
            font-weight: bold;
        }

        .empty-image {
            display: flex;
            min-height: 230px;
            align-items: center;
            justify-content: center;
            color: #7f91a7;
        }

        .info-card {
            padding: 14px;
            border: 1px solid #1e344f;
            border-radius: 10px;
            background: #0b1828;
        }

        .info-title {
            margin-bottom: 12px;
            font-weight: bold;
        }

        .info-row {
            display: flex;
            justify-content: space-between;
            gap: 12px;
            padding: 10px 0;
            border-bottom: 1px solid #182b42;
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
            display: inline-block;
            padding: 5px 10px;
            border-radius: 6px;
            font-size: 12px;
            font-weight: bold;
        }

        .badge-green {
            border: 1px solid #1f8b48;
            background: #123d26;
            color: #31d06b;
        }

        .badge-red {
            border: 1px solid #a92b2b;
            background: #49201f;
            color: #ff6b6b;
        }

        .badge-gray {
            border: 1px solid #54677d;
            background: #26384c;
            color: #c6d2df;
        }

        .table-card {
            padding: 16px;
        }

        .table-wrap {
            overflow-x: auto;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            font-size: 14px;
        }

        th {
            padding: 12px;
            background: #17283c;
            color: #dce7f5;
            text-align: left;
            white-space: nowrap;
        }

        td {
            padding: 11px 12px;
            border-bottom: 1px solid #1e344f;
            color: #d8e3f0;
        }

        tr:hover td {
            background: #132236;
        }

        .error-box {
            margin-bottom: 16px;
            padding: 12px 14px;
            border: 1px solid #a92b2b;
            border-radius: 8px;
            background: #49201f;
            color: #ffb3b3;
        }

        @media screen and (max-width: 1100px) {
            .kpi-grid,
            .device-grid,
            .main-grid,
            .capture-layout {
                grid-template-columns: 1fr;
            }

            .header {
                align-items: flex-start;
                flex-direction: column;
            }

            .title {
                text-align: left;
            }

            .system-status {
                flex-wrap: wrap;
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
            <c:choose>
                <c:when test="${not empty overview}">
                    <div class="status-pill online">System Data Available</div>
                </c:when>
                <c:otherwise>
                    <div class="status-pill offline">System Data Unavailable</div>
                </c:otherwise>
            </c:choose>

            <div class="status-pill">
                <fmt:formatDate value="<%= new Date() %>" pattern="dd/MM/yyyy HH:mm"/>
            </div>
        </div>
    </div>

    <c:if test="${not empty errorMessage}">
        <div class="error-box">
            <c:out value="${errorMessage}"/>
        </div>
    </c:if>

    <div class="kpi-grid">
        <div class="card kpi-card">
            <div class="kpi-title">Vehicles Inside</div>
            <div class="kpi-number">
                <c:out value="${empty vehiclesInside ? 0 : vehiclesInside}"/>
            </div>
            <div class="kpi-note">Current occupancy count</div>
        </div>

        <div class="card kpi-card">
            <div class="kpi-title">Available Capacity</div>
            <div class="kpi-number">
                <c:out value="${empty availableCapacity ? 0 : availableCapacity}"/>
            </div>
            <div class="kpi-note">
                Capacity:
                <c:out value="${empty capacity ? 0 : capacity}"/>
            </div>
        </div>

        <div class="card kpi-card">
            <div class="kpi-title">Entries Today</div>
            <div class="kpi-number">
                <c:out value="${empty entriesToday ? 0 : entriesToday}"/>
            </div>
            <div class="kpi-note">ENTRY events with OPEN decision</div>
        </div>

        <div class="card kpi-card">
            <div class="kpi-title">Exits Today</div>
            <div class="kpi-number">
                <c:out value="${empty exitsToday ? 0 : exitsToday}"/>
            </div>
            <div class="kpi-note">EXIT events with OPEN decision</div>
        </div>
    </div>

    <div class="device-grid">
        <div class="card device-card">
            <div class="device-name">Entry Gate</div>
            <div class="device-state">
                <c:choose>
                    <c:when test="${entryGateStatus == 'OPEN'}">
                        <span class="text-green">OPEN</span>
                    </c:when>
                    <c:when test="${entryGateStatus == 'ERROR'}">
                        <span class="text-red">ERROR</span>
                    </c:when>
                    <c:otherwise>
                        <c:out value="${empty entryGateStatus ? 'UNKNOWN' : entryGateStatus}"/>
                    </c:otherwise>
                </c:choose>
            </div>
        </div>

        <div class="card device-card">
            <div class="device-name">Exit Gate</div>
            <div class="device-state">
                <c:choose>
                    <c:when test="${exitGateStatus == 'OPEN'}">
                        <span class="text-green">OPEN</span>
                    </c:when>
                    <c:when test="${exitGateStatus == 'ERROR'}">
                        <span class="text-red">ERROR</span>
                    </c:when>
                    <c:otherwise>
                        <c:out value="${empty exitGateStatus ? 'UNKNOWN' : exitGateStatus}"/>
                    </c:otherwise>
                </c:choose>
            </div>
        </div>

        <div class="card device-card">
            <div class="device-name">Entry Camera</div>
            <div class="device-state">
                <c:out value="${empty entryCameraStatus ? 'UNKNOWN' : entryCameraStatus}"/>
            </div>
        </div>

        <div class="card device-card">
            <div class="device-name">Exit Camera</div>
            <div class="device-state">
                <c:out value="${empty exitCameraStatus ? 'UNKNOWN' : exitCameraStatus}"/>
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
                        <c:when test="${not empty latestEntry.annotatedImagePath}">
                            <img src="${pageContext.request.contextPath}/${latestEntry.annotatedImagePath}"
                                 alt="Latest entry image">
                        </c:when>
                        <c:when test="${not empty latestEntry.rawImagePath}">
                            <img src="${pageContext.request.contextPath}/${latestEntry.rawImagePath}"
                                 alt="Latest entry image">
                        </c:when>
                        <c:otherwise>
                            <div class="empty-image">No entry image</div>
                        </c:otherwise>
                    </c:choose>
                </div>

                <div class="info-card">
                    <div class="info-title">Entry Result</div>

                    <div class="info-row">
                        <span class="text-muted">Gate</span>
                        <span><c:out value="${empty latestEntry.gateId ? 'ENTRY_GATE' : latestEntry.gateId}"/></span>
                    </div>

                    <div class="info-row">
                        <span class="text-muted">Time</span>
                        <span>
                            <c:choose>
                                <c:when test="${not empty latestEntry.createdAt}">
                                    <fmt:formatDate value="${latestEntry.createdAt}" pattern="dd/MM/yyyy HH:mm:ss"/>
                                </c:when>
                                <c:otherwise>N/A</c:otherwise>
                            </c:choose>
                        </span>
                    </div>

                    <div class="info-row">
                        <span class="text-muted">Detected Object</span>
                        <span><c:out value="${empty latestEntry.detectedClass ? 'N/A' : latestEntry.detectedClass}"/></span>
                    </div>

                    <div class="info-row">
                        <span class="text-muted">Confidence</span>
                        <span>
                            <c:choose>
                                <c:when test="${not empty latestEntry.confidence}">
                                    <fmt:formatNumber value="${latestEntry.confidence}" minFractionDigits="2" maxFractionDigits="2"/>%
                                </c:when>
                                <c:otherwise>N/A</c:otherwise>
                            </c:choose>
                        </span>
                    </div>

                    <div class="info-row">
                        <span class="text-muted">AI Decision</span>
                        <span>
                            <c:choose>
                                <c:when test="${latestEntry.decision == 'OPEN'}">
                                    <span class="badge badge-green">OPEN</span>
                                </c:when>
                                <c:when test="${latestEntry.decision == 'CLOSE'}">
                                    <span class="badge badge-red">CLOSE</span>
                                </c:when>
                                <c:otherwise>
                                    <span class="badge badge-gray">N/A</span>
                                </c:otherwise>
                            </c:choose>
                        </span>
                    </div>

                    <div class="info-row">
                        <span class="text-muted">Status</span>
                        <span><c:out value="${empty latestEntry.eventStatus ? 'N/A' : latestEntry.eventStatus}"/></span>
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
                        <c:when test="${not empty latestExit.annotatedImagePath}">
                            <img src="${pageContext.request.contextPath}/${latestExit.annotatedImagePath}"
                                 alt="Latest exit image">
                        </c:when>
                        <c:when test="${not empty latestExit.rawImagePath}">
                            <img src="${pageContext.request.contextPath}/${latestExit.rawImagePath}"
                                 alt="Latest exit image">
                        </c:when>
                        <c:otherwise>
                            <div class="empty-image">No exit image</div>
                        </c:otherwise>
                    </c:choose>
                </div>

                <div class="info-card">
                    <div class="info-title">Exit Result</div>

                    <div class="info-row">
                        <span class="text-muted">Gate</span>
                        <span><c:out value="${empty latestExit.gateId ? 'EXIT_GATE' : latestExit.gateId}"/></span>
                    </div>

                    <div class="info-row">
                        <span class="text-muted">Time</span>
                        <span>
                            <c:choose>
                                <c:when test="${not empty latestExit.createdAt}">
                                    <fmt:formatDate value="${latestExit.createdAt}" pattern="dd/MM/yyyy HH:mm:ss"/>
                                </c:when>
                                <c:otherwise>N/A</c:otherwise>
                            </c:choose>
                        </span>
                    </div>

                    <div class="info-row">
                        <span class="text-muted">Detected Object</span>
                        <span><c:out value="${empty latestExit.detectedClass ? 'N/A' : latestExit.detectedClass}"/></span>
                    </div>

                    <div class="info-row">
                        <span class="text-muted">Confidence</span>
                        <span>
                            <c:choose>
                                <c:when test="${not empty latestExit.confidence}">
                                    <fmt:formatNumber value="${latestExit.confidence}" minFractionDigits="2" maxFractionDigits="2"/>%
                                </c:when>
                                <c:otherwise>N/A</c:otherwise>
                            </c:choose>
                        </span>
                    </div>

                    <div class="info-row">
                        <span class="text-muted">AI Decision</span>
                        <span>
                            <c:choose>
                                <c:when test="${latestExit.decision == 'OPEN'}">
                                    <span class="badge badge-green">OPEN</span>
                                </c:when>
                                <c:when test="${latestExit.decision == 'CLOSE'}">
                                    <span class="badge badge-red">CLOSE</span>
                                </c:when>
                                <c:otherwise>
                                    <span class="badge badge-gray">N/A</span>
                                </c:otherwise>
                            </c:choose>
                        </span>
                    </div>

                    <div class="info-row">
                        <span class="text-muted">Status</span>
                        <span><c:out value="${empty latestExit.eventStatus ? 'N/A' : latestExit.eventStatus}"/></span>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <div class="card table-card">
        <div class="section-title">Recent Detection Events</div>

        <div class="table-wrap">
            <table>
                <thead>
                    <tr>
                        <th>#</th>
                        <th>Gate</th>
                        <th>Direction</th>
                        <th>Detected Object</th>
                        <th>Confidence</th>
                        <th>Decision</th>
                        <th>Status</th>
                        <th>Distance</th>
                        <th>Created At</th>
                    </tr>
                </thead>

                <tbody>
                    <c:forEach var="event" items="${recentEvents}" varStatus="st">
                        <tr>
                            <td><c:out value="${st.index + 1}"/></td>
                            <td><c:out value="${event.gateId}"/></td>
                            <td><c:out value="${event.direction}"/></td>
                            <td><c:out value="${empty event.detectedClass ? 'N/A' : event.detectedClass}"/></td>

                            <td>
                                <c:choose>
                                    <c:when test="${not empty event.confidence}">
                                        <fmt:formatNumber value="${event.confidence}" minFractionDigits="2" maxFractionDigits="2"/>%
                                    </c:when>
                                    <c:otherwise>N/A</c:otherwise>
                                </c:choose>
                            </td>

                            <td>
                                <c:choose>
                                    <c:when test="${event.decision == 'OPEN'}">
                                        <span class="badge badge-green">OPEN</span>
                                    </c:when>
                                    <c:when test="${event.decision == 'CLOSE'}">
                                        <span class="badge badge-red">CLOSE</span>
                                    </c:when>
                                    <c:otherwise>
                                        <span class="badge badge-gray">N/A</span>
                                    </c:otherwise>
                                </c:choose>
                            </td>

                            <td><c:out value="${event.eventStatus}"/></td>

                            <td>
                                <c:choose>
                                    <c:when test="${not empty event.distanceCm}">
                                        <fmt:formatNumber value="${event.distanceCm}" minFractionDigits="2" maxFractionDigits="2"/> cm
                                    </c:when>
                                    <c:otherwise>N/A</c:otherwise>
                                </c:choose>
                            </td>

                            <td>
                                <fmt:formatDate value="${event.createdAt}" pattern="dd/MM/yyyy HH:mm:ss"/>
                            </td>
                        </tr>
                    </c:forEach>

                    <c:if test="${empty recentEvents}">
                        <tr>
                            <td colspan="9">No detection event data available.</td>
                        </tr>
                    </c:if>
                </tbody>
            </table>
        </div>
    </div>

</div>
</body>
</html>