# GCET Course File Quarto Extension

The branded PDF format used by the course file template:

- Title page built from the `coursefile:` metadata (institution, department,
  session, course code, faculty name, logo)
- Table of contents in the front matter
- Running header and footer on every page
- A `{{< signature >}}` shortcode that prints the Faculty / HOD signature
  block, using `coursefile.faculty-name` and `coursefile.hod-name`

## Usage

In `_quarto.yml`:

```yaml
format:
  gcet-course-file-pdf:
    classoption:
      - oneside                 # or twoside for double-sided printing
      - gcet-no-page-numbers    # or gcet-page-numbers
      - gcet-blank-toc-pages    # or gcet-show-toc-pages
```

Then render:

```bash
quarto render --to gcet-course-file-pdf
```

## Notes

- If `coursefile.logo` is not provided, the title page renders without a logo.
- The page header (institution name and address) and footer (department
  name) are set in `GcetCourseFile.cls`. Edit that file to adapt the format
  to another institution or department.
- Class options `gcetlogo-small`, `gcetlogo-medium` and `gcetlogo-large`
  control the header logo size.
