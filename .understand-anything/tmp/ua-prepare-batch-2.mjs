#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";

try {
  const planPath = path.resolve(process.argv[2]);
  const outputPath = path.resolve(process.argv[3]);
  const plan = JSON.parse(fs.readFileSync(planPath, "utf8"));
  const batch = plan?.batches?.[1];
  if (!batch || batch.index !== 2) throw new Error("Không tìm thấy batches[1] với index 2");
  if (!Array.isArray(batch.files) || batch.files.length !== 25) throw new Error(`Batch 2 có ${batch.files?.length ?? 0} files, cần 25`);
  const importCount = batch.files.reduce((total, file) => total + (batch.importData?.[file.path]?.length ?? 0), 0);
  if (importCount !== 66) throw new Error(`Batch 2 có ${importCount} imports, cần 66`);
  const input = {
    projectRoot: "D:\\FULearning\\semester 9\\Elog\\Flutter_app\\Elog-Mobile",
    batchFiles: batch.files,
    batchImportData: batch.importData
  };
  fs.mkdirSync(path.dirname(outputPath), { recursive: true });
  fs.writeFileSync(outputPath, `${JSON.stringify(input, null, 2)}\n`, "utf8");
  process.stdout.write(`${JSON.stringify({ files: batch.files.length, imports: importCount })}\n`);
} catch (error) {
  process.stderr.write(`${error instanceof Error ? error.message : String(error)}\n`);
  process.exit(1);
}
