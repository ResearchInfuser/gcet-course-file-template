# Contributing

Thank you for helping improve the GCET Course File Template. Bug reports,
fixes, new chapters, support for other departments or institutions, and
documentation improvements are all welcome.

This guide covers what you need to make a change and get it accepted. The
[README](README.md) explains how the template itself works.

## The one rule: no real data

This is a public template. A real course file contains student names,
admission numbers, marks, attendance and answer-sheet scans, and none of
that may ever be committed here.

- Use only the fictitious demo workbook, or data you have generated.
- Use only placeholder images under `Course File Resources/`.
- Check screenshots and PDFs attached to issues or pull requests as well:
  blur or replace anything that identifies a real student or faculty member.

A pull request containing real personal data will be closed, and the data
will have to be removed from the history.

## Reporting a problem

Open an issue and include:

- what you ran (for example `Rscript tools/render_course_file.R docx`) and
  which variant: Course Coordinator, Subject Teacher or Laboratory Course;
- the full error message, or a description of what looks wrong in the output;
- the output of `Rscript tools/check_workbook.R`;
- your versions of Quarto (`quarto --version`), R (`R --version`) and your
  operating system.

If the problem only appears with your own workbook, reproduce it with the
demo workbook, or describe the difference (an extra column, a longer table,
a renamed sheet) instead of attaching the real file.

For a feature request, describe the course-file requirement behind it, such
as the accreditation format or the department practice it comes from. That
helps decide whether it belongs in the shared template or in a profile.

## Setting up

1. Fork the repository and clone your fork.
2. Install the prerequisites listed in the README's
   [Quick start](README.md#quick-start): Quarto 1.4 or newer, R 4.2 or
   newer, TinyTeX, and the R packages (`Rscript tools/install_packages.R`).
3. Render the demo once, to confirm your setup works before you change
   anything:
   ```bash
   Rscript tools/render_course_file.R
   ```
4. Optional: run `npm install` in `tools/` if you want to use
   `dump_outline.js` to inspect a rendered PDF's bookmark tree.

## Making a change

Create a branch from `main` with a short descriptive name, such as
`fix/register-column-lookup` or `feat/lab-experiments-from-workbook`.

### Conventions

- **Nothing course-specific is hardcoded.** Per-course values come from the
  workbook's `0.CourseFile_Config` sheet. Institute-wide values come from
  `coursefile:` in `_quarto.yml`.
- **Workbook structure lives in one place.** Sheet names and cell ranges go
  under `coursefile.schema` in `_quarto.yml`. Register column headers go in
  `required_register_columns` in `Course File Resources/_data_helpers.R`.
  Do not write a sheet name, range or column header directly in a `.qmd`.
- **Use the shared helpers** in `_data_helpers.R` (`cf_value()`,
  `cf_sheet()`, `cf_range()`, `read_workbook_sheet()`,
  `render_register_table()` and others) instead of reading the workbook
  directly in a chapter.
- **Fail loudly.** A missing sheet, column or Config value should stop the
  render with a message that says what to fix, not produce a wrong or
  empty chapter.
- **Never include the same file from two profile blocks** in `index.qmd`.
  Duplicate chunk labels fail the render. Use `unless-profile` to share one
  include.
- **Chapter files** follow the existing numbering: `NN_name.qmd` for theory
  chapters and `LNN_name.qmd` for laboratory chapters.
- **Do not commit generated files**: `Course File/`, `_metadata.yml`,
  `.quarto/`, `*.tex` and the root copy of `GcetCourseFile.cls` are all
  gitignored for that reason.
- **Match the surrounding code style.** The R scripts indent with tabs.

The README has step-by-step instructions for the two most common larger
changes: [adding a new profile](README.md#adding-a-new-profile) and
[adding a new data-driven chapter](README.md#adding-a-new-data-driven-chapter).

### Changing the demo workbook

If your change needs a new sheet, column or Config key, add it to
`Course Workbook/DEMO_BMC101_Course_Workbook.xlsx` with fictitious values so
the template still renders out of the box. Keep exactly one workbook in that
folder.

## Testing your change

There is no automated test suite, so every change is checked by rendering.
Before opening a pull request:

1. Validate the workbook. Every line should be `[OK]`:
   ```bash
   Rscript tools/check_workbook.R
   ```
2. Render all three variants. A change to a shared helper or to the PDF
   class can break a variant you did not touch:
   ```bash
   quarto render --to gcet-course-file-pdf --profile course-coordinator
   quarto render --to gcet-course-file-pdf --profile subject-teacher
   quarto render --to gcet-course-file-pdf --profile laboratory-course
   ```
3. If your change affects tables or layout, also render one variant to Word:
   ```bash
   quarto render --to docx --profile course-coordinator
   ```
4. Open the PDFs and look at the chapters you changed, the table of
   contents, and the cover page.

If the rendered output changes visibly, regenerate the affected PDFs in
`sample-output/` and include them in the pull request, keeping the existing
filenames.

## Submitting a pull request

- Keep a pull request to one logical change.
- Write commit messages in the imperative mood with a short summary line,
  for example `Fix CO attainment table when a CAE column is empty`.
- Add an entry under `## [Unreleased]` in [CHANGELOG.md](CHANGELOG.md) for
  any change a user of the template would notice.
- Update the README if you change the Config keys, the schema, the commands
  or the folder layout.
- In the description, say what changed and why, which variants you
  rendered, and whether the output changed. A before/after screenshot of
  the affected page helps for layout changes.

## Releases (maintainers)

The project follows [Semantic Versioning](https://semver.org/). Because
faculty keep their own workbooks, the workbook layout is the public
interface:

- **Major**: an existing workbook or `_quarto.yml` no longer renders
  without edits (a renamed Config key, a new required Register column, a
  moved range).
- **Minor**: new chapters, profiles, Config keys or options that existing
  workbooks can ignore.
- **Patch**: bug fixes and documentation.

To release:

1. Move the `[Unreleased]` entries in `CHANGELOG.md` under a new version
   heading with the release date.
2. Update `version` in `_extensions/gcet-course-file/_extension.yml`.
3. Regenerate the PDFs in `sample-output/`.
4. Tag the commit `vX.Y.Z`.

## Licence

By contributing, you agree that your contribution is released under the
project's [MIT Licence](LICENSE). The Galgotias College of Engineering and
Technology name and logo belong to the institution; do not add other
institutions' logos or branding without permission to redistribute them.
