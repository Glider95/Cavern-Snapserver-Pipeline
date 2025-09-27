# Cavern Audio Processor - Windows x64 PowerShell Script
# Advanced audio processor management with better error handling and logging

param(
    [int]$Channels = 2,
    [string]$Codec = "eac3",
    [string]$LogDir = "$env:TEMP\cavern_logs",
    [switch]$Help
)

if ($Help) {
    Write-Host @"
Cavern Audio Processor - Windows x64

Usage: .\run_pipeline.ps1 [-Channels <int>] [-Codec <string>] [-LogDir <string>] [-Help]

Parameters:
  -Channels  Number of output channels (default: 2)
  -Codec     Audio codec: eac3, ac3, etc. (default: eac3)  
  -LogDir    Directory for log files (default: %TEMP%\cavern_logs)
  -Help      Show this help message

Examples:
  .\run_pipeline.ps1                           # Start with defaults
  .\run_pipeline.ps1 -Channels 6 -Codec ac3   # 6-channel AC3 output
  .\run_pipeline.ps1 -LogDir C:\logs           # Custom log directory

Media Player Integration:
  Use FFmpeg to connect media players to the Cavern processor:
  
  # Stream from media file to processor
  ffmpeg -i movie.mkv -map 0:a:0 -f data \\.\pipe\cavern-audio-input
  
  # Stream processed audio to speakers
  ffmpeg -f data -i \\.\pipe\cavern-audio-output -f wav - | ffplay -

"@
    exit 0
}

# Create log directory
if (!(Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

$audioProcessorPath = "bin\audio-processor\audio-processor.exe"

# Check if executable exists
if (!(Test-Path $audioProcessorPath)) {
    Write-Error "Required executable not found: $audioProcessorPath"
    Write-Host "Please run build-win-x64.bat first to build the Windows x64 executable."
    exit 1
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Cavern Audio Processor - Windows x64" -ForegroundColor Cyan  
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  Channels: $Channels" 
Write-Host "  Codec: $Codec"
Write-Host "  Log Directory: $LogDir"
Write-Host ""

# Cleanup any existing processes
Write-Host "Cleaning up existing processes..." -ForegroundColor Yellow
Get-Process -Name "audio-processor" -ErrorAction SilentlyContinue | Stop-Process -Force

Write-Host "Starting Cavern Audio Processor..." -ForegroundColor Green
$audioProcessorLog = Join-Path $LogDir "audio_processor.log"

# Start the audio processor
$audioProcessorProcess = Start-Process -FilePath $audioProcessorPath -ArgumentList "$Channels", "$Codec" -RedirectStandardOutput $audioProcessorLog -RedirectStandardError $audioProcessorLog -PassThru -WindowStyle Normal

if ($audioProcessorProcess) {
    Write-Host "Audio processor started (PID: $($audioProcessorProcess.Id))" -ForegroundColor Green
} else {
    Write-Error "Failed to start audio processor"
    exit 1
}

# Wait a moment for the audio processor to initialize
Start-Sleep -Seconds 2

Write-Host ""
Write-Host "Processor is ready!" -ForegroundColor Green
Write-Host ""
Write-Host "Named pipes created:" -ForegroundColor Yellow
Write-Host "  Input:  \\.\pipe\cavern-audio-input"
Write-Host "  Output: \\.\pipe\cavern-audio-output"
Write-Host ""
Write-Host "=== Media Player Integration Examples ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Stream from media file:" -ForegroundColor White
Write-Host "  ffmpeg -i movie.mkv -map 0:a:0 -f data \\.\pipe\cavern-audio-input" -ForegroundColor Gray
Write-Host ""
Write-Host "Play processed audio:" -ForegroundColor White  
Write-Host "  ffmpeg -f data -i \\.\pipe\cavern-audio-output -f wav - | ffplay -" -ForegroundColor Gray
Write-Host ""
Write-Host "Save processed audio to file:" -ForegroundColor White
Write-Host "  ffmpeg -f data -i \\.\pipe\cavern-audio-output output.wav" -ForegroundColor Gray
Write-Host ""
Write-Host "For VLC/Media Players:" -ForegroundColor Yellow
Write-Host "  Install VB-Cable or similar virtual audio cable software"
Write-Host "  Set VLC output to virtual cable, then use FFmpeg to capture"
Write-Host ""
Write-Host "Logs are being written to: $LogDir" -ForegroundColor Yellow
Write-Host ""
Write-Host "Press Ctrl+C to stop the processor..." -ForegroundColor Red

# Wait for user to stop
try {
    while ($audioProcessorProcess -and !$audioProcessorProcess.HasExited) {
        Start-Sleep -Seconds 1
    }
} catch {
    Write-Host "`nStopping processor..." -ForegroundColor Yellow
}

# Cleanup
Write-Host "Stopping audio processor..." -ForegroundColor Yellow
Get-Process -Name "audio-processor" -ErrorAction SilentlyContinue | Stop-Process -Force

Write-Host "Processor stopped." -ForegroundColor Green