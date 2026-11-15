# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
What counts as a breaking change for this template is described in
[CONTRIBUTING.md](CONTRIBUTING.md#releases-maintainers).

## [Unreleased]

### Added

- Preview section in the README with title page and table of contents
  screenshots for all three variants (`docs/screenshots/`).

## [0.1.0] - 2026-11-15

First public release.

### Added

- `README.md` covering the quick start, rendering, the workbook layout,
  evidence folders and how to adapt the template.
- `CONTRIBUTING.md` with the contribution workflow, project conventions and
  release process.
- `CHANGELOG.md` (this file).

### Known limitations

- The laboratory chapters for the schedule, experiments, manual and
  evaluation sheet do not yet read from the workbook.
- The demo workbook's CO-PO mapping justifications are sample text and do
  not match the demo course's outcomes.
- Table ranges in `coursefile.schema` are fixed, not auto-detected.

## [0.0.5] - 2026-11-15

### Added

- `tools/render_course_file.R`, which renders the variant chosen in the
  Config sheet and names the output
  `<course-code>-<Variant>-Course-File-<faculty-name>`, and
  `tools/render_course_file.ps1`, a Windows wrapper that finds `Rscript.exe`
  when it is not on `PATH`.
- `tools/check_workbook.R` for preflight validation of the workbook's
  sheets, required Register columns and variant selection.
- `tools/install_packages.R` to install the required R packages.
- `tools/generate_coursefile_metadata.R`, a pre-render hook that writes
  `_metadata.yml` from the Config sheet before every render.
- `tools/dump_outline.js` to print a rendered PDF's bookmark tree.
- VS Code build tasks for rendering from the Config sheet or with a manual
  profile override.
- Sample PDFs for all three variants in `sample-output/`.

## [0.0.4] - 2026-11-15

### Added

- Laboratory chapters for course information, CO attainment and the course
  exit survey, plus fill-in outlines for the lab schedule, list of
  experiments, additional experiment, laboratory manual and continuous
  evaluation sheet.

## [0.0.3] - 2026-11-15

### Added

- Theory chapters covering the quality policy, vision and mission, faculty
  timetable, student list, course information, lesson plan, question bank,
  home assignments, quiz bank, CAE-I, CAE-II and PUT question papers,
  previous university papers, CO assessment plan, CO attainment, slow and
  fast learners, innovative teaching-learning practices, attendance record,
  sample evaluated sheets, lecture notes and the student feedback survey.
- Shared R helpers (`_data_helpers.R`, `_data_helpers_course_tables.R`) that
  read the workbook and render its tables.
- Demo workbook (`DEMO_BMC101_Course_Workbook.xlsx`) with a
  `0.CourseFile_Config` sheet that supplies every per-course value and
  selects the variant from `subject-type` and `faculty-role`.
- Placeholder evidence images and folders. All demo data is fictitious.

## [0.0.2] - 2026-11-15

### Added

- Quarto book project (`_quarto.yml`, `index.qmd`) with three profiles built
  from one codebase: Course Coordinator (full file), Subject Teacher
  (reduced file) and Laboratory Course.
- `coursefile.schema` in `_quarto.yml`, which defines the workbook's sheet
  names, cell ranges and Register column overrides in one place.
- Institute and department branding (logo, header, footer, programme)
  configurable under `coursefile:` in `_quarto.yml`, with no LaTeX edits.

## [0.0.1] - 2026-11-15

### Added

- `gcet-course-file` Quarto extension: a branded PDF format with a cover
  page, running header and footer, and a `{{< signature >}}` shortcode for
  the Faculty / HOD signature block.
- MIT licence and `.gitignore`.

[Unreleased]: https://github.com/ResearchInfuser/gcet-course-file-template/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/ResearchInfuser/gcet-course-file-template/compare/v0.0.5...v0.1.0
[0.0.5]: https://github.com/ResearchInfuser/gcet-course-file-template/compare/v0.0.4...v0.0.5
[0.0.4]: https://github.com/ResearchInfuser/gcet-course-file-template/compare/v0.0.3...v0.0.4
[0.0.3]: https://github.com/ResearchInfuser/gcet-course-file-template/compare/v0.0.2...v0.0.3
[0.0.2]: https://github.com/ResearchInfuser/gcet-course-file-template/compare/v0.0.1...v0.0.2
[0.0.1]: https://github.com/ResearchInfuser/gcet-course-file-template/releases/tag/v0.0.1
