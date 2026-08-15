import fs from 'node:fs';
import path from 'node:path';

const projectRoot = process.cwd();
const planPath = path.join(projectRoot, '.understand-anything/intermediate/batch-plan.json');
const outputPath = path.join(projectRoot, '.understand-anything/tmp/ua-file-analyzer-input-3.json');
const plan = JSON.parse(fs.readFileSync(planPath, 'utf8'));
const batch = plan.batches?.[2];

if (!batch || batch.index !== 3) throw new Error('Không tìm thấy batch 3 tại batches[2]');
if (batch.files.length !== 25) throw new Error(`Batch 3 có ${batch.files.length} files, dự kiến 25`);
const importCount = Object.values(batch.importData).reduce((total, imports) => total + imports.length, 0);
if (importCount !== 42) throw new Error(`Batch 3 có ${importCount} imports, dự kiến 42`);

const input = {
  projectRoot,
  batchFiles: batch.files,
  batchImportData: batch.importData,
};
fs.writeFileSync(outputPath, `${JSON.stringify(input, null, 2)}\n`);
console.log(JSON.stringify({ outputPath, files: batch.files.length, imports: importCount }));
