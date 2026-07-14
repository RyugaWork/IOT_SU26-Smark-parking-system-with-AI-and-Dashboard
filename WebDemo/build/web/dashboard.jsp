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
            margin-bottom: 22px;
        }

        .brand {
            font-weight: bold;
            color: #ff7a1a;
            line-height: 1.3;
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
        }

        .online {
            color: #31d06b;
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
            display: flex;
            align-items: center;
            gap: 16px;
        }

        .icon-box {
            width: 54px;
            height: 54px;
            border-radius: 14px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 26px;
            font-weight: bold;
        }

        .blue {
            background: #174ea6;
        }

        .green {
            background: #14783e;
        }

        .orange {
            background: #d88412;
        }

        .purple {
            background: #6d45bd;
        }

        .kpi-title {
            color: #b9c7d8;
            font-size: 14px;
        }

        .kpi-number {
            font-size: 30px;
            font-weight: bold;
            margin-top: 4px;
        }

        .kpi-note {
            color: #93a4b8;
            font-size: 13px;
            margin-top: 4px;
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

        .entry-layout {
            display: grid;
            grid-template-columns: 2fr 1fr;
            gap: 14px;
        }

        .image-box {
            background: #07111f;
            border: 1px solid #28425e;
            border-radius: 8px;
            overflow: hidden;
            position: relative;
            min-height: 210px;
        }

        .image-box img {
            width: 100%;
            height: 100%;
            object-fit: cover;
            display: block;
        }

        .live-badge {
            position: absolute;
            top: 10px;
            left: 10px;
            background: #07111f;
            border-radius: 6px;
            padding: 6px 10px;
            color: #ffffff;
            font-size: 12px;
            font-weight: bold;
        }

        .live-dot {
            color: #31d06b;
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

        .badge {
            border-radius: 6px;
            padding: 5px 10px;
            font-size: 12px;
            font-weight: bold;
        }

        .badge-green {
            background: #123d26;
            color: #31d06b;
            border: 1px solid #1f8b48;
        }

        .match-banner {
            background: linear-gradient(90deg, #123d26, #0d512e);
            border: 1px solid #1f8b48;
            color: #31d06b;
            padding: 14px 18px;
            border-radius: 9px;
            font-size: 20px;
            font-weight: bold;
            margin-bottom: 14px;
            display: flex;
            justify-content: space-between;
        }

        .exit-layout {
            display: grid;
            grid-template-columns: 1fr 1fr 1fr;
            gap: 12px;
        }

        .small-image-title {
            font-weight: bold;
            font-size: 14px;
            margin-bottom: 8px;
        }

        .recent-title {
            margin-top: 14px;
            margin-bottom: 10px;
            font-weight: bold;
        }

        .recent-grid {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 12px;
        }

        .recent-card {
            background: #0b1828;
            border: 1px solid #1e344f;
            border-radius: 8px;
            overflow: hidden;
        }

        .recent-card img {
            width: 100%;
            height: 86px;
            object-fit: cover;
            display: block;
        }

        .recent-body {
            padding: 8px 10px;
            font-size: 14px;
        }

        .button-row {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 12px;
            margin-top: 14px;
        }

        .btn {
            padding: 12px;
            border: none;
            border-radius: 7px;
            color: #ffffff;
            cursor: pointer;
            font-weight: bold;
        }

        .btn-open {
            background: #14783e;
        }

        .btn-close {
            background: #16427a;
        }

        .btn-alarm {
            background: #a92b2b;
        }

        .bottom-grid {
            display: grid;
            grid-template-columns: 1fr 1fr 2fr;
            gap: 16px;
        }

        .camera-card {
            padding: 14px;
        }

        .camera-header {
            display: flex;
            justify-content: space-between;
            margin-bottom: 10px;
            font-weight: bold;
        }

        .camera-img {
            height: 180px;
            border-radius: 8px;
            overflow: hidden;
            border: 1px solid #28425e;
        }

        .camera-img img {
            width: 100%;
            height: 100%;
            object-fit: cover;
        }

        .table-card {
            padding: 14px;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            overflow: hidden;
            border-radius: 8px;
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

        .slot-grid {
            display: grid;
            grid-template-columns: repeat(6, 1fr);
            gap: 10px;
            margin-top: 16px;
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

        .empty-image {
            height: 100%;
            min-height: 120px;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #7f91a7;
        }

        @media screen and (max-width: 1100px) {
            .kpi-grid,
            .main-grid,
            .bottom-grid {
                grid-template-columns: 1fr;
            }

            .entry-layout,
            .exit-layout {
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

        <div class="title">Smart Parking System with AI and Dashboard</div>

        <div class="system-status">
            <div class="status-pill online">● System Online</div>
            <div class="status-pill">
                <fmt:formatDate value="<%= new Date() %>" pattern="dd/MM/yyyy HH:mm"/>
            </div>
        </div>
    </div>

    <div class="kpi-grid">
        <div class="card kpi-card">
            <div class="icon-box blue">🚗</div>
            <div>
                <div class="kpi-title">Vehicles Inside</div>
                <div class="kpi-number">${vehiclesInside}</div>
                <div class="kpi-note">Currently in the parking</div>
            </div>
        </div>

        <div class="card kpi-card">
            <div class="icon-box green">↪</div>
            <div>
                <div class="kpi-title">Entries Today</div>
                <div class="kpi-number">${entriesToday}</div>
                <div class="kpi-note">Total entries</div>
            </div>
        </div>

        <div class="card kpi-card">
            <div class="icon-box orange">↩</div>
            <div>
                <div class="kpi-title">Exits Today</div>
                <div class="kpi-number">${exitsToday}</div>
                <div class="kpi-note">Total exits</div>
            </div>
        </div>

        <div class="card kpi-card">
            <div class="icon-box purple">▣</div>
            <div>
                <div class="kpi-title">Gate Status</div>
                <div class="kpi-number text-green">${gateStatus}</div>
                <div class="kpi-note">Main gate is open</div>
            </div>
        </div>
    </div>

    <div class="main-grid">

        <div class="card section">
            <div class="section-title">Entry Monitoring</div>

            <div class="entry-layout">
                <div class="image-box">
                    <span class="live-badge"><span class="live-dot">●</span> LIVE</span>

                    <c:choose>
                        <c:when test="${not empty latestEntry and not empty latestEntry.entryImageUrl}">
                            <img src="${pageContext.request.contextPath}/${latestEntry.entryImageUrl}" alt="Entry image">
                        </c:when>
                        <c:otherwise>
                            <div class="empty-image">No entry image</div>
                        </c:otherwise>
                    </c:choose>
                </div>

                <div class="info-card">
                    <div class="info-title">Entry Information</div>

                    <div class="info-row">
                        <span class="text-muted">Time In</span>
                        <span>
                            <c:if test="${not empty latestEntry}">
                                <fmt:formatDate value="${latestEntry.entryTime}" pattern="dd/MM/yyyy HH:mm"/>
                            </c:if>
                        </span>
                    </div>

                    <div class="info-row">
                        <span class="text-muted">Vehicle Type</span>
                        <span>${latestEntry.vehicleType}</span>
                    </div>

                    <div class="info-row">
                        <span class="text-muted">Plate Number</span>
                        <span class="text-green">${latestEntry.licensePlate}</span>
                    </div>

                    <div class="info-row">
                        <span class="text-muted">Detection Status</span>
                        <span class="badge badge-green">MATCH</span>
                    </div>

                    <%-- TODO: Chờ tích hợp AI.
                         Sau này Detection Status sẽ lấy từ kết quả AI nhận diện biển số. --%>
                </div>
            </div>

            <div class="recent-title">Recent Entries</div>

            <div class="recent-grid">
                <c:forEach var="log" items="${parkingLogs}" begin="0" end="2">
                    <div class="recent-card">
                        <c:choose>
                            <c:when test="${not empty log.entryImageUrl}">
                                <img src="${pageContext.request.contextPath}/${log.entryImageUrl}" alt="Recent entry">
                            </c:when>
                            <c:otherwise>
                                <div class="empty-image">No image</div>
                            </c:otherwise>
                        </c:choose>

                        <div class="recent-body">
                            <div>${log.licensePlate}</div>
                            <div class="text-muted">${log.vehicleType}</div>
                        </div>
                    </div>
                </c:forEach>
            </div>

            <div class="button-row">
                <button class="btn btn-open">Open Camera</button>
                <button class="btn btn-close">Close Camera</button>
                <button class="btn btn-alarm">Trigger Alarm</button>
            </div>

            <%-- TODO: Các button trên hiện chỉ là giao diện.
                 Sau này gắn form/action để gọi Servlet điều khiển camera/gate. --%>
        </div>

        <div class="card section">
            <div class="section-title">Exit Monitoring</div>

            <div class="match-banner">
                <span>✓ PLATE MATCH</span>
                <span>Biển số giống nhau</span>
            </div>

            <div class="exit-layout">
                <div class="info-card">
                    <div class="info-title">Exit Information</div>

                    <div class="info-row">
                        <span class="text-muted">Time Out</span>
                        <span>
                            <c:if test="${not empty latestExit}">
                                <fmt:formatDate value="${latestExit.exitTime}" pattern="dd/MM/yyyy HH:mm"/>
                            </c:if>
                        </span>
                    </div>

                    <div class="info-row">
                        <span class="text-muted">Vehicle Type</span>
                        <span>${latestExit.vehicleType}</span>
                    </div>

                    <div class="info-row">
                        <span class="text-muted">Exit Plate</span>
                        <span class="text-green">${latestExit.licensePlate}</span>
                    </div>

                    <div class="info-row">
                        <span class="text-muted">Status</span>
                        <span>${latestExit.status}</span>
                    </div>

                    <%-- TODO: Chờ tích hợp AI.
                         Sau này so sánh biển số vào/ra bằng AI, không hard-code PLATE MATCH. --%>
                </div>

                <div>
                    <div class="small-image-title">Exit Vehicle Image</div>
                    <div class="image-box">
                        <c:choose>
                            <c:when test="${not empty latestExit and not empty latestExit.exitImageUrl}">
                                <img src="${pageContext.request.contextPath}/${latestExit.exitImageUrl}" alt="Exit image">
                            </c:when>
                            <c:otherwise>
                                <div class="empty-image">No exit image</div>
                            </c:otherwise>
                        </c:choose>
                    </div>
                </div>

                <div>
                    <div class="small-image-title">Entry Reference Image</div>
                    <div class="image-box">
                        <c:choose>
                            <c:when test="${not empty latestExit and not empty latestExit.entryImageUrl}">
                                <img src="${pageContext.request.contextPath}/${latestExit.entryImageUrl}" alt="Entry reference image">
                            </c:when>
                            <c:otherwise>
                                <div class="empty-image">No reference image</div>
                            </c:otherwise>
                        </c:choose>
                    </div>
                </div>
            </div>

            <div class="recent-title">Recent Exits</div>

            <div class="recent-grid">
                <c:forEach var="log" items="${completedLogs}" begin="0" end="2">
                    <div class="recent-card">
                        <c:choose>
                            <c:when test="${not empty log.exitImageUrl}">
                                <img src="${pageContext.request.contextPath}/${log.exitImageUrl}" alt="Recent exit">
                            </c:when>
                            <c:otherwise>
                                <div class="empty-image">No image</div>
                            </c:otherwise>
                        </c:choose>

                        <div class="recent-body">
                            <div>${log.licensePlate}</div>
                            <div class="text-muted">${log.vehicleType}</div>
                        </div>
                    </div>
                </c:forEach>
            </div>
        </div>

    </div>

    <div class="bottom-grid">

        <div class="card camera-card">
            <div class="camera-header">
                <span>Camera 1</span>
                <span class="online">● LIVE</span>
            </div>

            <div class="camera-img">
                <c:choose>
                    <c:when test="${not empty latestEntry and not empty latestEntry.entryImageUrl}">
                        <img src="${pageContext.request.contextPath}/${latestEntry.entryImageUrl}" alt="Camera 1">
                    </c:when>
                    <c:otherwise>
                        <div class="empty-image">Camera 1 preview</div>
                    </c:otherwise>
                </c:choose>
            </div>

            <%-- TODO: Chờ tích hợp camera thật từ ESP32-CAM. --%>
        </div>

        <div class="card camera-card">
            <div class="camera-header">
                <span>Camera 2</span>
                <span class="online">● LIVE</span>
            </div>

            <div class="camera-img">
                <c:choose>
                    <c:when test="${not empty latestExit and not empty latestExit.exitImageUrl}">
                        <img src="${pageContext.request.contextPath}/${latestExit.exitImageUrl}" alt="Camera 2">
                    </c:when>
                    <c:otherwise>
                        <div class="empty-image">Camera 2 preview</div>
                    </c:otherwise>
                </c:choose>
            </div>

            <%-- TODO: Chờ tích hợp camera thật từ ESP32-CAM. --%>
        </div>

        <div class="card table-card">
            <div class="section-title">Vehicles Currently Inside (${vehiclesInside})</div>

            <table>
                <thead>
                <tr>
                    <th>#</th>
                    <th>Plate Number</th>
                    <th>Slot</th>
                    <th>Vehicle Type</th>
                    <th>Time In</th>
                    <th>Status</th>
                </tr>
                </thead>

                <tbody>
                <c:forEach var="log" items="${parkedLogs}" varStatus="st">
                    <tr>
                        <td>${st.index + 1}</td>
                        <td>${log.licensePlate}</td>
                        <td>${log.slotNumber}</td>
                        <td>${log.vehicleType}</td>
                        <td>
                            <fmt:formatDate value="${log.entryTime}" pattern="dd/MM/yyyy HH:mm"/>
                        </td>
                        <td>
                            <span class="badge badge-green">${log.status}</span>
                        </td>
                    </tr>
                </c:forEach>

                <c:if test="${empty parkedLogs}">
                    <tr>
                        <td colspan="6">No vehicle currently inside.</td>
                    </tr>
                </c:if>
                </tbody>
            </table>
        </div>

    </div>

    <div class="card table-card" style="margin-top: 16px;">
        <div class="section-title">Parking Slot Status</div>

        <div class="slot-grid">
            <c:forEach var="slot" items="${slots}">
                <div class="slot ${slot.status == 'AVAILABLE' ? 'slot-available' : 'slot-occupied'}">
                    <div>${slot.slotNumber}</div>
                    <div style="font-size: 12px; margin-top: 5px;">${slot.status}</div>
                </div>
            </c:forEach>
        </div>
    </div>

</div>
</body>
</html>