param(
  [string]$InstallDirectory = (Join-Path $env:LOCALAPPDATA "Programs\TrustLens"),
  [switch]$SkipShortcuts,
  [switch]$SkipSuccessDialog
)

$ErrorActionPreference = "Stop"
$legacyInstallDirectory = Join-Path $env:LOCALAPPDATA "Programs\Rede Segura"
$usingLegacyInstallDirectory = $false

try {
if (-not $PSBoundParameters.ContainsKey("InstallDirectory")) {
  $trustLensInstallDirectory = Join-Path $env:LOCALAPPDATA "Programs\TrustLens"
  $legacyInstallExists = Test-Path -LiteralPath $legacyInstallDirectory -PathType Container
  $trustLensInstallExists = Test-Path -LiteralPath $trustLensInstallDirectory -PathType Container
  if ($legacyInstallExists -and $trustLensInstallExists) {
    throw "Foram encontradas as pastas antiga e TrustLens. Para evitar instalações duplicadas, resolva a instalação existente antes de continuar."
  }
  if ($legacyInstallExists) {
    $InstallDirectory = $legacyInstallDirectory
    $usingLegacyInstallDirectory = $true
  }
}

$files = @(
  "TrustLens.exe"
)

  $runningProcesses = @(Get-Process -Name "RedeSegura", "TrustLens" -ErrorAction SilentlyContinue)
  if ($runningProcesses.Count -gt 0) {
    $processDetails = ($runningProcesses | ForEach-Object { "$($_.ProcessName) (PID $($_.Id))" }) -join ", "
    throw "Feche a aplicação antes de instalar a atualização: $processDetails"
  }

  New-Item -ItemType Directory -Path $installDirectory -Force | Out-Null
  foreach ($file in $files) {
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot $file) -Destination (Join-Path $installDirectory $file) -Force
  }

  $iconPath = Join-Path $installDirectory "TrustLens.ico"
  $iconProcess = Start-Process `
    -FilePath (Join-Path $installDirectory "TrustLens.exe") `
    -ArgumentList @("--export-icon", "`"$iconPath`"") `
    -Wait `
    -PassThru
  if ($iconProcess.ExitCode -ne 0 -or -not (Test-Path -LiteralPath $iconPath -PathType Leaf)) {
    throw "Não foi possível criar o ícone da aplicação."
  }

  if (-not $SkipShortcuts) {
    $shell = New-Object -ComObject WScript.Shell
    $shortcutDirectories = @(
      [Environment]::GetFolderPath("Programs"),
      [Environment]::GetFolderPath("Desktop")
    )
    foreach ($shortcutDirectory in $shortcutDirectories) {
      $shortcut = $shell.CreateShortcut((Join-Path $shortcutDirectory "TrustLens.lnk"))
      $shortcut.TargetPath = Join-Path $installDirectory "TrustLens.exe"
      $shortcut.Arguments = ""
      $shortcut.WorkingDirectory = $installDirectory
      $shortcut.Description = "Abrir a aplicação TrustLens"
      $shortcut.IconLocation = "$iconPath,0"
      $shortcut.Save()
    }

    $legacyApplicationPath = Join-Path $installDirectory "RedeSegura.exe"
    foreach ($shortcutDirectory in $shortcutDirectories) {
      $legacyShortcutPath = Join-Path $shortcutDirectory "Rede Segura.lnk"
      if (Test-Path -LiteralPath $legacyShortcutPath -PathType Leaf) {
        $legacyShortcut = $shell.CreateShortcut($legacyShortcutPath)
        if ($legacyShortcut.TargetPath -and
            [System.StringComparer]::OrdinalIgnoreCase.Equals(
              [System.IO.Path]::GetFullPath($legacyShortcut.TargetPath),
              [System.IO.Path]::GetFullPath($legacyApplicationPath))) {
          Remove-Item -LiteralPath $legacyShortcutPath -Force
        }
      }
    }
  }

  if ($usingLegacyInstallDirectory -and -not $SkipShortcuts) {
    $legacyApplicationPath = Join-Path $installDirectory "RedeSegura.exe"
    if (Test-Path -LiteralPath $legacyApplicationPath -PathType Leaf) {
      Remove-Item -LiteralPath $legacyApplicationPath -Force
    }
  }

  if (-not $SkipSuccessDialog) {
    Add-Type -AssemblyName PresentationFramework
    [System.Windows.MessageBox]::Show(
      "A aplicação TrustLens foi instalada. Abra o atalho com a logo no Ambiente de Trabalho ou no menu Iniciar.",
      "TrustLens instalada",
      [System.Windows.MessageBoxButton]::OK,
      [System.Windows.MessageBoxImage]::Information
    ) | Out-Null
  }
} catch {
  Add-Type -AssemblyName PresentationFramework
  [System.Windows.MessageBox]::Show(
    "Não foi possível instalar a TrustLens.`n`n$($_.Exception.Message)",
    "Erro de instalação",
    [System.Windows.MessageBoxButton]::OK,
    [System.Windows.MessageBoxImage]::Error
  ) | Out-Null
  exit 1
}
