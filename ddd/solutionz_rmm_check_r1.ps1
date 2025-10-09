# ============================
# Solutionz INC RMM Connectivity Check
# ============================

# --- Display logo and welcome (excluded from transcript) ---
$logo = @'
  _____   ____    _      _    _   _____   _    ____   __     __
 / ____| / __ \  | |    | |  | | |_   _| | |  / __ \ |  \   |  |  ______
| (___  | |  | | | |    | |  | |   | |   | | | |  | ||   \  |  | |___  /
 \___ \ | |  | | | |    | |  | |   | |   | | | |  | ||  |\ \|  |    / /
 ____) || |__| | | |___ | |__| |   | |   | | | |__| ||  | \    |  / /__
|_____/  \____/  |_____| \____/    |_|   |_|  \____/ |__|   \__| /_____|

Welcome to the Solutionz INC diagnostic script.
'@
Write-Host $logo -ForegroundColor Cyan

Write-Host "`n======================================================================"
Write-Host "Solutionz INC is now checking RMM connections. Please wait a moment..."
Write-Host "========================================================================`n"

# --- Define file paths ---
$logFile = "$env:TEMP\RMM_Connectivity_Log.txt"
$downloads = Join-Path $env:USERPROFILE "Downloads"
$zipPath = Join-Path $downloads "RMM_Connectivity_Report.zip"
$logCopyPath = Join-Path $downloads "RMM_Connectivity_Log.txt"

# --- Start transcript ---
$transcriptStarted = $false
try {
    Start-Transcript -Path $logFile
    $transcriptStarted = $true
} catch {
    # Silent fail
}

# --- Test Functions ---
function Test-TCPPort {
    param ([string]$TargetHost, [int]$Port)
    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $tcpClient.Connect($TargetHost, $Port)
        $tcpClient.Close()
        Write-Host "${TargetHost}:${Port} - TCP OPEN"
    } catch {
        Write-Host "${TargetHost}:${Port} - TCP CLOSED"
    }
}

function Test-ICMP {
    param ([string]$TargetHost)
    if (Test-Connection -ComputerName $TargetHost -Count 2 -Quiet) {
        Write-Host "$TargetHost - ICMP REACHABLE"
    } else {
        Write-Host "$TargetHost - ICMP UNREACHABLE"
    }
}

function Test-DNS {
    param ([string]$TargetHost)
    try {
        $dns = Resolve-DnsName -Name $TargetHost -ErrorAction Stop
        Write-Host "$TargetHost - DNS RESOLVED to $($dns[0].IPAddress)"
    } catch {
        Write-Host "$TargetHost - DNS RESOLUTION FAILED"
    }
}

function Test-HTTP {
    param ([string]$TargetHost)
    try {
        $response = Invoke-WebRequest -Uri "https://$TargetHost" -UseBasicParsing -TimeoutSec 5
        Write-Host "$TargetHost - HTTP RESPONSE: $($response.StatusCode)"
    } catch {
        Write-Host "$TargetHost - HTTP FAILED"
    }
}

function Test-SSL {
    param ([string]$TargetHost)
    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient($TargetHost, 443)
        $sslStream = New-Object System.Net.Security.SslStream($tcpClient.GetStream(), $false, ({ $true }))
        $sslStream.AuthenticateAsClient($TargetHost)
        $cert = $sslStream.RemoteCertificate
        Write-Host "$TargetHost - SSL CERT VALID"
        $tcpClient.Close()
    } catch {
        Write-Host "$TargetHost - SSL CERT INVALID"
    }
}

function Test-UDPPort {
    param ([string]$TargetHost, [int]$Port)
    try {
        $udpClient = New-Object System.Net.Sockets.UdpClient
        $udpClient.Connect($TargetHost, $Port)
        $udpClient.Close()
        Write-Host "${TargetHost}:${Port} - UDP SENT (no response expected)"
    } catch {
        Write-Host "${TargetHost}:${Port} - UDP FAILED"
    }
}

# --- Connectivity Checks ---
Write-Host "`n--- GENERAL CONNECTIVITY ---"
Test-DNS -TargetHost "portal.domotz.com"
Test-HTTP -TargetHost "portal.domotz.com"
Test-SSL -TargetHost "portal.domotz.com"
Test-TCPPort -TargetHost "portal.domotz.com" -Port 443

Write-Host "`nChecking echo.domotz.com (ICMP)"
Test-DNS -TargetHost "echo.domotz.com"
Test-ICMP -TargetHost "echo.domotz.com"

Write-Host "`n--- API CONNECTIVITY ---"
Test-TCPPort -TargetHost "api-us-east-1-cell-1.domotz.com" -Port 443
Test-TCPPort -TargetHost "api-eu-west-1-cell-1.domotz.com" -Port 443

Write-Host "`n--- MESSAGING SERVICES ---"
Test-TCPPort -TargetHost "messaging-us-east-1-cell-1.domotz.com" -Port 5671
Test-TCPPort -TargetHost "messaging-eu-west-1-cell-1.domotz.com" -Port 5671

Write-Host "`n--- REMOTE CONNECTIONS ---"
$remoteHosts = @(
    "sshg.domotz.co",
    "us-east-1-sshg.domotz.co",
    "us-east-1-02-sshg.domotz.co",
    "us-west-2-sshg.domotz.co",
    "ap-southeast-2-sshg.domotz.co"
)
$samplePorts = @(32700, 40000, 50000, 57699)
foreach ($TargetHost in $remoteHosts) {
    foreach ($Port in $samplePorts) {
        Test-TCPPort -TargetHost $TargetHost -Port $Port
    }
}

Write-Host "`n--- PROVISIONING CHANNEL ---"
Test-TCPPort -TargetHost "provisioning.domotz.com" -Port 4505
Test-TCPPort -TargetHost "provisioning.domotz.com" -Port 4506
Test-TCPPort -TargetHost "login.ubuntu.com" -Port 443
Test-TCPPort -TargetHost "pool.sks-keyservers.net" -Port 11371
Test-TCPPort -TargetHost "messaging.orchestration.domotz.com" -Port 5671
Test-TCPPort -TargetHost "api.orchestration.wl-pro.com" -Port 443
Test-TCPPort -TargetHost "tunny.domotz.org" -Port 55022

Write-Host "`n--- UPDATES FROM CANONICAL ---"
$canonicalHosts = @(
    "api.snapcraft.io",
    "serial-vault-partners.canonical.com",
    "storage.snapcraftcontent.com",
    "canonical-lgw01.cdn.snapcraftcontent.com",
    "canonical-lcy01.cdn.snapcraftcontent.com",
    "canonical-lcy02.cdn.snapcraftcontent.com",
    "canonical-bos01.cdn.snapcraftcontent.com",
    "upload.apps.ubuntu.com"
)
foreach ($TargetHost in $canonicalHosts) {
    Test-TCPPort -TargetHost $TargetHost -Port 443
}

Write-Host "`n--- HTTPS SERVERS ---"
$httpsHosts = @(
    "www.google.com",
    "www.fast.com",
    "www.canonical.com",
    "www.redhat.com"
)
foreach ($TargetHost in $httpsHosts) {
    Test-TCPPort -TargetHost $TargetHost -Port 443
}

Write-Host "`n--- NTP SERVERS (UDP 123) ---"
$ntpHosts = @(
    "ntp.ubuntu.com",
    "0.pool.ntp.org",
    "1.pool.ntp.org"
)
foreach ($TargetHost in $ntpHosts) {
    Test-UDPPort -TargetHost $TargetHost -Port 123
}

Write-Host "`n--- SPEEDTEST SERVICES ---"
Test-TCPPort -TargetHost "api.fast.com" -Port 443
Test-TCPPort -TargetHost "ichnaea-web.netflix.com" -Port 443

Write-Host "`n========================================="
Write-Host "Connectivity check completed."
Write-Host "========================================="

if ($success) {
    Write-Host "A ZIP file has been created:"
    Write-Host "$zipPath"
    Write-Host ""
    Write-Host "Please email this file to: rmmadmins@solutionzinc.com"
    Write-Host "Subject: RMM Connectivity Report from $(hostname)"
    Write-Host ""
    Write-Host "Thank you for your time and support in verifying your connection."
    Write-Host "Have a wonderful day! 🙂"
} else {
    Write-Host "ZIP file creation failed."
    Write-Host "Please manually attach the log file located at:"
    Write-Host "$logFile"
    Write-Host ""
    Write-Host "Email to: rmmadmins@solutionzinc.com"
    Write-Host "Subject: RMM Connectivity Report from $(hostname)"
}
Write-Host "=========================================`n"

# Auto-open Downloads folder
Start-Process $downloads

# Stop transcript
if ($transcriptStarted) {
    try {
        Stop-Transcript
        Start-Sleep -Seconds 2
    } catch {
        # Silent fail
    }
}

# --- Create ZIP file from copied log ---
$logCopyPath = Join-Path $downloads "RMM_Connectivity_Log.txt"
Copy-Item -Path $logFile -Destination $logCopyPath -Force

try {
    Compress-Archive -Path $logCopyPath -DestinationPath $zipPath -Force
    Remove-Item $logCopyPath -Force
    $success = $true
} catch {
    $success = $false
}

# --- Confirm success ---
$success = Test-Path $zipPath

# --- Create ZIP file with retry logic ---
$downloads = Join-Path $env:USERPROFILE "Downloads"
$logCopyPath = Join-Path $downloads "RMM_Connectivity_Log.txt"

$maxRetries = 5
$retryCount = 0
$success = $false

while (-not $success -and $retryCount -lt $maxRetries) {
    try {
        Compress-Archive -Path $logCopyPath -DestinationPath $zipPath
        $success = $true
    } catch {
        Start-Sleep -Seconds 1
        $retryCount++
    }
}
