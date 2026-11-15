# Locates Rscript.exe and runs tools/render_course_file.R, so the VS Code
# build task (and anyone at a plain shell) works even when Rscript isn't on
# PATH -- Quarto itself locates R some other way internally for its own
# pre-render/knitr needs, but a plain `Rscript` shell command does not.
#
# Usage: pwsh tools/render_course_file.ps1 [format]
# [format] defaults to "gcet-course-file-pdf" (passed straight through to
# render_course_file.R; try "docx" for a Word copy).

param(
	[string]$Format = "gcet-course-file-pdf"
)

$ErrorActionPreference = "Stop"

function Find-Rscript {
	$cmd = Get-Command Rscript -ErrorAction SilentlyContinue
	if ($cmd) { return $cmd.Source }

	$found = Get-ChildItem "C:\Program Files\R" -Directory -ErrorAction SilentlyContinue |
		Sort-Object Name -Descending |
		ForEach-Object { Join-Path $_.FullName "bin\Rscript.exe" } |
		Where-Object { Test-Path $_ } |
		Select-Object -First 1

	if ($found) { return $found }

	throw "Rscript.exe not found on PATH or under 'C:\Program Files\R\'. Install R from https://cran.r-project.org/, or add Rscript to PATH, then retry."
}

$rscript = Find-Rscript
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$renderScript = Join-Path $scriptDir "render_course_file.R"

& $rscript $renderScript $Format
exit $LASTEXITCODE
