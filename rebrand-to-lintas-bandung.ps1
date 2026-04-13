# Rebrand lengkap portal berita menjadi Lintas Bandung
# Menjaga encoding UTF-8, backup articles.json, dan merapikan branding + warna

$ErrorActionPreference = 'Stop'
$WorkspaceRoot = $PSScriptRoot
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

$FileChanges = [ordered]@{
    main_pages = 0
    article_pages = 0
    css = 0
    package = 0
    docs = 0
}

function Read-Utf8File {
    param([string]$Path)
    return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
}

function Write-Utf8File {
    param(
        [string]$Path,
        [string]$Content
    )
    [System.IO.File]::WriteAllText($Path, $Content, $Utf8NoBom)
}

function Normalize-Text {
    param([string]$Content)

    $Content = $Content.Replace([char]0x201C, '"')
    $Content = $Content.Replace([char]0x201D, '"')
    $Content = $Content.Replace([char]0x2018, "'")
    $Content = $Content.Replace([char]0x2019, "'")
    $Content = $Content.Replace([char]0x2013, '-')
    $Content = $Content.Replace([char]0x2014, '-')
    $Content = $Content.Replace([char]0x00A0, ' ')
    $Content = $Content.Replace([char]0xFFFD, ' ')
    return $Content
}

function Apply-CommonReplacements {
    param([string]$Content)

    $replacePairs = @(
        @{ Old = 'Warta Janten Team'; New = 'Lintas Bandung Team' }
        @{ Old = 'Warta Janten'; New = 'Lintas Bandung' }
        @{ Old = 'WartaJanten'; New = 'LintasBandung' }
        @{ Old = 'wartajanten'; New = 'lintasbandung' }
        @{ Old = 'WARTA JANTEN'; New = 'LINTAS BANDUNG' }
        @{ Old = 'Indonesia Daily'; New = 'Lintas Bandung' }
        @{ Old = 'IndonesiaDaily'; New = 'LintasBandung' }
        @{ Old = 'indonesiadaily'; New = 'lintasbandung' }
        @{ Old = 'indonesiadaily@gmail.com'; New = 'lintasbandung@gmail.com' }
        @{ Old = 'wartajanten@gmail.com'; New = 'lintasbandung@gmail.com' }
        @{ Old = '#065F46'; New = '#047857' }
        @{ Old = '#065f46'; New = '#047857' }
        @{ Old = '#022C22'; New = '#064E3B' }
        @{ Old = '#022c22'; New = '#064E3B' }
        @{ Old = '#1E3A5F'; New = '#7F1F1F' }
        @{ Old = '#1e3a5f'; New = '#7F1F1F' }
        @{ Old = '#FFCC00'; New = '#047857' }
        @{ Old = '#ffcc00'; New = '#047857' }
        @{ Old = '#1E2024'; New = '#064E3B' }
        @{ Old = '#1e2024'; New = '#064E3B' }
        @{ Old = '#31404B'; New = '#7F1F1F' }
        @{ Old = '#31404b'; New = '#7F1F1F' }
        @{ Old = '#b38f00'; New = '#7F1F1F' }
    )

    foreach ($pair in $replacePairs) {
        $Content = $Content -replace [regex]::Escape($pair.Old), $pair.New
    }

    $Content = $Content -replace 'https://(www\.)?twitter\.com/[A-Za-z0-9_@-]+', 'https://twitter.com/lintasbandung'
    $Content = $Content -replace 'https://(www\.)?facebook\.com/[A-Za-z0-9_@-]+', 'https://facebook.com/lintasbandung'
    $Content = $Content -replace 'https://(www\.)?instagram\.com/[A-Za-z0-9_@-]+', 'https://instagram.com/lintasbandung'
    $Content = $Content -replace 'https://(www\.)?youtube\.com/@?[A-Za-z0-9_@-]+', 'https://youtube.com/@lintasbandung'
    $Content = $Content -replace 'https://(www\.)?linkedin\.com/company/[A-Za-z0-9_@-]+', 'https://linkedin.com/company/lintasbandung'

    $Content = $Content -replace '(--primary\s*:\s*)#[0-9A-Fa-f]{6}', '$1#047857'
    $Content = $Content -replace '(--dark\s*:\s*)#[0-9A-Fa-f]{6}', '$1#064E3B'
    $Content = $Content -replace '(--secondary\s*:\s*)#[0-9A-Fa-f]{6}', '$1#7F1F1F'

    return $Content
}

$LogoMarkup = @'
<span style="display: inline-block; line-height: 1;">
    <span style="font-weight: 700; color: #047857; font-size: 24px; letter-spacing: -0.5px;">LINTAS</span>
    <span style="color: #7F1F1F; font-weight: 500; font-size: 16px; letter-spacing: 0.5px; margin-left: 4px;">BANDUNG</span>
</span>
'@

Write-Host '=== Rebrand Lintas Bandung dimulai ==='
Write-Host "Root: $WorkspaceRoot"

# Backup wajib
$ArticlesPath = Join-Path $WorkspaceRoot 'articles.json'
$ArticlesBackupPath = Join-Path $WorkspaceRoot 'articles.json.bak'
if (Test-Path $ArticlesPath) {
    Copy-Item -Path $ArticlesPath -Destination $ArticlesBackupPath -Force
    Write-Host "Backup dibuat: $ArticlesBackupPath"
}

# HTML: gunakan pola yang diminta
Get-ChildItem -Path $WorkspaceRoot -Recurse -Include *.html -File |
    Where-Object { $_.FullName -notmatch '\\node_modules\\' -and $_.Name -notlike '*.bak*' } |
    ForEach-Object {
        $file = $_
        $content = Read-Utf8File -Path $file.FullName
        $original = $content

        $content = Normalize-Text -Content $content
        $content = Apply-CommonReplacements -Content $content

        $content = [regex]::Replace(
            $content,
            '(?is)(<a\b[^>]*class="[^"]*\bnavbar-brand\b[^"]*"[^>]*>).*?(</a>)',
            {
                param($match)
                return "$($match.Groups[1].Value)`r`n            $LogoMarkup`r`n        $($match.Groups[2].Value)"
            }
        )

        $content = [regex]::Replace($content, '(?is)<img\b[^>]*src="(?:\.\./)?img/logo\.png"[^>]*>\s*', '')
        $content = $content -replace 'alt="(?:LintasBandung|WartaJanten|IndonesiaDaily|logo)"', 'alt="LintasBandung"'

        if ($content -ne $original) {
            Write-Utf8File -Path $file.FullName -Content $content
            if ($file.FullName -match '\\article\\') {
                $FileChanges.article_pages++
            }
            else {
                $FileChanges.main_pages++
            }
        }
    }

# CSS utama dan minified
Get-ChildItem -Path $WorkspaceRoot -Recurse -Include *.css -File |
    Where-Object { $_.FullName -notmatch '\\node_modules\\' } |
    ForEach-Object {
        $file = $_
        $content = Read-Utf8File -Path $file.FullName
        $original = $content

        $content = Normalize-Text -Content $content
        $content = Apply-CommonReplacements -Content $content

        if ($content -ne $original) {
            Write-Utf8File -Path $file.FullName -Content $content
            $FileChanges.css++
        }
    }

# Package metadata
Get-ChildItem -Path $WorkspaceRoot -Recurse -Include package.json,package-lock.json -File |
    ForEach-Object {
        $file = $_
        $content = Read-Utf8File -Path $file.FullName
        $original = $content

        $content = Normalize-Text -Content $content
        $content = Apply-CommonReplacements -Content $content
        $content = $content -replace '"name"\s*:\s*"[^"]*wartajanten-article-generator[^"]*"', '"name": "lintasbandung-article-generator"'
        $content = $content -replace '"name"\s*:\s*"indonesiadaily-article-generator"', '"name": "lintasbandung-article-generator"'
        $content = $content -replace '"name"\s*:\s*"wartajanten"', '"name": "lintasbandung"'
        $content = $content -replace '"name"\s*:\s*"indonesiadaily"', '"name": "lintasbandung"'

        if ($content -ne $original) {
            Write-Utf8File -Path $file.FullName -Content $content
            $FileChanges.package++
        }
    }

# Dokumen / konfigurasi
Get-ChildItem -Path $WorkspaceRoot -Recurse -Include *.md,*.toml,*.txt -File |
    Where-Object { $_.FullName -notmatch '\\node_modules\\' -and $_.Name -notlike '*.bak*' } |
    ForEach-Object {
        $file = $_
        $content = Read-Utf8File -Path $file.FullName
        $original = $content

        $content = Normalize-Text -Content $content
        $content = Apply-CommonReplacements -Content $content

        if ($content -ne $original) {
            Write-Utf8File -Path $file.FullName -Content $content
            $FileChanges.docs++
        }
    }

Write-Host ''
Write-Host '=== Ringkasan Rebrand ==='
Write-Host ("Main pages updated : {0}" -f $FileChanges.main_pages)
Write-Host ("Article pages updated : {0}" -f $FileChanges.article_pages)
Write-Host ("CSS files updated  : {0}" -f $FileChanges.css)
Write-Host ("Package files updated: {0}" -f $FileChanges.package)
Write-Host ("Docs/config updated : {0}" -f $FileChanges.docs)
Write-Host 'Rebrand Lintas Bandung selesai ✅'
