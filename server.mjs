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

const seedData = {
  customers: [],
  products: [],
  services: [],
  vendors: []
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

const readWorkbook = () => {
  ensureWorkbook();
  return XLSX.readFile(dbPath, { cellDates: false });
};

const readTable = (tableName, workbook = readWorkbook()) => {
  const config = tableConfig[tableName];
  if (!config) return null;
  const sheet = workbook.Sheets[tableName];
  if (!sheet) return [];
  return XLSX.utils.sheet_to_json(sheet, { defval: "" }).map(normalizeRecord);
};

const readAllTables = () => {
  const workbook = readWorkbook();
  return Object.fromEntries(Object.keys(tableConfig).map(tableName => [tableName, readTable(tableName, workbook)]));
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

    if (request.method === "GET" && url.pathname === "/api/health") {
      sendJson(response, 200, { ok: true, workbook: dbPath });
      return;
    }

    if (request.method === "GET" && url.pathname === "/api/mock-db") {
      sendJson(response, 200, readAllTables());
      return;
    }

    const tableMatch = url.pathname.match(/^\/api\/mock-db\/([a-z]+)$/);
    if (tableMatch) {
      const tableName = tableMatch[1];
      if (!tableConfig[tableName]) return sendJson(response, 404, { error: "Unknown table" });
      if (request.method === "GET") return sendJson(response, 200, readTable(tableName));
      if (request.method === "PUT") {
        const rows = await readBody(request);
        if (!Array.isArray(rows)) return sendJson(response, 400, { error: "Expected an array of records" });
        writeTable(tableName, rows.map(normalizeRecord));
        sendJson(response, 200, { ok: true, table: tableName, count: rows.length });
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
