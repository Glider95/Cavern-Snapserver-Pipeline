# Cavern Snapserver Pipeline - Windows x64 PowerShell Script
# Advanced pipeline management with better error handling and logging

param(
    [int]$Channels = 2,
    [string]$Codec = "eac3",
    [string]$LogDir = "$env:TEMP\cavern_logs",
    [switch]$Help
)

if ($Help) {
    Write-Host @"
Cavern Snapserver Pipeline - Windows x64

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

"@
    exit 0
}

# Create log directory
if (!(Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

$audioProcessorPath = "bin\audio-processor\audio-processor.exe"
$fifoToPipePath = "bin\FifoToPipe\FifoToPipe.exe"
$pipeToFifoPath = "bin\PipeToFifo\PipeToFifo.exe"

# Check if executables exist
$requiredFiles = @($audioProcessorPath, $fifoToPipePath, $pipeToFifoPath)
foreach ($file in $requiredFiles) {
    if (!(Test-Path $file)) {
        Write-Error "Required executable not found: $file"
        Write-Host "Please run build-win-x64.bat first to build the Windows x64 executables."
        exit 1
    }
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Cavern Snapserver Pipeline - Windows x64" -ForegroundColor Cyan  
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  Channels: $Channels" 
Write-Host "  Codec: $Codec"
Write-Host "  Log Directory: $LogDir"
Write-Host ""

# Cleanup any existing processes
Write-Host "Cleaning up existing processes..." -ForegroundColor Yellow
Get-Process -Name "audio-processor", "FifoToPipe", "PipeToFifo" -ErrorAction SilentlyContinue | Stop-Process -Force

Write-Host "Starting Audio Processor..." -ForegroundColor Green
$audioProcessorLog = Join-Path $LogDir "audio_processor.log"

# Start the audio processor
$audioProcessorProcess = Start-Process -FilePath $audioProcessorPath -ArgumentList "$Channels", "$Codec" -RedirectStandardOutput $audioProcessorLog -RedirectStandardError $audioProcessorLog -PassThru -WindowStyle Hidden

if ($audioProcessorProcess) {
    Write-Host "Audio processor started (PID: $($audioProcessorProcess.Id))" -ForegroundColor Green
} else {
    Write-Error "Failed to start audio processor"
    exit 1
}

# Wait a moment for the audio processor to initialize
Start-Sleep -Seconds 2

Write-Host ""
Write-Host "Pipeline is ready!" -ForegroundColor Green
Write-Host ""
Write-Host "Manual connection instructions:" -ForegroundColor Yellow
Write-Host ""
Write-Host "To feed audio input:" -ForegroundColor White
Write-Host "  $fifoToPipePath <input_file_or_source>" -ForegroundColor Gray
Write-Host ""
Write-Host "To consume processed output:" -ForegroundColor White  
Write-Host "  $pipeToFifoPath <output_file_or_destination>" -ForegroundColor Gray
Write-Host ""
Write-Host "Example workflow:" -ForegroundColor Yellow
Write-Host "  # Terminal 1: Feed input"
Write-Host "  $fifoToPipePath audio_input.raw" -ForegroundColor Gray
Write-Host ""
Write-Host "  # Terminal 2: Capture output"  
Write-Host "  $pipeToFifoPath processed_output.raw" -ForegroundColor Gray
Write-Host ""
Write-Host "Named pipes created:" -ForegroundColor Yellow
Write-Host "  Input:  \\.\pipe\cavern-audio-input"
Write-Host "  Output: \\.\pipe\cavern-audio-output"
Write-Host ""
Write-Host "Logs are being written to: $LogDir" -ForegroundColor Yellow
Write-Host ""
Write-Host "Press Ctrl+C to stop the pipeline..." -ForegroundColor Red

# Wait for user to stop
try {
    while ($audioProcessorProcess -and !$audioProcessorProcess.HasExited) {
        Start-Sleep -Seconds 1
    }
} catch {
    Write-Host "`nStopping pipeline..." -ForegroundColor Yellow
}

# Cleanup
Write-Host "Stopping all pipeline processes..." -ForegroundColor Yellow
Get-Process -Name "audio-processor", "FifoToPipe", "PipeToFifo" -ErrorAction SilentlyContinue | Stop-Process -Force

Write-Host "Pipeline stopped." -ForegroundColor Green