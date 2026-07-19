import http from "node:http";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import XLSX from "xlsx";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const PORT = Number(process.env.PORT || 4317);
const dbDir = path.join(__dirname, "mock-db");
const dbPath = path.join(dbDir, "erp_mock_database.xlsx");
const htmlPath = path.join(__dirname, "erp_base_layout_shell.html");
const hrmsCoreHtmlPath = path.resolve(__dirname, "..", "indipet_hrms", "hrms_dashboard_nav_visual.html");
const hrmsDbDir = path.resolve(__dirname, "..", "indipet_hrms", "mock-db");
const hrmsDbPath = path.join(hrmsDbDir, "hrms_mock_database.xlsx");

const listFields = new Set([
  "tags",
  "animals",
  "flags",
  "designations",
  "supplyCategories"
]);

const booleanFields = new Set([
  "online",
  "appointment",
  "hasDefaultAddress"
]);

const numberFields = new Set([
  "bills",
  "netSales",
  "activePets",
  "totalPets",
  "progress",
  "packQty",
  "mrp",
  "selling",
  "duration",
  "consumables"
]);

const tableConfig = {
  parent_entities: {
    key: "entity_code",
    headers: ["entity_code", "legal_name", "entity_type", "entity_role", "gstin", "gst_type", "pan_number", "cin_number", "phone", "email", "address_line1", "address_line2", "city", "pincode", "state", "country", "commission_on_products", "commission_on_services", "status"]
  },
  customers: {
    key: "code",
    headers: ["code", "name", "phone", "classification", "tags", "bills", "netSales", "activePets", "totalPets", "progress", "status", "location", "source", "joined", "lastActivity", "hasDefaultAddress"]
  },
  products: {
    key: "sku",
    headers: ["sku", "product", "brand", "subbrand", "barcode", "variation", "stockUnit", "packQty", "uom", "category", "subcategory", "animals", "tags", "mrp", "selling", "online", "flags", "status", "structure", "attribute", "hsn", "gst", "created", "updated", "lastSale"]
  },
  services: {
    key: "id",
    headers: ["id", "name", "category", "subcategory", "department", "designations", "animals", "appointment", "duration", "mrp", "selling", "pricing", "consumables", "online", "flags", "status", "tags", "sac", "gst", "created", "lastPerformed"]
  },
  vendors: {
    key: "id",
    headers: ["id", "name", "legalName", "contact", "phone", "type", "supplyNature", "supplyCategories", "gstStatus", "gstin", "paymentTerms", "paymentStart", "status", "location", "tags", "created", "flags"]
  }
};

const hrmsJsonFields = new Set(["details", "access", "record", "services", "deliveryZones", "shifts", "operatingHoursRecords", "cells"]);
const hrmsBooleanFields = new Set(["gstRegistered", "keyholderEligible"]);
const hrmsNumberFields = new Set(["readiness"]);

const hrmsTableConfig = {
  entities: {
    key: "entity_id",
    headers: ["entity_id", "legal_name", "entity_type", "entity_role", "status", "details", "access"]
  },
  locations: {
    key: "id",
    headers: ["id", "name", "listName", "parent", "parentCode", "state", "type", "status", "readiness", "readinessLabel", "readinessTone", "officialHours", "operationalHours", "closedDay", "services", "deliveryZones", "shifts", "record", "operatingHoursRecords"]
  },
  employees: {
    key: "employee_id",
    headers: ["employee_id", "employee_name", "location", "designation", "profile_status", "status", "record"]
  },
  attendance: {
    key: "id",
    headers: ["id", "name", "initials", "location", "shift", "checkIn", "checkOut", "status"]
  },
  keyholders: {
    key: "id",
    headers: ["id", "name", "locationId", "status", "keyholderEligible"]
  },
  operating_contexts: {
    key: "context_id",
    headers: ["context_id", "primary_entity_id", "active_entity_id", "entity_name", "admin_name", "admin_phone", "status"]
  },
  module_rows: {
    key: "row_id",
    headers: ["row_id", "pageKey", "cells"]
  },
  country_masters: {
    key: "country_code",
    headers: ["country_code", "country_name", "iso2", "phone_code", "default_country", "status"]
  },
  state_masters: {
    key: "state_code",
    headers: ["state_code", "state_name", "gst_state_code", "country", "status"]
  },
  pincode_masters: {
    key: "pincode",
    headers: ["pincode", "city", "state_name", "gst_state_code", "country", "status"]
  },
  city_masters: {
    key: "city_id",
    headers: ["city_id", "city", "district", "state_name", "gst_state_code", "country", "status"]
  }
};

const seedData = {
  parent_entities: [],
  customers: [],
  products: [],
  services: [],
  vendors: []
};

const hrmsSeedData = Object.fromEntries(Object.keys(hrmsTableConfig).map(tableName => [tableName, []]));

const normalizeEntityRole = value => {
  const role = String(value || "").trim().toLowerCase();
  if (role === "primary") return "Primary";
  if (role === "franchisee" || role === "franchaisee") return "Franchisee";
  return String(value || "").trim();
};

const normalizeParentEntityRows = rows => rows.map(row => ({
  ...row,
  entity_role: normalizeEntityRole(row.entity_role)
}));

const validateParentEntityRows = rows => {
  const invalidRole = rows.find(row => !["Primary", "Franchisee"].includes(row.entity_role));
  if (invalidRole) {
    return "Entity Role must be either Primary or Franchisee.";
  }

  const primaryRows = rows.filter(row => row.entity_role === "Primary");
  if (primaryRows.length > 1) {
    return "Only one Primary Entity can exist in ERP. Add Franchisee entities after the Primary Entity.";
  }

  if (rows.length && primaryRows.length === 0) {
    return "Create the Primary Entity first. After that, only Franchisee entities can be added.";
  }

  return "";
};

const normalizeHrmsEntityRole = value => {
  const role = String(value || "").trim().toLowerCase();
  if (role === "primary") return "Primary";
  if (role === "franchisee" || role === "franchaisee") return "Franchisee";
  return "";
};

const hasHrmsEntityIdentity = row => Boolean(
  String(row.entity_id || "").trim()
  || String(row.legal_name || "").trim()
  || String(row.entity_role || "").trim()
);

const validateHrmsEntityRows = rows => {
  const normalizedRows = rows.map(row => ({
    ...row,
    entity_role: normalizeHrmsEntityRole(row.entity_role)
  }));
  const entityRows = normalizedRows.filter(hasHrmsEntityIdentity);
  const invalidRole = entityRows.find(row => !row.entity_role);
  if (invalidRole) return { ok: false, error: "Entity Role must be either Primary or Franchisee." };

  const primaryRows = entityRows.filter(row => row.entity_role === "Primary");
  if (primaryRows.length > 1) return { ok: false, error: "Only one Primary Entity can exist in ERP Core." };
  if (entityRows.length && primaryRows.length === 0) return { ok: false, error: "Create the Primary Entity first. Franchisee entities can be added after the Primary Entity exists." };

  return { ok: true, rows: normalizedRows };
};

const serializeRecord = (record, headers) => Object.fromEntries(headers.map(header => {
  const value = record[header];
  if (Array.isArray(value)) return [header, JSON.stringify(value)];
  if (typeof value === "boolean") return [header, value ? "TRUE" : "FALSE"];
  return [header, value ?? ""];
}));

const normalizeRecord = record => Object.fromEntries(Object.entries(record).map(([key, value]) => {
  if (listFields.has(key)) {
    if (Array.isArray(value)) return [key, value];
    const text = String(value || "").trim();
    if (!text) return [key, []];
    if (text.startsWith("[")) {
      try { return [key, JSON.parse(text)]; } catch {}
    }
    return [key, text.split(",").map(item => item.trim()).filter(Boolean)];
  }
  if (booleanFields.has(key)) return [key, value === true || String(value).toLowerCase() === "true" || String(value).toLowerCase() === "yes"];
  if (numberFields.has(key)) {
    const number = Number(value);
    return [key, Number.isFinite(number) ? number : 0];
  }
  return [key, value ?? ""];
}));

const serializeHrmsRecord = (record, headers) => Object.fromEntries(headers.map(header => {
  const value = record[header];
  if (Array.isArray(value) || (value && typeof value === "object")) return [header, JSON.stringify(value)];
  if (typeof value === "boolean") return [header, value ? "TRUE" : "FALSE"];
  return [header, value ?? ""];
}));

const normalizeHrmsRecord = record => Object.fromEntries(Object.entries(record).map(([key, value]) => {
  if (hrmsJsonFields.has(key)) {
    if (!value) return [key, key === "cells" ? [] : {}];
    if (typeof value !== "string") return [key, value];
    try { return [key, JSON.parse(value)]; } catch { return [key, value]; }
  }
  if (hrmsBooleanFields.has(key)) {
    const text = String(value).toLowerCase();
    return [key, value === true || text === "true" || text === "yes" || text === "1"];
  }
  if (hrmsNumberFields.has(key)) {
    if (value === "" || value === null || value === undefined) return [key, 0];
    const number = Number(value);
    return [key, Number.isFinite(number) ? number : 0];
  }
  return [key, value ?? ""];
}));

const ensureWorkbook = () => {
  fs.mkdirSync(dbDir, { recursive: true });
  if (fs.existsSync(dbPath)) return;
  const workbook = XLSX.utils.book_new();
  for (const [tableName, config] of Object.entries(tableConfig)) {
    const rows = seedData[tableName].map(record => serializeRecord(record, config.headers));
    const sheet = XLSX.utils.json_to_sheet(rows, { header: config.headers });
    XLSX.utils.book_append_sheet(workbook, sheet, tableName);
  }
  XLSX.writeFile(workbook, dbPath);
};

const ensureHrmsWorkbook = () => {
  fs.mkdirSync(hrmsDbDir, { recursive: true });
  if (fs.existsSync(hrmsDbPath)) return;
  const workbook = XLSX.utils.book_new();
  for (const [tableName, config] of Object.entries(hrmsTableConfig)) {
    const rows = hrmsSeedData[tableName].map(record => serializeHrmsRecord(record, config.headers));
    const sheet = XLSX.utils.json_to_sheet(rows, { header: config.headers });
    XLSX.utils.book_append_sheet(workbook, sheet, tableName);
  }
  XLSX.writeFile(workbook, hrmsDbPath);
};

const readWorkbook = () => {
  ensureWorkbook();
  return XLSX.readFile(dbPath, { cellDates: false });
};

const readHrmsWorkbook = () => {
  ensureHrmsWorkbook();
  return XLSX.readFile(hrmsDbPath, { cellDates: false });
};

const readTable = (tableName, workbook = readWorkbook()) => {
  const config = tableConfig[tableName];
  if (!config) return null;
  const sheet = workbook.Sheets[tableName];
  if (!sheet) return [];
  return XLSX.utils.sheet_to_json(sheet, { defval: "" }).map(normalizeRecord);
};

const readHrmsTable = (tableName, workbook = readHrmsWorkbook()) => {
  const config = hrmsTableConfig[tableName];
  if (!config) return null;
  const sheet = workbook.Sheets[tableName];
  if (!sheet) return [];
  return XLSX.utils.sheet_to_json(sheet, { defval: "" }).map(normalizeHrmsRecord);
};

const readAllTables = () => {
  const workbook = readWorkbook();
  return Object.fromEntries(Object.keys(tableConfig).map(tableName => [tableName, readTable(tableName, workbook)]));
};

const readAllHrmsTables = () => {
  const workbook = readHrmsWorkbook();
  return Object.fromEntries(Object.keys(hrmsTableConfig).map(tableName => [tableName, readHrmsTable(tableName, workbook)]));
};

const writeTable = (tableName, rows) => {
  const config = tableConfig[tableName];
  if (!config || !Array.isArray(rows)) return false;
  const workbook = readWorkbook();
  workbook.Sheets[tableName] = XLSX.utils.json_to_sheet(rows.map(record => serializeRecord(record, config.headers)), { header: config.headers });
  if (!workbook.SheetNames.includes(tableName)) workbook.SheetNames.push(tableName);
  XLSX.writeFile(workbook, dbPath);
  return true;
};

const writeHrmsTable = (tableName, rows) => {
  const config = hrmsTableConfig[tableName];
  if (!config || !Array.isArray(rows)) return false;
  const workbook = readHrmsWorkbook();
  workbook.Sheets[tableName] = XLSX.utils.json_to_sheet(rows.map(record => serializeHrmsRecord(record, config.headers)), { header: config.headers });
  if (!workbook.SheetNames.includes(tableName)) workbook.SheetNames.push(tableName);
  XLSX.writeFile(workbook, hrmsDbPath);
  return true;
};

const sendJson = (response, statusCode, payload) => {
  response.writeHead(statusCode, {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type",
    "Access-Control-Allow-Methods": "GET,PUT,OPTIONS"
  });
  response.end(JSON.stringify(payload));
};

const readBody = request => new Promise((resolve, reject) => {
  const chunks = [];
  request.on("data", chunk => chunks.push(chunk));
  request.on("end", () => {
    try {
      const text = Buffer.concat(chunks).toString("utf8");
      resolve(text ? JSON.parse(text) : null);
    } catch (error) {
      reject(error);
    }
  });
  request.on("error", reject);
});

ensureWorkbook();

if (process.argv.includes("--init")) {
  console.log(`Mock Excel database ready: ${dbPath}`);
  process.exit(0);
}

http.createServer(async (request, response) => {
  const url = new URL(request.url || "/", `http://${request.headers.host || `localhost:${PORT}`}`);
  if (request.method === "OPTIONS") return sendJson(response, 204, {});

  try {
    if (request.method === "GET" && (url.pathname === "/" || url.pathname === "/erp_base_layout_shell.html")) {
      response.writeHead(200, { "Content-Type": "text/html; charset=utf-8" });
      response.end(fs.readFileSync(htmlPath, "utf8"));
      return;
    }

    if (request.method === "GET" && url.pathname === "/erp-core/hrms") {
      response.writeHead(200, { "Content-Type": "text/html; charset=utf-8" });
      response.end(fs.readFileSync(hrmsCoreHtmlPath, "utf8"));
      return;
    }

    if (request.method === "GET" && url.pathname === "/erp-core/hrms-api") {
      sendJson(response, 200, readAllHrmsTables());
      return;
    }

    const hrmsTableMatch = url.pathname.match(/^\/erp-core\/hrms-api\/([a-z_]+)$/);
    if (hrmsTableMatch) {
      const tableName = hrmsTableMatch[1];
      if (!hrmsTableConfig[tableName]) return sendJson(response, 404, { error: "Unknown HRMS table" });
      if (request.method === "GET") return sendJson(response, 200, readHrmsTable(tableName));
      if (request.method === "PUT") {
        const rows = await readBody(request);
        if (!Array.isArray(rows)) return sendJson(response, 400, { error: "Expected an array of records" });
        let nextRows = rows.map(normalizeHrmsRecord);
        if (tableName === "entities") {
          const validation = validateHrmsEntityRows(nextRows);
          if (!validation.ok) return sendJson(response, 409, { error: validation.error });
          nextRows = validation.rows;
        }
        writeHrmsTable(tableName, nextRows);
        sendJson(response, 200, { ok: true, table: tableName, count: nextRows.length });
        return;
      }
    }

    if (request.method === "GET" && url.pathname === "/api/health") {
      sendJson(response, 200, { ok: true, workbook: dbPath });
      return;
    }

    if (request.method === "GET" && url.pathname === "/api/mock-db") {
      sendJson(response, 200, readAllTables());
      return;
    }

    const tableMatch = url.pathname.match(/^\/api\/mock-db\/([a-z_]+)$/);
    if (tableMatch) {
      const tableName = tableMatch[1];
      if (!tableConfig[tableName]) return sendJson(response, 404, { error: "Unknown table" });
      if (request.method === "GET") return sendJson(response, 200, readTable(tableName));
      if (request.method === "PUT") {
        const rows = await readBody(request);
        if (!Array.isArray(rows)) return sendJson(response, 400, { error: "Expected an array of records" });
        let normalizedRows = rows.map(normalizeRecord);
        if (tableName === "parent_entities") {
          normalizedRows = normalizeParentEntityRows(normalizedRows);
          const validationError = validateParentEntityRows(normalizedRows);
          if (validationError) return sendJson(response, 409, { error: validationError });
        }
        writeTable(tableName, normalizedRows);
        sendJson(response, 200, { ok: true, table: tableName, count: normalizedRows.length });
        return;
      }
    }

    sendJson(response, 404, { error: "Not found" });
  } catch (error) {
    sendJson(response, 500, { error: error.message });
  }
}).listen(PORT, () => {
  console.log(`Indipet ERP mock server running at http://localhost:${PORT}`);
  console.log(`Excel database: ${dbPath}`);
});
