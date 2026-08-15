#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";

const inputPath = process.argv[2];
const outputPath = process.argv[3];

try {
  if (!inputPath || !outputPath) throw new Error("Usage: node ua-finalize-scan.mjs <raw-json> <final-json>");
  const raw = JSON.parse(fs.readFileSync(path.resolve(inputPath), "utf8"));
  if (raw.scriptCompleted !== true) throw new Error("Discovery script chưa hoàn tất thành công");

  const result = {
    name: raw.name,
    description: "Ứng dụng Flutter dành cho tài xế của ELog, kết nối với Spring Boot API để xác thực bằng JWT, quản lý và thực thi chuyến giao hàng theo luồng stop-based hoặc FT-09 order-based, xử lý kết quả giao hàng và ngoại lệ, hoàn tất chuyến, xem lịch sử và bản đồ.",
    languages: raw.languages,
    frameworks: raw.frameworks,
    files: raw.files,
    totalFiles: raw.totalFiles,
    filteredByIgnore: raw.filteredByIgnore,
    estimatedComplexity: raw.estimatedComplexity,
    importMap: raw.importMap,
  };

  fs.mkdirSync(path.dirname(path.resolve(outputPath)), { recursive: true });
  fs.writeFileSync(path.resolve(outputPath), `${JSON.stringify(result, null, 2)}\n`, "utf8");
  process.exit(0);
} catch (error) {
  process.stderr.write(`${error instanceof Error ? error.message : String(error)}\n`);
  process.exit(1);
}
