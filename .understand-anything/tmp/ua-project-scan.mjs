#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { pathToFileURL } from "node:url";

const LANGUAGE_BY_EXTENSION = new Map([
  [".ts", "typescript"], [".tsx", "typescript"],
  [".js", "javascript"], [".jsx", "javascript"],
  [".py", "python"], [".go", "go"], [".rs", "rust"],
  [".java", "java"], [".rb", "ruby"],
  [".cpp", "cpp"], [".cc", "cpp"], [".cxx", "cpp"],
  [".h", "cpp"], [".hpp", "cpp"], [".hxx", "cpp"], [".cuh", "cpp"],
  [".c", "c"], [".cs", "csharp"], [".swift", "swift"],
  [".kt", "kotlin"], [".kts", "kotlin"], [".php", "php"],
  [".vue", "vue"], [".svelte", "svelte"], [".dart", "dart"],
  [".sh", "shell"], [".bash", "shell"], [".ps1", "powershell"],
  [".bat", "batch"], [".cmd", "batch"],
  [".md", "markdown"], [".rst", "markdown"],
  [".yaml", "yaml"], [".yml", "yaml"], [".json", "json"],
  [".jsonc", "jsonc"], [".toml", "toml"], [".sql", "sql"],
  [".graphql", "graphql"], [".gql", "graphql"], [".proto", "protobuf"],
  [".tf", "terraform"], [".tfvars", "terraform"],
  [".html", "html"], [".htm", "html"],
  [".css", "css"], [".scss", "css"], [".sass", "css"], [".less", "css"],
  [".xml", "xml"], [".cfg", "config"], [".ini", "config"], [".env", "config"],
]);

const EXCLUDED_DIRECTORY_SEGMENTS = new Set([
  "node_modules", ".git", "vendor", "venv", ".venv", "__pycache__",
  "dist", "build", "out", "coverage", ".next", ".cache", ".turbo",
  "target", "obj",
]);
const EXCLUDED_EXTENSIONS = new Set([
  ".lock", ".png", ".jpg", ".jpeg", ".gif", ".svg", ".ico",
  ".woff", ".woff2", ".ttf", ".eot", ".mp3", ".mp4", ".pdf",
  ".zip", ".tar", ".gz", ".log",
]);
const CONFIG_EXTENSIONS = new Set([
  ".yaml", ".yml", ".json", ".jsonc", ".toml", ".xml", ".cfg", ".ini", ".env",
]);
const DATA_EXTENSIONS = new Set([".sql", ".graphql", ".gql", ".proto", ".prisma", ".csv"]);
const SCRIPT_EXTENSIONS = new Set([".sh", ".bash", ".ps1", ".bat"]);
const MARKUP_EXTENSIONS = new Set([".html", ".htm", ".css", ".scss", ".sass", ".less"]);
const DOC_EXTENSIONS = new Set([".md", ".rst", ".txt"]);
const RELATIVE_IMPORT_PROBES = [
  "", ".ts", ".tsx", ".js", ".jsx", "/index.ts", "/index.js",
  "/index.tsx", "/index.jsx", ".py", ".go", ".rs", ".rb", ".dart",
  ".kt", ".java", ".php",
];

function normalizePath(value) {
  return value.replaceAll("\\", "/").replace(/^\.\//, "");
}

function uniqueSorted(values) {
  return [...new Set(values)].sort((a, b) => a.localeCompare(b));
}

function isExistingProjectFile(root, relativePath) {
  const absolute = path.resolve(root, relativePath);
  const relative = path.relative(root, absolute);
  if (relative.startsWith("..") || path.isAbsolute(relative)) return false;
  try {
    return fs.statSync(absolute).isFile();
  } catch {
    return false;
  }
}

function discoverRecursively(root) {
  const results = [];
  const visit = (directory) => {
    let entries;
    try {
      entries = fs.readdirSync(directory, { withFileTypes: true });
    } catch {
      return;
    }
    entries.sort((a, b) => a.name.localeCompare(b.name));
    for (const entry of entries) {
      if (entry.name === ".git") continue;
      const absolute = path.join(directory, entry.name);
      if (entry.isDirectory()) {
        visit(absolute);
      } else if (entry.isFile()) {
        results.push(normalizePath(path.relative(root, absolute)));
      }
    }
  };
  visit(root);
  return results;
}

function discoverFiles(root) {
  const git = spawnSync("rtk", ["git", "-C", root, "ls-files", "-z"], {
    encoding: "buffer",
    maxBuffer: 64 * 1024 * 1024,
    windowsHide: true,
  });
  let files;
  if (!git.error && git.status === 0) {
    files = git.stdout.toString("utf8").split("\0").filter(Boolean).map(normalizePath);
  } else {
    files = discoverRecursively(root);
  }
  return uniqueSorted(files).filter((file) => isExistingProjectFile(root, file));
}

function isHardcodedIgnored(relativePath) {
  const normalized = normalizePath(relativePath);
  const segments = normalized.split("/");
  const base = segments.at(-1) ?? "";
  const lowerBase = base.toLowerCase();
  const extension = path.posix.extname(lowerBase);

  if (segments.slice(0, -1).some((segment) => EXCLUDED_DIRECTORY_SEGMENTS.has(segment))) return true;
  if (EXCLUDED_EXTENSIONS.has(extension)) return true;
  if (["package-lock.json", "yarn.lock", "pnpm-lock.yaml"].includes(lowerBase)) return true;
  if (lowerBase.endsWith(".min.js") || lowerBase.endsWith(".min.css")) return true;
  if (lowerBase.endsWith(".map") || lowerBase.includes(".generated.")) return true;
  if (segments.includes(".idea") || segments.includes(".vscode")) return true;
  if (base === "LICENSE" || lowerBase === ".gitignore" || lowerBase === ".editorconfig") return true;
  if (lowerBase === ".prettierrc" || lowerBase.startsWith(".eslintrc")) return true;
  return false;
}

async function applyIgnoreRules(root, originalFiles) {
  const projectIgnore = path.join(root, ".understand-anything", ".understandignore");
  const rootIgnore = path.join(root, ".understandignore");
  const baselineFiles = originalFiles.filter((file) => !isHardcodedIgnored(file));
  if (!fs.existsSync(projectIgnore) && !fs.existsSync(rootIgnore)) {
    return { files: baselineFiles, filteredByIgnore: 0 };
  }

  const candidates = uniqueSorted([
    process.env.UNDERSTAND_CORE_DIST || "",
    path.join(process.env.USERPROFILE || "", ".understand-anything", "repo", "understand-anything-plugin", "packages", "core", "dist", "index.js"),
    "C:/Users/admin/.understand-anything/repo/understand-anything-plugin/packages/core/dist/index.js",
  ].filter(Boolean));
  const corePath = candidates.find((candidate) => fs.existsSync(candidate));
  if (!corePath) {
    throw new Error("Không tìm thấy bản build @understand-anything/core để áp dụng .understandignore");
  }
  const { createIgnoreFilter } = await import(pathToFileURL(corePath).href);
  const ignoreFilter = createIgnoreFilter(root);
  const files = originalFiles.filter((file) => !ignoreFilter.isIgnored(normalizePath(file)));
  const finalSet = new Set(files);
  const filteredByIgnore = baselineFiles.filter((file) => !finalSet.has(file)).length;
  return { files, filteredByIgnore };
}

function detectLanguage(relativePath) {
  const base = path.posix.basename(relativePath);
  if (base === "Dockerfile") return "dockerfile";
  if (base === "Makefile") return "makefile";
  if (base === "Jenkinsfile") return "jenkinsfile";
  const extension = path.posix.extname(base).toLowerCase();
  return LANGUAGE_BY_EXTENSION.get(extension) || extension.slice(1) || "unknown";
}

function isInfrastructurePath(relativePath) {
  const normalized = normalizePath(relativePath);
  const lower = normalized.toLowerCase();
  const base = path.posix.basename(normalized);
  const lowerBase = base.toLowerCase();
  return base === "Dockerfile"
    || lowerBase === "docker-compose.yml"
    || lowerBase === "docker-compose.yaml"
    || ["Makefile", "Jenkinsfile", "Procfile", "Vagrantfile"].includes(base)
    || lowerBase === ".gitlab-ci.yml"
    || lower.startsWith(".github/workflows/")
    || lower.startsWith(".circleci/")
    || lower.includes("/k8s/") || lower.startsWith("k8s/")
    || lower.includes("/kubernetes/") || lower.startsWith("kubernetes/")
    || lowerBase.endsWith(".k8s.yaml") || lowerBase.endsWith(".k8s.yml")
    || [".tf", ".tfvars"].includes(path.posix.extname(lowerBase));
}

function detectFileCategory(relativePath) {
  const normalized = normalizePath(relativePath);
  const base = path.posix.basename(normalized);
  const lowerBase = base.toLowerCase();
  const extension = path.posix.extname(lowerBase);
  if (base !== "LICENSE" && DOC_EXTENSIONS.has(extension)) return "docs";
  if (isInfrastructurePath(normalized)) return "infra";
  if (DATA_EXTENSIONS.has(extension) || lowerBase.endsWith(".schema.json")) return "data";
  if (SCRIPT_EXTENSIONS.has(extension)) return "script";
  if (MARKUP_EXTENSIONS.has(extension)) return "markup";
  if (CONFIG_EXTENSIONS.has(extension)
      || ["tsconfig.json", "package.json", "pyproject.toml", "cargo.toml", "go.mod"].includes(lowerBase)) {
    return "config";
  }
  return "code";
}

function countNewlines(absolutePath) {
  try {
    const buffer = fs.readFileSync(absolutePath);
    let count = 0;
    for (const byte of buffer) if (byte === 10) count += 1;
    return count;
  } catch {
    return 0;
  }
}

function countLines(root, files) {
  const counts = new Map();
  const chunks = [];
  for (let index = 0; index < files.length; index += 80) chunks.push(files.slice(index, index + 80));

  let wcAvailable = true;
  for (const chunk of chunks) {
    const absolutePaths = chunk.map((file) => path.join(root, ...file.split("/")));
    const wc = spawnSync("rtk", ["wc", "-l", "--", ...absolutePaths], {
      encoding: "utf8",
      maxBuffer: 16 * 1024 * 1024,
      windowsHide: true,
    });
    if (wc.error || wc.status !== 0) {
      wcAvailable = false;
      break;
    }
    for (const line of wc.stdout.split(/\r?\n/)) {
      const match = line.match(/^\s*(\d+)\s+(.+?)\s*$/);
      if (!match || match[2] === "total") continue;
      const reported = match[2].replace(/^['"]|['"]$/g, "");
      const relative = normalizePath(path.relative(root, path.resolve(reported)));
      if (files.includes(relative)) counts.set(relative, Number(match[1]));
    }
  }

  if (!wcAvailable || counts.size !== files.length) {
    counts.clear();
    for (const file of files) counts.set(file, countNewlines(path.join(root, ...file.split("/"))));
  }
  return counts;
}

function readText(root, relativePath) {
  try {
    return fs.readFileSync(path.join(root, ...relativePath.split("/")), "utf8");
  } catch {
    return "";
  }
}

function parseJson(text) {
  try {
    return JSON.parse(text);
  } catch {
    return null;
  }
}

function parsePubspec(text) {
  const field = (name) => {
    const match = text.match(new RegExp(`^${name}:\\s*["']?([^\\r\\n"'#]+)`, "m"));
    return match ? match[1].trim() : "";
  };
  const dependencyNames = new Set();
  let section = "";
  for (const line of text.split(/\r?\n/)) {
    const topLevel = line.match(/^([A-Za-z_][\w-]*):\s*(?:#.*)?$/);
    if (topLevel) {
      section = topLevel[1];
      continue;
    }
    if (section === "dependencies" || section === "dev_dependencies") {
      const dependency = line.match(/^\s{2}([A-Za-z_][\w-]*):/);
      if (dependency) dependencyNames.add(dependency[1]);
    }
  }
  return { name: field("name"), description: field("description"), dependencyNames };
}

function addPackageFrameworks(frameworks, packageJson) {
  const all = { ...(packageJson?.dependencies || {}), ...(packageJson?.devDependencies || {}) };
  const mapping = new Map([
    ["react", "React"], ["vue", "Vue"], ["svelte", "Svelte"], ["@angular/core", "Angular"],
    ["express", "Express"], ["fastify", "Fastify"], ["koa", "Koa"], ["next", "Next.js"],
    ["nuxt", "Nuxt"], ["vite", "Vite"], ["vitest", "Vitest"], ["jest", "Jest"],
    ["mocha", "Mocha"], ["tailwindcss", "Tailwind CSS"], ["prisma", "Prisma"],
    ["typeorm", "TypeORM"], ["sequelize", "Sequelize"], ["mongoose", "Mongoose"],
    ["redux", "Redux"], ["zustand", "Zustand"], ["mobx", "MobX"],
  ]);
  for (const [dependency, framework] of mapping) if (dependency in all) frameworks.add(framework);
}

function addKeywordFrameworks(frameworks, text, mappings) {
  const lower = text.toLowerCase();
  for (const [needle, label] of mappings) if (lower.includes(needle.toLowerCase())) frameworks.add(label);
}

function detectProjectMetadata(root, files) {
  const frameworks = new Set();
  let name = path.basename(root);
  let rawDescription = "";
  let dartPackageName = "";

  const has = (file) => files.includes(file);
  if (has("package.json")) {
    const packageJson = parseJson(readText(root, "package.json"));
    if (packageJson?.name) name = packageJson.name;
    if (packageJson?.description) rawDescription = packageJson.description;
    addPackageFrameworks(frameworks, packageJson);
  }
  if (has("tsconfig.json")) frameworks.add("TypeScript");

  if (has("Cargo.toml")) {
    const cargo = readText(root, "Cargo.toml");
    if (!has("package.json")) {
      const match = cargo.match(/^name\s*=\s*["']([^"']+)/m);
      if (match) name = match[1];
    }
    addKeywordFrameworks(frameworks, cargo, [
      ["actix-web", "Actix Web"], ["axum", "Axum"], ["rocket", "Rocket"],
      ["diesel", "Diesel"], ["tokio", "Tokio"], ["serde", "Serde"], ["warp", "Warp"],
    ]);
  }
  if (has("go.mod")) {
    const goMod = readText(root, "go.mod");
    if (!has("package.json") && !has("Cargo.toml")) {
      const match = goMod.match(/^module\s+(\S+)/m);
      if (match) name = match[1].split("/").at(-1);
    }
    addKeywordFrameworks(frameworks, goMod, [
      ["github.com/gin-gonic/gin", "Gin"], ["github.com/labstack/echo", "Echo"],
      ["github.com/gofiber/fiber", "Fiber"], ["github.com/go-chi/chi", "Chi"], ["gorm.io/gorm", "GORM"],
    ]);
  }

  const pythonManifestFiles = ["requirements.txt", "pyproject.toml", "setup.py", "setup.cfg", "Pipfile"].filter(has);
  if (pythonManifestFiles.length) {
    const pythonText = pythonManifestFiles.map((file) => readText(root, file)).join("\n");
    addKeywordFrameworks(frameworks, pythonText, [
      ["djangorestframework", "Django REST Framework"], ["django", "Django"],
      ["fastapi", "FastAPI"], ["flask", "Flask"], ["sqlalchemy", "SQLAlchemy"],
      ["alembic", "Alembic"], ["celery", "Celery"], ["pydantic", "Pydantic"],
      ["uvicorn", "Uvicorn"], ["gunicorn", "Gunicorn"], ["aiohttp", "aiohttp"],
      ["tornado", "Tornado"], ["starlette", "Starlette"], ["pytest", "pytest"],
      ["hypothesis", "Hypothesis"], ["channels", "Django Channels"],
    ]);
    if (!has("package.json") && !has("Cargo.toml") && !has("go.mod") && has("pyproject.toml")) {
      const pyproject = readText(root, "pyproject.toml");
      const projectSection = pyproject.match(/\[project\][\s\S]*?^name\s*=\s*["']([^"']+)/m);
      const poetrySection = pyproject.match(/\[tool\.poetry\][\s\S]*?^name\s*=\s*["']([^"']+)/m);
      if (projectSection || poetrySection) name = (projectSection || poetrySection)[1];
    }
  }

  if (has("Gemfile")) addKeywordFrameworks(frameworks, readText(root, "Gemfile"), [
    ["rails", "Rails"], ["railties", "Railties"], ["sinatra", "Sinatra"], ["grape", "Grape"],
    ["rspec", "RSpec"], ["sidekiq", "Sidekiq"], ["activerecord", "Active Record"],
    ["actionpack", "Action Pack"], ["devise", "Devise"], ["pundit", "Pundit"],
  ]);

  for (const manifest of ["pom.xml", "build.gradle", "build.gradle.kts"].filter(has)) {
    addKeywordFrameworks(frameworks, readText(root, manifest), [
      ["spring-boot", "Spring Boot"], ["spring-web", "Spring Web"], ["spring-data", "Spring Data"],
      ["quarkus", "Quarkus"], ["micronaut", "Micronaut"], ["hibernate", "Hibernate"],
      ["jakarta", "Jakarta"], ["junit", "JUnit"], ["ktor", "Ktor"],
    ]);
  }

  if (has("pubspec.yaml")) {
    const pubspec = parsePubspec(readText(root, "pubspec.yaml"));
    dartPackageName = pubspec.name;
    if (!has("package.json") && !has("Cargo.toml") && !has("go.mod") && pubspec.name) name = pubspec.name;
    if (!rawDescription && pubspec.description) rawDescription = pubspec.description;
    if (pubspec.dependencyNames.has("flutter")) frameworks.add("Flutter");
    if (pubspec.dependencyNames.has("flutter_riverpod") || pubspec.dependencyNames.has("riverpod_annotation")) frameworks.add("Riverpod");
    if (pubspec.dependencyNames.has("go_router")) frameworks.add("GoRouter");
  }

  if (has("Dockerfile")) frameworks.add("Docker");
  if (has("docker-compose.yml") || has("docker-compose.yaml")) frameworks.add("Docker Compose");
  if (files.some((file) => file.endsWith(".tf"))) frameworks.add("Terraform");
  if (files.some((file) => /^\.github\/workflows\/.*\.ya?ml$/i.test(file))) frameworks.add("GitHub Actions");
  if (has(".gitlab-ci.yml")) frameworks.add("GitLab CI");
  if (has("Jenkinsfile")) frameworks.add("Jenkins");

  return { name, rawDescription, dartPackageName, frameworks: uniqueSorted(frameworks) };
}

function resolveFirst(filesSet, candidates) {
  for (const candidate of candidates) {
    const normalized = normalizePath(path.posix.normalize(candidate));
    if (!normalized.startsWith("../") && filesSet.has(normalized)) return normalized;
  }
  return null;
}

function resolveRelativeImport(importer, specifier, filesSet, extraProbes = []) {
  const base = path.posix.normalize(path.posix.join(path.posix.dirname(importer), specifier));
  return resolveFirst(filesSet, [...new Set([...RELATIVE_IMPORT_PROBES, ...extraProbes])].map((probe) => `${base}${probe}`));
}

function loadTsAliases(root, files) {
  if (!files.includes("tsconfig.json")) return [];
  let config = parseJson(readText(root, "tsconfig.json"));
  if (!config) {
    const stripped = readText(root, "tsconfig.json").replace(/\/\*[\s\S]*?\*\//g, "").replace(/^\s*\/\/.*$/gm, "");
    config = parseJson(stripped);
  }
  const compilerOptions = config?.compilerOptions || {};
  const aliases = [];
  for (const [pattern, targets] of Object.entries(compilerOptions.paths || {})) {
    for (const target of Array.isArray(targets) ? targets : []) {
      aliases.push({ pattern, target, baseUrl: compilerOptions.baseUrl || "." });
    }
  }
  return aliases;
}

function resolveTsAlias(specifier, aliases, filesSet) {
  for (const alias of aliases) {
    const starIndex = alias.pattern.indexOf("*");
    let wildcard = "";
    if (starIndex >= 0) {
      const prefix = alias.pattern.slice(0, starIndex);
      const suffix = alias.pattern.slice(starIndex + 1);
      if (!specifier.startsWith(prefix) || !specifier.endsWith(suffix)) continue;
      wildcard = specifier.slice(prefix.length, specifier.length - suffix.length);
    } else if (specifier !== alias.pattern) {
      continue;
    }
    const substituted = alias.target.replace("*", wildcard);
    const base = path.posix.normalize(path.posix.join(normalizePath(alias.baseUrl), substituted));
    const resolved = resolveFirst(filesSet, RELATIVE_IMPORT_PROBES.map((probe) => `${base}${probe}`));
    if (resolved) return resolved;
  }
  return null;
}

function parseComposerAutoload(root, files) {
  if (!files.includes("composer.json")) return [];
  const composer = parseJson(readText(root, "composer.json"));
  const mappings = composer?.autoload?.["psr-4"] || {};
  return Object.entries(mappings).flatMap(([prefix, directories]) =>
    (Array.isArray(directories) ? directories : [directories]).map((directory) => ({ prefix, directory: normalizePath(directory) })));
}

function buildImportMap(root, fileRecords, metadata) {
  const files = fileRecords.map((record) => record.path);
  const filesSet = new Set(files);
  const tsAliases = loadTsAliases(root, files);
  const composerMappings = parseComposerAutoload(root, files);
  const goMod = filesSet.has("go.mod") ? readText(root, "go.mod") : "";
  const goModule = goMod.match(/^module\s+(\S+)/m)?.[1] || "";
  const importMap = Object.fromEntries(files.map((file) => [file, []]));

  const add = (resolved, imports) => {
    if (resolved && filesSet.has(resolved)) imports.add(resolved);
  };

  for (const record of fileRecords) {
    if (record.fileCategory !== "code") continue;
    const content = readText(root, record.path);
    const imports = new Set();

    if (record.language === "typescript" || record.language === "javascript") {
      const patterns = [
        /\bimport\s+(?:[\s\S]*?\s+from\s+)?["']([^"']+)["']/g,
        /\brequire\s*\(\s*["']([^"']+)["']\s*\)/g,
      ];
      for (const pattern of patterns) {
        for (const match of content.matchAll(pattern)) {
          const specifier = match[1];
          if (specifier.startsWith("./") || specifier.startsWith("../")) add(resolveRelativeImport(record.path, specifier, filesSet), imports);
          else add(resolveTsAlias(specifier, tsAliases, filesSet), imports);
        }
      }
    } else if (record.language === "dart") {
      for (const match of content.matchAll(/\b(?:import|export|part)\s+["']([^"']+)["']/g)) {
        const specifier = match[1];
        if (specifier.startsWith("dart:")) continue;
        if (specifier.startsWith("package:")) {
          const packageMatch = specifier.match(/^package:([^/]+)\/(.+)$/);
          if (packageMatch && packageMatch[1] === metadata.dartPackageName) add(resolveFirst(filesSet, [`lib/${packageMatch[2]}`]), imports);
        } else if (specifier.startsWith("./") || specifier.startsWith("../") || !specifier.includes(":")) {
          add(resolveRelativeImport(record.path, specifier, filesSet, [".dart"]), imports);
        }
      }
    } else if (record.language === "python") {
      for (const match of content.matchAll(/^\s*import\s+([^#\n]+)/gm)) {
        for (const item of match[1].split(",")) {
          const moduleName = item.trim().split(/\s+as\s+/)[0];
          const modulePath = moduleName.replaceAll(".", "/");
          add(resolveFirst(filesSet, [`${modulePath}.py`, `${modulePath}/__init__.py`]), imports);
        }
      }
      for (const match of content.matchAll(/^\s*from\s+([.\w]+)\s+import\s+([^#\n]+)/gm)) {
        const moduleName = match[1];
        const importedNames = match[2].replace(/[()]/g, "").split(",").map((name) => name.trim().split(/\s+as\s+/)[0]).filter(Boolean);
        if (moduleName.startsWith(".")) {
          const dots = moduleName.match(/^\.+/)[0].length;
          const suffix = moduleName.slice(dots).replaceAll(".", "/");
          let baseDirectory = path.posix.dirname(record.path);
          for (let index = 1; index < dots; index += 1) baseDirectory = path.posix.dirname(baseDirectory);
          const moduleBase = path.posix.join(baseDirectory, suffix);
          const packageInit = resolveFirst(filesSet, [`${moduleBase}.py`, `${moduleBase}/__init__.py`]);
          add(packageInit, imports);
          if (packageInit?.endsWith("/__init__.py")) {
            for (const importedName of importedNames) add(resolveFirst(filesSet, [`${moduleBase}/${importedName}.py`, `${moduleBase}/${importedName}/__init__.py`]), imports);
          }
        } else {
          const moduleBase = moduleName.replaceAll(".", "/");
          const packageInit = resolveFirst(filesSet, [`${moduleBase}.py`, `${moduleBase}/__init__.py`]);
          add(packageInit, imports);
          if (packageInit?.endsWith("/__init__.py")) {
            for (const importedName of importedNames) add(resolveFirst(filesSet, [`${moduleBase}/${importedName}.py`, `${moduleBase}/${importedName}/__init__.py`]), imports);
          }
        }
      }
    } else if (record.language === "go" && goModule) {
      for (const match of content.matchAll(/["`]([^"`]+)["`]/g)) {
        if (!match[1].startsWith(`${goModule}/`)) continue;
        const packagePath = match[1].slice(goModule.length + 1);
        const candidates = files.filter((file) => file.startsWith(`${packagePath}/`) && file.endsWith(".go") && !file.endsWith("_test.go"));
        for (const candidate of candidates) imports.add(candidate);
      }
    } else if (record.language === "rust") {
      for (const match of content.matchAll(/\bmod\s+([A-Za-z_]\w*)\s*;/g)) {
        const directory = path.posix.dirname(record.path);
        add(resolveFirst(filesSet, [`${directory}/${match[1]}.rs`, `${directory}/${match[1]}/mod.rs`]), imports);
      }
      for (const match of content.matchAll(/\buse\s+(crate|super)::([A-Za-z_]\w*(?:::[A-Za-z_]\w*)*)/g)) {
        const segments = match[2].split("::");
        const baseDirectory = match[1] === "crate" ? "src" : path.posix.dirname(path.posix.dirname(record.path));
        add(resolveFirst(filesSet, [`${baseDirectory}/${segments.join("/")}.rs`, `${baseDirectory}/${segments.join("/")}/mod.rs`]), imports);
      }
    } else if (record.language === "java" || record.language === "kotlin") {
      const extension = record.language === "java" ? ".java" : ".kt";
      for (const match of content.matchAll(/^\s*import\s+(?:static\s+)?([\w.]+)\s*;?/gm)) {
        const suffix = `${match[1].replaceAll(".", "/")}${extension}`;
        const candidate = files.find((file) => file === suffix || file.endsWith(`/${suffix}`));
        add(candidate, imports);
      }
    } else if (record.language === "ruby") {
      for (const match of content.matchAll(/\brequire_relative\s+["']([^"']+)["']/g)) add(resolveRelativeImport(record.path, match[1], filesSet, [".rb"]), imports);
      for (const match of content.matchAll(/\brequire\s+["']([^"']+)["']/g)) {
        const specifier = match[1].replace(/\.rb$/, "");
        add(resolveFirst(filesSet, [`lib/${specifier}.rb`, `app/${specifier}.rb`, `${specifier}.rb`]), imports);
      }
    } else if (record.language === "php") {
      for (const match of content.matchAll(/^\s*use\s+([^;]+);/gm)) {
        const namespace = match[1].trim().replace(/^function\s+|^const\s+/, "");
        for (const mapping of composerMappings) {
          if (!namespace.startsWith(mapping.prefix)) continue;
          const remainder = namespace.slice(mapping.prefix.length).replaceAll("\\", "/");
          add(resolveFirst(filesSet, [`${mapping.directory.replace(/\/$/, "")}/${remainder}.php`]), imports);
        }
      }
    } else if (record.language === "c" || record.language === "cpp") {
      for (const match of content.matchAll(/^\s*#\s*include\s*[<"]([^>"]+)[>"]/gm)) {
        const includePath = match[1];
        const directory = path.posix.dirname(record.path);
        add(resolveFirst(filesSet, [
          `${directory}/${includePath}`, `include/${includePath}`, `src/${includePath}`, includePath,
        ]), imports);
      }
    }
    importMap[record.path] = uniqueSorted(imports);
  }
  return importMap;
}

function readReadmeHead(root, files) {
  const readme = ["README.md", "readme.md", "README.rst"].find((candidate) => files.includes(candidate));
  if (!readme) return "";
  return readText(root, readme).split(/\r?\n/).slice(0, 10).join("\n");
}

async function main() {
  const projectRootArgument = process.argv[2];
  const outputPathArgument = process.argv[3];
  if (!projectRootArgument || !outputPathArgument) throw new Error("Usage: node ua-project-scan.mjs <project-root> <output-json>");

  const root = path.resolve(projectRootArgument);
  const outputPath = path.resolve(outputPathArgument);
  let stat;
  try {
    stat = fs.statSync(root);
  } catch (error) {
    throw new Error(`Không thể truy cập project root: ${error.message}`);
  }
  if (!stat.isDirectory()) throw new Error(`Project root không phải thư mục: ${root}`);

  const originalFiles = discoverFiles(root);
  const { files, filteredByIgnore } = await applyIgnoreRules(root, originalFiles);
  const lineCounts = countLines(root, files);
  const fileRecords = files.map((file) => ({
    path: file,
    language: detectLanguage(file),
    sizeLines: lineCounts.get(file) ?? 0,
    fileCategory: detectFileCategory(file),
  })).sort((a, b) => a.path.localeCompare(b.path));
  const metadata = detectProjectMetadata(root, files);
  const importMap = buildImportMap(root, fileRecords, metadata);
  const totalFiles = fileRecords.length;
  const estimatedComplexity = totalFiles <= 30 ? "small"
    : totalFiles <= 150 ? "moderate"
      : totalFiles <= 500 ? "large" : "very-large";

  const result = {
    scriptCompleted: true,
    name: metadata.name,
    rawDescription: metadata.rawDescription,
    readmeHead: readReadmeHead(root, files),
    languages: uniqueSorted(fileRecords.map((file) => file.language)),
    frameworks: metadata.frameworks,
    files: fileRecords,
    totalFiles,
    filteredByIgnore,
    estimatedComplexity,
    importMap,
  };

  if (result.totalFiles !== result.files.length) throw new Error("totalFiles không khớp files.length");
  if (Object.keys(result.importMap).length !== result.files.length) throw new Error("importMap không bao phủ toàn bộ file inventory");
  for (const file of result.files) {
    if (!isExistingProjectFile(root, file.path)) throw new Error(`Đường dẫn không tồn tại: ${file.path}`);
  }

  fs.mkdirSync(path.dirname(outputPath), { recursive: true });
  fs.writeFileSync(outputPath, `${JSON.stringify(result, null, 2)}\n`, "utf8");
}

main().then(() => process.exit(0)).catch((error) => {
  process.stderr.write(`${error instanceof Error ? error.message : String(error)}\n`);
  process.exit(1);
});
