# Force-unblock and remove stuck Dart SDK folder, to be run as Administrator
Write-Output "Starting force-unblock script..."

# Stop known processes that might lock flutter/dart
$procs = Get-Process -Name dart,flutter,java -ErrorAction SilentlyContinue
if ($procs) {
    Write-Output "Stopping processes: $($procs.Name -join ', ')"
    $procs | ForEach-Object { Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue }
} else {
    Write-Output "No dart/flutter/java processes found"
}

$dartPath = 'D:\flutter\bin\cache\dart-sdk'
if (Test-Path $dartPath) {
    Write-Output "Taking ownership of $dartPath"
    try {
        & takeown.exe /F $dartPath /R /D Y 2>&1 | Write-Output
    } catch { Write-Output "takeown failed: $_" }

    # Grant current user full control
    $user = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    Write-Output "Granting full control to $user"
    try {
        & icacls.exe $dartPath /grant "$user:(F)" /T /C 2>&1 | Write-Output
    } catch { Write-Output "icacls failed: $_" }

    Write-Output "Clearing read-only attributes"
    try {
        Get-ChildItem -Path $dartPath -Recurse -Force | ForEach-Object { $_.Attributes = 'Normal' }
    } catch { Write-Output "Failed to clear attributes: $_" }

    Write-Output "Removing $dartPath"
    try {
        Remove-Item -LiteralPath $dartPath -Recurse -Force -ErrorAction Stop
        Write-Output "Removed $dartPath"
    } catch { Write-Output "Remove-Item failed: $_" }
} else {
    Write-Output "$dartPath not found"
}

# Also remove potential leftover stamp files
$stamps = @('D:\flutter\bin\cache\engine-dart-sdk.stamp','D:\flutter\bin\cache\dart-sdk.stamp')
foreach ($s in $stamps) {
    if (Test-Path $s) { Remove-Item $s -Force -ErrorAction SilentlyContinue; Write-Output "Removed $s" }
}

Write-Output "Force-unblock script finished."
