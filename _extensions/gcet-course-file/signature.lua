-- signature.lua
-- GCET Course File: Faculty and HOD signature block.
--
-- The names come from the workbook's Config sheet ("faculty-name" and
-- "hod-name" rows), which tools/generate_coursefile_metadata.R writes into
-- the `coursefile:` metadata block before every render. A top-level
-- `faculty-name` / `hod-name` metadata key is also honoured. If a name is
-- not set, the line under the signature rule is simply left blank.

local function meta_name(meta, key)
  if not meta then return "" end
  local coursefile = meta["coursefile"]
  local value = (coursefile and coursefile[key]) or meta[key]
  if value then
    return pandoc.utils.stringify(value)
  end
  return ""
end

local function latex_escape(s)
  return s:gsub("\\", "\\textbackslash{}")
          :gsub("([%%$#&_{}])", "\\%1")
end

return {
  ["signature"] = function(args, kwargs, meta)
    local faculty_name = meta_name(meta, "faculty-name")
    local hod_name = meta_name(meta, "hod-name")

    if quarto.doc.is_format("pdf") then
      -- \gcetsignatureblock is defined in GcetCourseFile.cls, which also
      -- uses it for the table of contents page.
      return pandoc.RawBlock("latex", "\\gcetsignatureblock{"
        .. latex_escape(faculty_name) .. "}{" .. latex_escape(hod_name) .. "}")
    end

    local md = string.format([[
| | |
|:---:|:---:|
| **Signature of Faculty** | **Signature of HOD** |
| %s | %s |
]], faculty_name, hod_name)

    return pandoc.read(md, "markdown").blocks
  end
}
