# Abre o Simple Browser dentro do Cursor (não no Chrome/Edge)
$Url = "http://localhost:3456"

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
}
"@

$proc = Get-Process -Name "Cursor" -ErrorAction SilentlyContinue |
  Where-Object { $_.MainWindowHandle -ne 0 } |
  Select-Object -First 1

if (-not $proc) {
  Write-Host "Cursor nao encontrado. Abra o Cursor e rode de novo."
  exit 1
}

[Win32]::ShowWindow($proc.MainWindowHandle, 9) | Out-Null
[Win32]::SetForegroundWindow($proc.MainWindowHandle) | Out-Null
Start-Sleep -Milliseconds 500

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.SendKeys]::SendWait("^+p")
Start-Sleep -Milliseconds 700
[System.Windows.Forms.SendKeys]::SendWait("Simple Browser: Show")
Start-Sleep -Milliseconds 900
[System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
Start-Sleep -Milliseconds 800
[System.Windows.Forms.SendKeys]::SendWait($Url)
Start-Sleep -Milliseconds 300
[System.Windows.Forms.SendKeys]::SendWait("{ENTER}")

Write-Host "Preview aberto no Cursor: $Url"
