#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";

const projectRoot = path.resolve(process.argv[2] || ".");
const resultPath = path.resolve(process.argv[3] || "");
const failures = [];
const assert = (condition, message) => { if (!condition) failures.push(message); };

try {
  const result = JSON.parse(fs.readFileSync(resultPath, "utf8"));
  const expectedKeys = [
    "name", "description", "languages", "frameworks", "files", "totalFiles",
    "filteredByIgnore", "estimatedComplexity", "importMap",
  ];
  assert(JSON.stringify(Object.keys(result)) === JSON.stringify(expectedKeys), "Top-level fields/order không đúng schema cuối");
  assert(!("scriptCompleted" in result) && !("rawDescription" in result) && !("readmeHead" in result), "Còn field trung gian");
  assert(typeof result.name === "string" && result.name === "elog_driver", "Project name không đúng");
  assert(typeof result.description === "string" && result.description.startsWith("Ứng dụng Flutter"), "Description chưa phải tiếng Việt mong đợi");
  assert(Array.isArray(result.files), "files không phải array");
  assert(result.totalFiles === result.files.length, "totalFiles không khớp files.length");
  assert(Number.isInteger(result.filteredByIgnore) && result.filteredByIgnore >= 0, "filteredByIgnore không hợp lệ");
  assert(["small", "moderate", "large", "very-large"].includes(result.estimatedComplexity), "estimatedComplexity không hợp lệ");

  const allowedCategories = new Set(["code", "config", "docs", "infra", "data", "script", "markup"]);
  const paths = result.files.map((file) => file.path);
  const sortedPaths = [...paths].sort((a, b) => a.localeCompare(b));
  assert(JSON.stringify(paths) === JSON.stringify(sortedPaths), "files chưa sort theo path");
  assert(new Set(paths).size === paths.length, "files có path trùng");

  for (const file of result.files) {
    assert(typeof file.path === "string" && file.path && !file.path.includes("\\"), `Path không chuẩn hóa: ${file.path}`);
    assert(!path.isAbsolute(file.path) && !file.path.startsWith("../"), `Path không project-relative: ${file.path}`);
    assert(fs.existsSync(path.join(projectRoot, ...file.path.split("/"))), `Path không tồn tại: ${file.path}`);
    assert(typeof file.language === "string" && file.language.length > 0, `Language không hợp lệ: ${file.path}`);
    assert(Number.isInteger(file.sizeLines) && file.sizeLines >= 0, `sizeLines không hợp lệ: ${file.path}`);
    assert(allowedCategories.has(file.fileCategory), `fileCategory không hợp lệ: ${file.path}`);
  }

  const fileSet = new Set(paths);
  const importKeys = Object.keys(result.importMap);
  assert(importKeys.length === paths.length && importKeys.every((key) => fileSet.has(key)), "importMap không có đúng một key cho mỗi file");
  for (const file of result.files) {
    const imports = result.importMap[file.path];
    assert(Array.isArray(imports), `Import entry không phải array: ${file.path}`);
    if (!Array.isArray(imports)) continue;
    assert(new Set(imports).size === imports.length, `Import bị trùng: ${file.path}`);
    assert(JSON.stringify(imports) === JSON.stringify([...imports].sort((a, b) => a.localeCompare(b))), `Import chưa sort: ${file.path}`);
    for (const target of imports) assert(fileSet.has(target), `Import target không tồn tại trong inventory: ${file.path} -> ${target}`);
    if (file.fileCategory !== "code") assert(imports.length === 0, `Non-code file có import: ${file.path}`);
  }

  const detectedLanguages = [...new Set(result.files.map((file) => file.language))].sort((a, b) => a.localeCompare(b));
  assert(JSON.stringify(result.languages) === JSON.stringify(detectedLanguages), "languages không khớp inventory hoặc chưa sort");
  assert(result.languages.includes("dart"), "Thiếu Dart trong languages");
  assert(result.frameworks.includes("Flutter"), "Thiếu Flutter trong frameworks");
  assert(fileSet.has("pubspec.yaml") && fileSet.has("lib/main.dart"), "Thiếu manifest hoặc entry point đã xác nhận");

  const expectedComplexity = result.totalFiles <= 30 ? "small"
    : result.totalFiles <= 150 ? "moderate"
      : result.totalFiles <= 500 ? "large" : "very-large";
  assert(result.estimatedComplexity === expectedComplexity, "Complexity không khớp totalFiles");

  const categories = result.files.reduce((counts, file) => {
    counts[file.fileCategory] = (counts[file.fileCategory] || 0) + 1;
    return counts;
  }, {});
  const filesWithImports = Object.values(result.importMap).filter((imports) => imports.length > 0).length;
  if (failures.length) {
    process.stderr.write(`${failures.length} validation failure(s):\n- ${failures.join("\n- ")}\n`);
    process.exit(1);
  }
  process.stdout.write(`${JSON.stringify({
    valid: true,
    name: result.name,
    totalFiles: result.totalFiles,
    categories,
    languages: result.languages,
    frameworks: result.frameworks,
    estimatedComplexity: result.estimatedComplexity,
    filteredByIgnore: result.filteredByIgnore,
    filesWithResolvedImports: filesWithImports,
  }, null, 2)}\n`);
  process.exit(0);
} catch (error) {
  process.stderr.write(`${error instanceof Error ? error.stack : String(error)}\n`);
  process.exit(1);
}
