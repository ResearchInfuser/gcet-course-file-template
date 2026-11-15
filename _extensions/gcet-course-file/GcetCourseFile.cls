%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GCET Course File Class
% Version 1.0.0
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{GcetCourseFile}[2026/04/14 v1.0 GCET Course File Class]

% Page numbers enabled by default; disable with class option gcet-no-page-numbers.
\newif\ifgcetpagenumbers
\gcetpagenumberstrue
\DeclareOption{gcet-no-page-numbers}{\gcetpagenumbersfalse}
\DeclareOption{gcet-page-numbers}{\gcetpagenumberstrue}
\newif\ifgcettocpages
\gcettocpagestrue
\DeclareOption{gcet-blank-toc-pages}{\gcettocpagesfalse}
\DeclareOption{gcet-show-toc-pages}{\gcettocpagestrue}
\newcommand{\gcetpagefooter}{\ifgcetpagenumbers\thepage\fi}
\newcommand{\gcettocpage}[1]{\ifgcettocpages#1\fi}
\newcommand{\GcetLogoHeight}{1.35cm}
\DeclareOption{gcetlogo-small}{\renewcommand{\GcetLogoHeight}{1.20cm}}
\DeclareOption{gcetlogo-medium}{\renewcommand{\GcetLogoHeight}{1.35cm}}
\DeclareOption{gcetlogo-large}{\renewcommand{\GcetLogoHeight}{2.00cm}}
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{book}}
\ProcessOptions\relax
\LoadClass{book}

% Fully blank the auto-inserted page before a chapter in twoside mode: the
% kernel's default \cleardoublepage leaves the active page style (fancy) in
% place, so headers/footers/rule lines would otherwise still print on it.
\renewcommand{\cleardoublepage}{%
  \clearpage
  \if@twoside
    \ifodd\c@page\else
      \hbox{}%
      \thispagestyle{empty}%
      \newpage%
      \if@twocolumn\hbox{}\newpage\fi
    \fi
  \fi
}

% Core packages for stable PDF rendering and layout control
\RequirePackage{graphicx}
\RequirePackage[table]{xcolor}
\RequirePackage{array}
\RequirePackage{longtable}
\RequirePackage{fancyhdr}
\RequirePackage{titlesec}
\RequirePackage{etoc}
\RequirePackage{setspace}
\RequirePackage{pdfpages}

\setlength{\headheight}{70pt}

% Paragraph and spacing defaults
\setlength{\parindent}{0pt}
\setlength{\parskip}{6pt}
\onehalfspacing
\setcounter{secnumdepth}{1}

% Section title styling
\titleformat{\chapter}[block]
  {\normalfont\bfseries\LARGE\filcenter}
  {\thechapter}
  {0.4em}
  {}
\titlespacing*{\chapter}{0pt}{0pt}{8pt}

\titleformat{\section}
  {\normalfont\Large\bfseries}
  {\thesection}
  {0.6em}
  {}

\titleformat{\subsection}
  {\normalfont\large\bfseries}
  {}
  {0pt}
  {}

% Faculty / HOD signature block:
%   \gcetsignatureblock[gap above]{faculty name}{HOD name}
% The single definition used by both the {{< signature >}} shortcode
% (signature.lua) and the table of contents page. The gap above the
% signing lines defaults to 2cm.
\newcommand{\gcetsignatureblock}[3][\addvspace{2cm}]{%
  \par#1%
  \noindent
  \begin{minipage}[b]{0.46\linewidth}
    \centering
    \rule{0.90\linewidth}{0.4pt}\\[5pt]
    \textbf{Signature of Faculty}\\[3pt]
    \strut #2
  \end{minipage}%
  \hfill
  \begin{minipage}[b]{0.46\linewidth}
    \centering
    \rule{0.90\linewidth}{0.4pt}\\[5pt]
    \textbf{Signature of HOD}\\[3pt]
    \strut #3
  \end{minipage}%
  \par
}

\newcommand{\gcettableofcontents}{%
  \pdfbookmark[0]{\contentsname}{toc}%
  \clearpage%
  \pagenumbering{roman}%
  \begingroup
  \thispagestyle{gcettoc}%
  \pagestyle{gcettoc}%
  \etocglobaldefs%
  \hypersetup{hidelinks}%
  \setlength{\tabcolsep}{4pt}%
  \renewcommand{\arraystretch}{0.95}%
  \small%
  \etocsetnexttocdepth{section}%
  \etocsetstyle{chapter}
    {}
    {\etociffirst{\\\hline}{\\\hline}}
    {\etocnumber & \etocname & \gcettocpage{\etocpage}}
    {}
  \etocsetstyle{section}
    {}
    {\\}
    { & \hspace*{0.35em}\footnotesize\etocname & \footnotesize\gcettocpage{\etocpage}}
    {}
  \etocsettocstyle
    {\noindent\begin{longtable}{|>{\bfseries\centering\arraybackslash}p{1.4cm}|p{\dimexpr\textwidth-1.4cm-1.6cm-6\tabcolsep-4\arrayrulewidth\relax}|>{\centering\arraybackslash}p{1.6cm}|}
     \hline
     \multicolumn{3}{|c|}{\normalsize\bfseries\strut TABLE OF CONTENTS}\\\hline
     \textbf{S.No.} & \textbf{Content} & \textbf{Page No.}}
    {\\\hline\end{longtable}}
  \let\Etoc@contents\@empty%
  \etoctableofcontents
  \endgroup
  % Signature block directly below the table, as on the chapter pages.
  % \cfFacultyName / \cfHodName are defined in partials/title.tex from the
  % Config sheet's "faculty-name" / "hod-name" rows.
  % The gap is the usual 2cm, but may shrink so that a long table and the
  % signatures still share the page.
  \gcetsignatureblock[\nopagebreak\vspace{2cm minus 1.3cm}]{\@ifundefined{cfFacultyName}{}{\cfFacultyName}}{\@ifundefined{cfHodName}{}{\cfHodName}}%
  \clearpage%
  \pagenumbering{arabic}%
  \pagestyle{fancy}%
  \addtocontents{toc}{\protect\contentsline{chapter}{\protect\numberline{2}Table of Contents}{\thepage}{toc}}%
}

% Header/footer text and logo.
% These are NOT meant to be edited here: partials/title.tex redefines them
% from the project's coursefile.* metadata (the workbook's Config sheet and
% _quarto.yml), in this order of preference:
%   \GcetHeaderInstitution  header-institution, else institution (uppercased)
%   \GcetHeaderAddress      header-address,     else institution-address
%   \GcetFooterText         footer-text,        else department
%   \GcetHeaderLogo         logo
% They start out empty, so the class itself carries no institute-specific
% text; anything left empty is simply left out of the header/footer.
\newcommand{\GcetHeaderInstitution}{}
\newcommand{\GcetHeaderAddress}{}
\newcommand{\GcetFooterText}{}
\newcommand{\GcetHeaderLogo}{}

% The two header cells, shared by the "fancy" and "plain" page styles. They
% are expanded when a page is shipped out, so they always pick up the values
% set later in the preamble by partials/title.tex.
\newcommand{\gcet@headlogo}{%
  \parbox[c][\headheight][c]{1.25in}{%
    \if\relax\detokenize\expandafter{\GcetHeaderLogo}\relax\else
      \includegraphics[height=\GcetLogoHeight]{\GcetHeaderLogo}%
    \fi
  }%
}
\newcommand{\gcet@headtitle}{%
  \parbox[c][\headheight][c]{\dimexpr\headwidth-1.35in\relax}{\centering%
    \large\textbf{\GcetHeaderInstitution}%
    \if\relax\detokenize\expandafter{\GcetHeaderAddress}\relax\else
      \\[-1pt]
      {\small\textit{\GcetHeaderAddress}}%
    \fi
  }%
}

% Header/footer styling
\pagestyle{fancy}
\fancyhf{}
\renewcommand{\headrulewidth}{0.4pt}
\renewcommand{\footrulewidth}{0.4pt}
\setlength{\headwidth}{\textwidth}
\fancyheadoffset[L]{0pt}
\fancyheadoffset[R]{0pt}
\fancyfootoffset[L]{0pt}
\fancyfootoffset[R]{0pt}
\renewcommand{\headrule}{\hbox to\headwidth{\rule{\textwidth}{\headrulewidth}}}
\renewcommand{\footrule}{\hbox to\headwidth{\rule{\textwidth}{\footrulewidth}}\vskip-\footrulewidth}
\setlength{\headsep}{6pt}
\fancyhead[L]{\gcet@headlogo}
\fancyhead[R]{\gcet@headtitle}

% Use chapter/section marks in running headers
\renewcommand{\chaptermark}[1]{\markboth{#1}{}}
\renewcommand{\sectionmark}[1]{\markright{#1}}

\fancyfoot[C]{\textit{\GcetFooterText}}
\fancyfoot[R]{\gcetpagefooter}

\fancypagestyle{gcettoc}{
  \fancyhf{}
  \renewcommand{\headrulewidth}{0pt}
  \renewcommand{\footrulewidth}{0pt}
  \fancyfoot[C]{\parbox[b]{\textwidth}{%
    \rule{\textwidth}{0.4pt}\\[-1pt]
    \makebox[\textwidth][c]{\textit{\GcetFooterText}}\makebox[0pt][r]{\gcetpagefooter}%
  }}
}

% Keep chapter-opening pages consistent with the main page style.
\fancypagestyle{plain}{
  \fancyhf{}
  \renewcommand{\headrulewidth}{0.4pt}
  \renewcommand{\footrulewidth}{0.4pt}
  \setlength{\headwidth}{\textwidth}
  \fancyheadoffset[L]{0pt}
  \fancyheadoffset[R]{0pt}
  \fancyfootoffset[L]{0pt}
  \fancyfootoffset[R]{0pt}
  \renewcommand{\headrule}{\hbox to\headwidth{\rule{\textwidth}{\headrulewidth}}}
  \renewcommand{\footrule}{\hbox to\headwidth{\rule{\textwidth}{\footrulewidth}}\vskip-\footrulewidth}
  \fancyhead[L]{\gcet@headlogo}
  \fancyhead[R]{\gcet@headtitle}
  \fancyfoot[C]{\textit{\GcetFooterText}}
  \fancyfoot[R]{\gcetpagefooter}
}

% Frontmatter defaults
\AtBeginDocument{%
  \let\tableofcontents\gcettableofcontents%
  \setlength{\footskip}{28pt}%
  \pagestyle{plain}%
}
