& 'D:\mygoatmanager\fix_flutter.bat'

# Add Defender exclusions (requires admin)
Try {
    Add-MpPreference -ExclusionPath 'D:\flutter\bin\cache' -ErrorAction Stop
    Add-MpPreference -ExclusionPath 'D:\mygoatmanager\build' -ErrorAction Stop
    Write-Output "Defender exclusions added"
} Catch {
    Write-Output "Failed to add Defender exclusions: $_"
}
