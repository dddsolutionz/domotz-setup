# ============================
# Solutionz INC RMM Connectivity Check
# ============================

Write-Host "Solutionz INC is now checking RMM connections. Please wait a moment..."

# Function to test TCP port
function Test-TCPPort {
    param (
        [string]$TargetHost,
        [int]$Port
    )
    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $tcpClient.Connect($TargetHost, $Port)
        $tcpClient.Close()
        Write-Host "${TargetHost}:${Port} - TCP OPEN"
    } catch {
        Write-Host "${TargetHost}:${Port} - TCP CLOSED"
    }
}

# Function to test ICMP ping
function Test-ICMP {
    param (
        [string]$TargetHost
    )
    if (Test-Connection -ComputerName $TargetHost -Count 2 -Quiet) {
        Write-Host "$TargetHost - ICMP REACHABLE"
    } else {
        Write-Host "$TargetHost - ICMP UNREACHABLE"
    }
}

# Function to test DNS resolution
function Test-DNS {
    param (
        [string]$TargetHost
    )
    try {
        $dns = Resolve-DnsName -Name $TargetHost -ErrorAction Stop
        Write-Host "$TargetHost - DNS RESOLVED to $($dns[0].IPAddress)"
    } catch {
        Write-Host "$TargetHost - DNS RESOLUTION FAILED"
    }
}

# Function to test HTTP response
function Test-HTTP {
    param (
        [string]$TargetHost
    )
    try {
        $response = Invoke-WebRequest -Uri "https://$TargetHost" -UseBasicParsing -TimeoutSec 5
        Write-Host "$TargetHost - HTTP RESPONSE: $($response.StatusCode)"
    } catch {
        Write-Host "$TargetHost - HTTP FAILED"
    }
}

# Function to test SSL certificate
function Test-SSL {
    param (
        [string]$TargetHost
    )
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

# === General Domain Health Check ===
$generalHosts = @("portal.domotz.com", "echo.domotz.com")
foreach ($domain in $generalHosts) {
    Test-DNS -TargetHost $domain
    Test-ICMP -TargetHost $domain
    Test-HTTP -TargetHost $domain
    Test-SSL -TargetHost $domain
}
Test-TCPPort -TargetHost "portal.domotz.com" -Port 443

# === API Connectivity ===
Test-TCPPort -TargetHost "api-us-east-1-cell-1.domotz.com" -Port 443
Test-TCPPort -TargetHost "api-eu-west-1-cell-1.domotz.com" -Port 443

# === Messaging ===
Test-TCPPort -TargetHost "messaging-us-east-1-cell-1.domotz.com" -Port 5671
Test-TCPPort -TargetHost "messaging-eu-west-1-cell-1.domotz.com" -Port 5671

# === Remote Connections ===
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

# === Provisioning Channel ===
Test-TCPPort -TargetHost "provisioning.domotz.com" -Port 4505
Test-TCPPort -TargetHost "provisioning.domotz.com" -Port 4506
Test-TCPPort -TargetHost "login.ubuntu.com" -Port 443
Test-TCPPort -TargetHost "pool.sks-keyservers.net" -Port 11371
Test-TCPPort -TargetHost "messaging.orchestration.domotz.com" -Port 5671
Test-TCPPort -TargetHost "api.orchestration.wl-pro.com" -Port 443
Test-TCPPort -TargetHost "tunny.domotz.org" -Port 55022

# === Updates from Canonical ===
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

# === HTTPS Servers ===
$httpsHosts = @(
    "www.google.com",
    "www.fast.com",
    "www.canonical.com",
    "www.redhat.com"
)
foreach ($TargetHost in $httpsHosts) {
    Test-TCPPort -TargetHost $TargetHost -Port 443
}

# === NTP Servers (UDP) ===
function Test-UDPPort {
    param (
        [string]$TargetHost,
        [int]$Port
    )
    try {
        $udpClient = New-Object System.Net.Sockets.UdpClient
        $udpClient.Connect($TargetHost, $Port)
        $udpClient.Close()
        Write-Host "${TargetHost}:${Port} - UDP SENT (no response expected)"
    } catch {
        Write-Host "${TargetHost}:${Port} - UDP FAILED"
    }
}

$ntpHosts = @(
    "ntp.ubuntu.com",
    "0.pool.ntp.org",
    "1.pool.ntp.org"
)
foreach ($TargetHost in $ntpHosts) {
    Test-UDPPort -TargetHost $TargetHost -Port 123
}

# === Speedtest Services ===
Test-TCPPort -TargetHost "api.fast.com" -Port 443
Test-TCPPort -TargetHost "ichnaea-web.netflix.com" -Port 443

# === Final Message ===
Write-Host "`nThank you for your patience."
Write-Host "Solutionz INC RMM has completed the connectivity check."
Write-Host "Please copy the text output above and send it to the Solutionz INC RMM team via email: rmmadmins@solutionzinc.com"
Write-Host "Thank you!"
