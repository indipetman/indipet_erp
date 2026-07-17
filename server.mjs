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
  customers: [
    { code: "LG000155", name: "Ananya Ghosh", phone: "98300 14210", classification: "B2C", tags: ["VIP", "In-store", "Grooming"], bills: 18, netSales: 48620, activePets: 2, totalPets: 2, progress: 96, status: "Active", location: "Lake Gardens", source: "Walk-in", joined: "2026-06-03", lastActivity: "2026-06-19", hasDefaultAddress: true },
    { code: "RJ000064", name: "Arjun Kennels", phone: "98310 76218", classification: "B2B", tags: ["Breeder", "Wholesale", "Repeat"], bills: 31, netSales: 184500, activePets: 6, totalPets: 7, progress: 88, status: "Active", location: "Rajarhat", source: "Referral", joined: "2026-05-14", lastActivity: "2026-06-18", hasDefaultAddress: true }
  ],
  products: [
    { product: "Ocean Fish Adult Dry Food", brand: "Whiskas", sku: "WHI-OCF-70G", barcode: "8901003107012", variation: "Standard", stockUnit: "pc", packQty: 70, uom: "g", category: "Food", subcategory: "Dry Food", animals: ["Cat"], tags: ["Daily Care"], mrp: 65, selling: 62, online: true, flags: ["Duplicate"], status: "Active", structure: "Standard", attribute: "", hsn: "23091000", gst: "18", created: "2025-11-14", updated: "2026-06-18", lastSale: "2026-06-20" },
    { product: "Maxi Adult Dry Food", brand: "Royal Canin", sku: "RC-MAX-4KG", barcode: "3182550402220", variation: "Standard", stockUnit: "bag", packQty: 4, uom: "kg", category: "Food", subcategory: "Dry Food", animals: ["Dog"], tags: ["Premium", "Daily Care"], mrp: 3250, selling: 3090, online: true, flags: [], status: "Active", structure: "Standard", attribute: "", hsn: "23091000", gst: "18", created: "2025-08-09", updated: "2026-05-30", lastSale: "2026-06-19" }
  ],
  services: [
    { id: "SRV-GRM-001", name: "Full Grooming", category: "Grooming", subcategory: "Haircut & Styling", department: "Grooming", designations: ["Groomer", "Senior Groomer"], animals: ["Dog", "Cat"], appointment: true, duration: 90, mrp: 1800, selling: 1650, pricing: "Tiered", consumables: 4, online: true, flags: [], status: "Active", tags: ["Popular", "Premium"], sac: "999729", gst: "18", created: "2025-08-12", lastPerformed: "2026-06-21" },
    { id: "SRV-VET-001", name: "General Veterinary Consultation", category: "Veterinary Care", subcategory: "Consultation", department: "Veterinary", designations: ["Veterinarian", "Veterinary Surgeon"], animals: ["Dog", "Cat"], appointment: true, duration: 30, mrp: 700, selling: 700, pricing: "Fixed", consumables: 1, online: true, flags: [], status: "Active", tags: ["Popular"], sac: "999316", gst: "18", created: "2025-07-02", lastPerformed: "2026-06-22" }
  ],
  vendors: [
    { id: "VEN-001", name: "Pawsome Distribution Pvt Ltd", legalName: "Pawsome Distribution Private Limited", contact: "Rohit Sharma", phone: "98300 44210", type: "Distributor", supplyNature: "Product", supplyCategories: ["Food", "Healthcare"], gstStatus: "Registered", gstin: "19AAJCP1234F1Z7", paymentTerms: "30 Days", paymentStart: "Billing Date", status: "Active", location: "Kolkata", tags: ["Preferred", "Credit"], created: "2026-06-04", flags: [] },
    { id: "VEN-003", name: "VetCare Pharma Supplies", legalName: "VetCare Pharma Supplies LLP", contact: "Dr. Arindam Basu", phone: "81001 66220", type: "Supplier", supplyNature: "Consumable", supplyCategories: ["Healthcare", "Medicines"], gstStatus: "Registered", gstin: "19AAVFV9900K1Z5", paymentTerms: "7 Days", paymentStart: "Billing Date", status: "Active", location: "Salt Lake", tags: ["Drug License"], created: "2025-12-12", flags: [] }
  ]
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
