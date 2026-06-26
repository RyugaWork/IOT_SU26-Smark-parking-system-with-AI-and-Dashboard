function formatDate(value) {
    if (!value) return "--";

    const date = new Date(value);
    if (Number.isNaN(date.getTime())) return "--";

    return date.toLocaleString("vi-VN", {
        hour12: false,
        year: "numeric",
        month: "2-digit",
        day: "2-digit",
        hour: "2-digit",
        minute: "2-digit"
    });
}

function text(value, fallback = "--") {
    if (value === null || value === undefined || value === "") {
        return fallback;
    }
    return value;
}

function setText(id, value) {
    const el = document.getElementById(id);
    if (el) el.innerText = value;
}

function setImage(imgId, emptyId, url) {
    const img = document.getElementById(imgId);
    const empty = document.getElementById(emptyId);

    if (!img || !empty) return;

    if (url) {
        img.src = url;
        img.classList.remove("hidden");
        empty.classList.add("hidden");
    } else {
        img.src = "";
        img.classList.add("hidden");
        empty.classList.remove("hidden");
    }
}

function renderRecent(containerId, logs, imageField) {
    const container = document.getElementById(containerId);
    if (!container) return;

    if (!logs || logs.length === 0) {
        container.innerHTML = `<div class="empty-image">No data</div>`;
        return;
    }

    container.innerHTML = logs.map(log => {
        const imageUrl = log[imageField] || "";
        const imageHtml = imageUrl
            ? `<img src="${imageUrl}" alt="Vehicle image">`
            : `<div class="empty-image">No image</div>`;

        return `
            <div class="recent-card">
                ${imageHtml}
                <div class="recent-body">
                    <div>${text(log.license_plate)}</div>
                    <div class="text-muted">${text(log.vehicle_type)}</div>
                </div>
            </div>
        `;
    }).join("");
}

function renderParkedTable(logs) {
    const tbody = document.getElementById("parkedTableBody");
    if (!tbody) return;

    if (!logs || logs.length === 0) {
        tbody.innerHTML = `<tr><td colspan="6">No vehicle currently inside.</td></tr>`;
        return;
    }

    tbody.innerHTML = logs.map((log, index) => `
        <tr>
            <td>${index + 1}</td>
            <td>${text(log.license_plate)}</td>
            <td>${text(log.slot_number)}</td>
            <td>${text(log.vehicle_type)}</td>
            <td>${formatDate(log.entry_time)}</td>
            <td><span class="badge badge-green">${text(log.status)}</span></td>
        </tr>
    `).join("");
}

function renderSlots(slots) {
    const slotGrid = document.getElementById("slotGrid");
    if (!slotGrid) return;

    if (!slots || slots.length === 0) {
        slotGrid.innerHTML = `<div class="empty-image">No slot data</div>`;
        return;
    }

    slotGrid.innerHTML = slots.map(slot => {
        const cssClass = slot.status === "AVAILABLE" ? "slot-available" : "slot-occupied";
        return `
            <div class="slot ${cssClass}">
                <div>${text(slot.slot_number)}</div>
                <div style="font-size: 12px; margin-top: 5px;">${text(slot.status)}</div>
            </div>
        `;
    }).join("");
}

function renderMatchBanner(plateMatch) {
    const banner = document.getElementById("matchBanner");
    const matchText = document.getElementById("matchText");
    const matchNote = document.getElementById("matchNote");

    if (!banner || !matchText || !matchNote) return;

    if (plateMatch) {
        banner.classList.remove("mismatch");
        matchText.innerText = "✓ PLATE MATCH";
        matchNote.innerText = "Biển số giống nhau";
    } else {
        banner.classList.add("mismatch");
        matchText.innerText = "✕ PLATE MISMATCH";
        matchNote.innerText = "Chưa có dữ liệu đối chiếu";
    }
}

async function loadDashboard() {
    try {
        const response = await fetch("/api/dashboard");
        const data = await response.json();

        if (!response.ok) {
            throw new Error(data.detail || "Cannot load dashboard data");
        }

        setText("serverTime", formatDate(data.serverTime));
        setText("vehiclesInside", data.vehiclesInside);
        setText("entriesToday", data.entriesToday);
        setText("exitsToday", data.exitsToday);
        setText("gateStatus", data.gateStatus);
        setText("vehiclesInsideTitle", `Vehicles Currently Inside (${data.vehiclesInside})`);

        const latestEntry = data.latestEntry;
        const latestExit = data.latestExit;

        if (latestEntry) {
            setText("entryTime", formatDate(latestEntry.entry_time));
            setText("entryVehicleType", text(latestEntry.vehicle_type));
            setText("entryPlate", text(latestEntry.license_plate));
            setImage("latestEntryImage", "noEntryImage", latestEntry.entry_image_full_url);
            setImage("camera1Image", "noCamera1", latestEntry.entry_image_full_url);
        }

        if (latestExit) {
            setText("exitTime", formatDate(latestExit.exit_time));
            setText("exitVehicleType", text(latestExit.vehicle_type));
            setText("exitPlate", text(latestExit.license_plate));
            setText("exitStatus", text(latestExit.status));
            setImage("latestExitImage", "noExitImage", latestExit.exit_image_full_url);
            setImage("entryReferenceImage", "noReferenceImage", latestExit.entry_image_full_url);
            setImage("camera2Image", "noCamera2", latestExit.exit_image_full_url);
        }

        renderMatchBanner(data.plateMatch);
        renderRecent("recentEntries", data.recentEntries, "entry_image_full_url");
        renderRecent("recentExits", data.recentExits, "exit_image_full_url");
        renderParkedTable(data.parkedLogs);
        renderSlots(data.slots);

    } catch (error) {
        console.error(error);
        const page = document.querySelector(".page");
        if (page && !document.getElementById("errorBox")) {
            const box = document.createElement("div");
            box.id = "errorBox";
            box.className = "error-box";
            box.innerText = "Cannot connect to FastAPI/SQL Server. Check terminal logs and database connection.";
            page.prepend(box);
        }
    }
}

async function callCommand(url) {
    try {
        const response = await fetch(url, { method: "POST" });
        const result = await response.json();

        if (!response.ok) {
            throw new Error(result.detail || "Command failed");
        }

        alert(result.message || "Command sent");
        await loadDashboard();

    } catch (error) {
        alert(error.message);
    }
}

loadDashboard();
setInterval(loadDashboard, 2000);
