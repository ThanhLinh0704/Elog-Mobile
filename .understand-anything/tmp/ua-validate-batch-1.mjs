#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";

const root = path.resolve(process.argv[2]);
const input = JSON.parse(fs.readFileSync(path.resolve(process.argv[3]), "utf8"));
const extraction = JSON.parse(fs.readFileSync(path.resolve(process.argv[4]), "utf8"));
const graph = JSON.parse(fs.readFileSync(path.resolve(process.argv[5]), "utf8"));
const errors = [];
const check = (condition, message) => { if (!condition) errors.push(message); };

const nodeTypes = new Set(["file", "function", "class", "config", "document", "service", "table", "endpoint", "pipeline", "schema", "resource"]);
const complexities = new Set(["simple", "moderate", "complex"]);
const edgeWeights = new Map([
  ["contains", 1.0], ["imports", 0.7], ["calls", 0.8], ["inherits", 0.9],
  ["implements", 0.9], ["exports", 0.8], ["depends_on", 0.6], ["tested_by", 0.5],
  ["configures", 0.6], ["documents", 0.5], ["deploys", 0.7], ["migrates", 0.7],
  ["triggers", 0.6], ["defines_schema", 0.8], ["serves", 0.7], ["provisions", 0.7],
  ["routes", 0.6], ["related", 0.5],
]);

check(extraction.scriptCompleted === true, "Extractor chưa hoàn tất");
check(extraction.filesAnalyzed === 25, `Extractor filesAnalyzed=${extraction.filesAnalyzed}, cần 25`);
check(Array.isArray(extraction.filesSkipped) && extraction.filesSkipped.length === 0, "Extractor có file bị skip");
check(extraction.results.length === 25, "Extractor results không đủ 25");
check(graph && Array.isArray(graph.nodes) && Array.isArray(graph.edges), "Graph phải có nodes và edges arrays");

const nodeIds = new Set();
for (const node of graph.nodes) {
  check(typeof node.id === "string" && node.id.length > 0, "Node thiếu id");
  check(!nodeIds.has(node.id), `Node ID trùng: ${node.id}`);
  nodeIds.add(node.id);
  check(nodeTypes.has(node.type), `Node type không hợp lệ: ${node.id}`);
  check(typeof node.name === "string" && node.name.length > 0, `Node thiếu name: ${node.id}`);
  check(typeof node.summary === "string" && node.summary.length > 0, `Node thiếu summary: ${node.id}`);
  check(Array.isArray(node.tags) && node.tags.length >= 3 && node.tags.length <= 5, `Node phải có 3-5 tags: ${node.id}`);
  check(complexities.has(node.complexity), `Complexity không hợp lệ: ${node.id}`);
  if (["file", "config", "document", "service", "pipeline", "schema", "resource"].includes(node.type)) {
    check(typeof node.filePath === "string" && fs.existsSync(path.join(root, ...node.filePath.split("/"))), `File node path không tồn tại: ${node.id}`);
  }
  if (node.type === "function" || node.type === "class") {
    check(Array.isArray(node.lineRange) && node.lineRange.length === 2 && node.lineRange[0] <= node.lineRange[1], `Subnode thiếu lineRange: ${node.id}`);
  }
}

const expectedFileIds = new Map(input.batchFiles.map((file) => {
  const prefix = file.fileCategory === "docs" ? "document" : file.fileCategory === "config" ? "config" : "file";
  return [file.path, `${prefix}:${file.path}`];
}));
for (const [filePath, id] of expectedFileIds) check(nodeIds.has(id), `Thiếu file-level node: ${filePath}`);
const fileLevelNodes = graph.nodes.filter((node) => expectedFileIds.has(node.filePath) && expectedFileIds.get(node.filePath) === node.id);
check(fileLevelNodes.length === 25, `Có ${fileLevelNodes.length} file-level nodes, cần 25`);

const expectedManualNodes = [
  "class:android/app/src/main/kotlin/com/elog/elog_driver/MainActivity.kt:MainActivity",
  "function:integration_test/app_test.dart:main",
  "function:lib/core/constants.dart:kBaseUrl",
  "class:lib/core/error/exceptions.dart:ApiBusinessException",
  "function:lib/core/error/exceptions.dart:ApiBusinessException.userMessage",
  "class:lib/core/error/exceptions.dart:NetworkException",
  "function:lib/core/network/dio_client.dart:createDioClient",
  "function:lib/core/network/dio_client.dart:parseDioError",
  "class:lib/core/storage/secure_storage_service.dart:SecureStorageService",
  "function:lib/core/storage/secure_storage_service.dart:saveTokens"
];
for (const id of expectedManualNodes) check(nodeIds.has(id), `Thiếu manual Dart/Kotlin subnode: ${id}`);

const knownProjectIds = new Set(nodeIds);
for (const targets of Object.values(input.batchImportData)) {
  for (const target of targets) knownProjectIds.add(`file:${target}`);
}
const edgeKeys = new Set();
for (const edge of graph.edges) {
  const key = `${edge.source}\0${edge.target}\0${edge.type}`;
  check(!edgeKeys.has(key), `Edge trùng: ${edge.source} -> ${edge.target} (${edge.type})`);
  edgeKeys.add(key);
  check(edgeWeights.has(edge.type), `Edge type không hợp lệ: ${edge.type}`);
  check(edge.direction === "forward", `Edge direction không phải forward: ${key}`);
  check(edge.weight === edgeWeights.get(edge.type), `Sai weight cho edge ${key}`);
  check(edge.source !== edge.target, `Self edge: ${key}`);
  check(knownProjectIds.has(edge.source), `Source không tồn tại/không được biết: ${edge.source}`);
  check(knownProjectIds.has(edge.target), `Target không tồn tại/không được biết: ${edge.target}`);
}

const expectedImports = [];
for (const file of input.batchFiles.filter((entry) => entry.fileCategory === "code")) {
  for (const target of input.batchImportData[file.path] || []) expectedImports.push(`file:${file.path}\0file:${target}\0imports`);
}
const actualImports = graph.edges.filter((edge) => edge.type === "imports").map((edge) => `${edge.source}\0${edge.target}\0imports`);
check(expectedImports.length === 8, `Input có ${expectedImports.length} imports thay vì 8`);
check(actualImports.length === expectedImports.length, `Output có ${actualImports.length} imports, cần ${expectedImports.length}`);
for (const expected of expectedImports) check(actualImports.includes(expected), `Thiếu import edge: ${expected.replaceAll("\0", " -> ")}`);

if (errors.length) {
  process.stderr.write(`${errors.length} validation failure(s):\n- ${errors.join("\n- ")}\n`);
  process.exit(1);
}

const nodeCounts = graph.nodes.reduce((counts, node) => {
  counts[node.type] = (counts[node.type] || 0) + 1;
  return counts;
}, {});
const edgeCounts = graph.edges.reduce((counts, edge) => {
  counts[edge.type] = (counts[edge.type] || 0) + 1;
  return counts;
}, {});
process.stdout.write(`${JSON.stringify({
  valid: true,
  filesAnalyzed: extraction.filesAnalyzed,
  skipped: extraction.filesSkipped,
  totalNodes: graph.nodes.length,
  nodeCounts,
  totalEdges: graph.edges.length,
  edgeCounts,
  importEdgesExpected: expectedImports.length,
  importEdgesActual: actualImports.length
}, null, 2)}\n`);
