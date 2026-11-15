// Dev utility: dump a rendered course-file PDF's bookmark/outline tree to
// the console, for a quick sanity-check of chapter structure after a
// render. Usage (from the project root):
//   node tools/dump_outline.js [path/to/file.pdf]
// With no argument, it picks the first PDF found in the project's
// "Course File" output directory, so this works for any course-file
// project without hardcoding a course-specific filename.
const fs = require("fs");
const path = require("path");
const { PDFDocument, PDFName, PDFDict, PDFString, PDFHexString } = require("pdf-lib");

function resolvePdfPath() {
  if (process.argv[2]) return process.argv[2];
  const outputDir = path.join(__dirname, "..", "Course File");
  const pdfs = fs.readdirSync(outputDir).filter((f) => f.toLowerCase().endsWith(".pdf"));
  if (pdfs.length === 0) {
    throw new Error(`No PDF found in "${outputDir}". Render the project first, or pass a path explicitly.`);
  }
  return path.join(outputDir, pdfs[0]);
}

(async () => {
  const bytes = fs.readFileSync(resolvePdfPath());
  const pdfDoc = await PDFDocument.load(bytes, { updateMetadata: false });
  const catalog = pdfDoc.catalog;
  const outlinesRef = catalog.get(PDFName.of("Outlines"));
  if (!outlinesRef) { console.log("No /Outlines found"); return; }
  const context = pdfDoc.context;

  function getTitle(dict) {
    const t = dict.get(PDFName.of("Title"));
    if (!t) return "(no title)";
    if (t instanceof PDFString || t instanceof PDFHexString) return t.decodeText();
    return String(t);
  }

  function walk(ref, depth) {
    if (!ref) return;
    const dict = context.lookup(ref);
    if (!(dict instanceof PDFDict)) return;
    let child = dict.get(PDFName.of("First"));
    while (child) {
      const cdict = context.lookup(child);
      if (!(cdict instanceof PDFDict)) break;
      console.log("  ".repeat(depth) + "- " + getTitle(cdict));
      walk(child, depth + 1);
      child = cdict.get(PDFName.of("Next"));
    }
  }

  walk(outlinesRef, 0);
})();
