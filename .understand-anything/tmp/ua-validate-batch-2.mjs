import fs from 'node:fs';
import path from 'node:path';

const root = process.cwd();
const readJson = (relativePath) =>
  JSON.parse(fs.readFileSync(path.join(root, relativePath), 'utf8'));
const fail = (message) => {
  throw new Error(message);
};
const assert = (condition, message) => {
  if (!condition) fail(message);
};
const stableJson = (value) => JSON.stringify(value);
const countBy = (items, key) =>
  items.reduce((counts, item) => {
    const value = item[key];
    counts[value] = (counts[value] ?? 0) + 1;
    return counts;
  }, {});
const edgeKey = (edge) => `${edge.type}\u0000${edge.source}\u0000${edge.target}`;

const plan = readJson('.understand-anything/intermediate/batch-plan.json');
const input = readJson('.understand-anything/tmp/ua-file-analyzer-input-2.json');
const extraction = readJson('.understand-anything/tmp/ua-file-extract-results-2.json');
const graph = readJson('.understand-anything/intermediate/batch-2.json');
const batch = plan.batches?.[1];

assert(batch, 'Không tìm thấy batches[1] trong batch-plan.json');
assert(batch.index === 2, `Batch plan có index ${batch.index}, dự kiến 2`);
assert(stableJson(input.batchFiles) === stableJson(batch.files), 'batchFiles không khớp nguyên bản với batches[1].files');
assert(stableJson(input.batchImportData) === stableJson(batch.importData), 'batchImportData không khớp nguyên bản với batches[1].importData');
assert(batch.files.length === 25, `Số file trong plan là ${batch.files.length}, dự kiến 25`);

const expectedImports = [];
for (const file of batch.files) {
  const imports = batch.importData[file.path] ?? [];
  for (const target of imports) {
    expectedImports.push({
      source: `file:${file.path}`,
      target: `file:${target}`,
      type: 'imports',
    });
  }
}
assert(expectedImports.length === 66, `Số imports trong plan là ${expectedImports.length}, dự kiến 66`);

assert(extraction.scriptCompleted === true, 'Extractor chưa báo scriptCompleted=true');
assert(extraction.filesAnalyzed === 25, `Extractor phân tích ${extraction.filesAnalyzed} file, dự kiến 25`);
assert(Array.isArray(extraction.filesSkipped) && extraction.filesSkipped.length === 0, 'Extractor có file bị bỏ qua');
assert(Array.isArray(graph.nodes), 'Graph thiếu mảng nodes');
assert(Array.isArray(graph.edges), 'Graph thiếu mảng edges');

const batchPaths = new Set(batch.files.map((file) => file.path));
const fileLineCounts = new Map();
for (const file of batch.files) {
  const absolutePath = path.join(root, ...file.path.split('/'));
  assert(fs.existsSync(absolutePath), `Path trong batch không tồn tại: ${file.path}`);
  const lines = fs.readFileSync(absolutePath, 'utf8').split(/\r?\n/);
  fileLineCounts.set(file.path, lines.length);
}

const nodeIds = new Set();
const validNodeTypes = new Set(['file', 'class', 'function']);
const validComplexity = new Set(['simple', 'moderate', 'complex']);
for (const node of graph.nodes) {
  assert(node && typeof node === 'object', 'Có node không phải object');
  assert(typeof node.id === 'string' && node.id.length > 0, 'Có node thiếu id');
  assert(!nodeIds.has(node.id), `Node ID trùng lặp: ${node.id}`);
  nodeIds.add(node.id);
  assert(validNodeTypes.has(node.type), `Node ${node.id} có type không hợp lệ: ${node.type}`);
  assert(typeof node.name === 'string' && node.name.length > 0, `Node ${node.id} thiếu name`);
  assert(batchPaths.has(node.filePath), `Node ${node.id} trỏ tới file ngoài batch: ${node.filePath}`);
  assert(typeof node.summary === 'string' && node.summary.trim().length > 0, `Node ${node.id} thiếu summary`);
  assert(Array.isArray(node.tags) && node.tags.length >= 3 && node.tags.length <= 5, `Node ${node.id} phải có 3-5 tags`);
  for (const tag of node.tags) {
    assert(typeof tag === 'string' && /^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(tag), `Tag không chuẩn ở ${node.id}: ${tag}`);
  }
  assert(validComplexity.has(node.complexity), `Node ${node.id} có complexity không hợp lệ`);

  if (node.type === 'file') {
    assert(node.id === `file:${node.filePath}`, `File node ID không chuẩn: ${node.id}`);
    assert(typeof node.languageNotes === 'string' && node.languageNotes.trim().length > 0, `File node ${node.id} thiếu languageNotes`);
    continue;
  }

  const expectedPrefix = `${node.type}:${node.filePath}:`;
  assert(node.id.startsWith(expectedPrefix), `${node.type} node ID không chuẩn: ${node.id}`);
  assert(Array.isArray(node.lineRange) && node.lineRange.length === 2, `Node ${node.id} thiếu lineRange`);
  const [start, end] = node.lineRange;
  const lineCount = fileLineCounts.get(node.filePath);
  assert(Number.isInteger(start) && Number.isInteger(end) && start >= 1 && end >= start && end <= lineCount,
    `lineRange ngoài file ở ${node.id}: ${start}-${end}/${lineCount}`);

  // Cho phép annotation hoặc signature nhiều dòng: declaration name phải xuất hiện
  // trong một cửa sổ nhỏ quanh start line đã ghi nhận.
  const absolutePath = path.join(root, ...node.filePath.split('/'));
  const lines = fs.readFileSync(absolutePath, 'utf8').split(/\r?\n/);
  const windowText = lines.slice(Math.max(0, start - 2), Math.min(lines.length, start + 5)).join(' ').replace(/\s+/g, '');
  const normalizedName = node.name.replace(/\s+/g, '');
  assert(windowText.includes(normalizedName), `Không thấy declaration ${node.name} gần start line ${start} của ${node.filePath}`);
}

const nodeTypes = countBy(graph.nodes, 'type');
assert(graph.nodes.length === 230, `Tổng nodes là ${graph.nodes.length}, dự kiến 230`);
assert(nodeTypes.file === 25, `File nodes là ${nodeTypes.file}, dự kiến 25`);
assert(nodeTypes.class === 70, `Class nodes là ${nodeTypes.class}, dự kiến 70`);
assert(nodeTypes.function === 135, `Function nodes là ${nodeTypes.function}, dự kiến 135`);
for (const file of batch.files) {
  assert(nodeIds.has(`file:${file.path}`), `Thiếu file node: ${file.path}`);
}

const edgeIds = new Set();
const edgeWeights = { contains: 1, exports: 0.8, imports: 0.7, calls: 0.8 };
for (const edge of graph.edges) {
  assert(edge && typeof edge === 'object', 'Có edge không phải object');
  assert(Object.hasOwn(edgeWeights, edge.type), `Edge type không hợp lệ: ${edge.type}`);
  assert(edge.direction === 'forward', `Edge ${edgeKey(edge)} không có direction=forward`);
  assert(edge.weight === edgeWeights[edge.type], `Edge ${edgeKey(edge)} có weight ${edge.weight}, dự kiến ${edgeWeights[edge.type]}`);
  assert(edge.source !== edge.target, `Self-edge: ${edgeKey(edge)}`);
  const key = edgeKey(edge);
  assert(!edgeIds.has(key), `Edge trùng lặp: ${key}`);
  edgeIds.add(key);

  if (edge.type === 'imports') {
    assert(nodeIds.has(edge.source), `Import source không phải file node trong batch: ${edge.source}`);
    assert(edge.source.startsWith('file:') && edge.target.startsWith('file:'), `Import edge không nối file->file: ${key}`);
    const targetPath = edge.target.slice('file:'.length);
    const absoluteTarget = path.join(root, ...targetPath.split('/'));
    assert(fs.existsSync(absoluteTarget), `Import target không tồn tại: ${targetPath}`);
  } else {
    assert(nodeIds.has(edge.source), `Edge source không tồn tại: ${edge.source}`);
    assert(nodeIds.has(edge.target), `Edge target không tồn tại: ${edge.target}`);
  }
}

const edgeTypes = countBy(graph.edges, 'type');
assert(graph.edges.length === 366, `Tổng edges là ${graph.edges.length}, dự kiến 366`);
assert(edgeTypes.contains === 205, `Contains edges là ${edgeTypes.contains}, dự kiến 205`);
assert(edgeTypes.exports === 62, `Exports edges là ${edgeTypes.exports}, dự kiến 62`);
assert(edgeTypes.imports === 66, `Imports edges là ${edgeTypes.imports}, dự kiến 66`);
assert(edgeTypes.calls === 33, `Calls edges là ${edgeTypes.calls}, dự kiến 33`);

const actualImportKeys = graph.edges
  .filter((edge) => edge.type === 'imports')
  .map((edge) => edgeKey(edge))
  .sort();
const expectedImportKeys = expectedImports.map((edge) => edgeKey(edge)).sort();
assert(stableJson(actualImportKeys) === stableJson(expectedImportKeys), 'Import edge multiset không khớp chính xác batchImportData');

const subnodes = graph.nodes.filter((node) => node.type !== 'file');
for (const node of subnodes) {
  const expectedContains = `contains\u0000file:${node.filePath}\u0000${node.id}`;
  const containsCount = graph.edges.filter((edge) => edgeKey(edge) === expectedContains).length;
  assert(containsCount === 1, `Node ${node.id} phải có đúng một contains edge, hiện có ${containsCount}`);
}

const exportTargets = new Set(graph.edges.filter((edge) => edge.type === 'exports').map((edge) => edge.target));
for (const node of subnodes) {
  const qualified = node.id.slice(`${node.type}:${node.filePath}:`.length);
  const isTopLevel = node.type === 'class' || !qualified.includes('.');
  const isPublic = !node.name.startsWith('_');
  const shouldExport = isTopLevel && isPublic;
  assert(exportTargets.has(node.id) === shouldExport,
    `${node.id} có trạng thái exports không đúng (expected=${shouldExport})`);
}
for (const edge of graph.edges.filter((item) => item.type === 'exports')) {
  const target = graph.nodes.find((node) => node.id === edge.target);
  assert(edge.source === `file:${target.filePath}`, `Exports edge sai source cho ${edge.target}`);
}

const extractionEntries = extraction.results ?? extraction.files ?? extraction.extractions ?? [];
const unsupportedStructureCount = Array.isArray(extractionEntries)
  ? extractionEntries.filter((entry) => {
      const functions = entry.functions ?? entry.structure?.functions ?? [];
      const classes = entry.classes ?? entry.structure?.classes ?? [];
      return functions.length === 0 && classes.length === 0;
    }).length
  : 0;

console.log(JSON.stringify({
  valid: true,
  batchFiles: batch.files.length,
  expectedImports: expectedImports.length,
  extractor: {
    scriptCompleted: extraction.scriptCompleted,
    filesAnalyzed: extraction.filesAnalyzed,
    filesSkipped: extraction.filesSkipped.length,
    emptyStructuresDetected: unsupportedStructureCount,
  },
  nodes: { total: graph.nodes.length, ...nodeTypes },
  edges: { total: graph.edges.length, ...edgeTypes },
}, null, 2));
