param([switch]$Elevated)

function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if ((Test-Admin) -eq $false)  {
    if ($elevated) {
        # tried to elevate, did not work, aborting
    } else {
        Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -noexit -file "{0}" -elevated' -f ($myinvocation.MyCommand.Definition))
    }
    exit
}

'running with full privileges'

# Get process list before VR
$allProcesses = Get-Process | Select-Object -Property ProcessName, Id, CPU, VM, WS, StartTime

# Filter process to find adobe and kill it
Write-Host "Killing adobe processes..."
$allProcesses | Where-Object { $_.ProcessName -match "adobe" } | ForEach-Object { Stop-Process -Id $_.Id -Force }

# Filter process to find elgato
$elgatoProcesses = $allProcesses | Where-Object { $_.ProcessName -match "elgato" }
# The elgato processes need to be killed in a specific order
$elgatoProcesses | Sort-Object { $_.ProcessName -match 'watcher' }, ProcessName -Descending | ForEach-Object {
    Write-Host "Killing process: $($_.ProcessName) with ID: $($_.Id)"
    Start-Sleep -Seconds 1
    Stop-Process -Id $_.Id -Force
}

Write-Host "Killing icue processes..."
# Filter process to find corsair icue
$iCue = $allProcesses | Where-Object { $_.ProcessName -match "icue" }

# Kill the ICue process
$iCue | ForEach-Object {
    $processName = $_.ProcessName
    $processId = $_.Id
    Write-Host "Killing process: $processName with ID: $processId"
    Start-Sleep -Seconds 1
    Stop-Process -Id $processId -Force
}

# Get and stop Corsair services
Write-Host "Stopping Corsair services..."
Get-Service | Where-Object { $_.Name -like "*corsair*" } | ForEach-Object { Stop-Service -Name $_.Name }

# Kill any remaining corsair processes
Write-Host "Killing any remaining Corsair processes..."
$allProcesses | Where-Object { $_.ProcessName -match "corsair" } | ForEach-Object {Stop-Process -Id $_.Id -Force}


# Stop macrium service
Write-Host "Stopping Macrium Service..."
Get-Service | Where-Object { $_.Name -like "*macrium*" } | ForEach-Object { Stop-Service -Name $_.Name }



