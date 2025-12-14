#requires -version 5.1
# Process-only policy (no system change)
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

Clear-Host
$Host.UI.RawUI.WindowTitle = "DARKNET // MINING CORE v9.3"
$Host.UI.RawUI.ForegroundColor = "Green"
$Host.UI.RawUI.BackgroundColor = "Black"

# Boot sequence
Write-Host "Initializing mining core..." -ForegroundColor Cyan
Start-Sleep -Milliseconds 800
Write-Host "Loading compute engine..." -ForegroundColor Green
Start-Sleep -Milliseconds 700
Write-Host "Configuring network protocols..." -ForegroundColor Yellow
Start-Sleep -Milliseconds 700
Write-Host "Establishing pool connections..." -ForegroundColor Magenta
Start-Sleep -Milliseconds 600
Write-Host "Calibrating optimizer..." -ForegroundColor Green
Start-Sleep -Milliseconds 900
Write-Host "Wallet subsystem online." -ForegroundColor Cyan
Start-Sleep -Milliseconds 600

# Progress bars
$subsystems = @("Network Sync", "Hash Engine", "Pool", "Wallet", "Cooling")
foreach ($sub in $subsystems) {
    Write-Host "$sub Progress: " -NoNewline -ForegroundColor Cyan
    for ($i = 0; $i -le 100; $i += 5) {
        Write-Host "`r$sub Progress: [" -NoNewline -ForegroundColor Green
        for ($j = 0; $j -lt $i/5; $j++) { Write-Host "=" -NoNewline -ForegroundColor Green }
        for ($j = $i/5; $j -lt 20; $j++) { Write-Host " " -NoNewline }
        Write-Host "] $i%" -NoNewline -ForegroundColor Green
        Start-Sleep -Milliseconds 80
    }
    Write-Host ""
}
Clear-Host

Write-Host "MINING CORE ONLINE" -ForegroundColor Red
Write-Host "Type 'help' for commands or 'exit' to shutdown." -ForegroundColor Yellow
Write-Host "------------------------------------------------" -ForegroundColor Green

# Global state
$global:totalHashes = 0
$global:blocksFound = 0
$global:balance = 0.0
$global:difficulty = 1000000000
$global:hashRate = 1000000
$global:lastBlockTime = Get-Date
$global:walletAddress = $null

# Utils
function New-BTCAddress {
    $chars = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
    $addr = "1"
    for ($i = 0; $i -lt 33; $i++) { $addr += $chars[(Get-Random -Min 0 -Max $chars.Length)] }
    $addr
}

function New-Hash {
    $bytes = New-Object byte[] 32
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $rng.GetBytes($bytes)
    ([BitConverter]::ToString($bytes) -replace '-', '')
}

function Wallet-Search {
    Write-Host "Searching wallet data..." -ForegroundColor Cyan
    Start-Sleep -Milliseconds 500
    Write-Host "Scanning nodes..." -ForegroundColor Yellow
    for ($i=0;$i -lt 15;$i++){ Write-Host "`rScan" -NoNewline; Start-Sleep -Milliseconds 120 }
    Write-Host "`nNodes ready." -ForegroundColor Green
    Write-Host "Decrypting keys..." -ForegroundColor Magenta
    for ($i=0;$i -le 100;$i+=5){ Write-Host "`r[" -NoNewline; for($j=0;$j -lt $i/5;$j++){Write-Host "=" -NoNewline}; Write-Host "] $i%" -NoNewline; Start-Sleep -Milliseconds 100 }
    Write-Host "`nKeys processed." -ForegroundColor Green
    $global:walletAddress = New-BTCAddress
    Write-Host "Wallet ready: $global:walletAddress" -ForegroundColor Yellow
}

function Start-Mining {
    param([int]$Minutes = 60)
    $end = (Get-Date).AddMinutes($Minutes)
    while ((Get-Date) -lt $end) {
        $h = New-Hash
        $global:totalHashes += [int]($global:hashRate/10)
        Write-Host "`rHash: $h | Total: $global:totalHashes | Balance: $global:balance BTC" -NoNewline -ForegroundColor DarkGreen
        Start-Sleep -Milliseconds 200
        if ((Get-Random -Min 1 -Max $global:difficulty) -le 10) {
            $global:blocksFound++
            $reward = [math]::Round(6.25 / (Get-Random -Min 1 -Max 20), 8)
            $global:balance += $reward
            $global:lastBlockTime = Get-Date
            Write-Host "`nBlock accepted. Reward: $reward BTC" -ForegroundColor Yellow
            $global:difficulty += 50000000
        }
    }
    Write-Host "`nSession ended. Blocks: $global:blocksFound" -ForegroundColor Red
}

function Show-Status {
    $uptime = ((Get-Date) - $global:lastBlockTime).ToString("hh\\:mm\\:ss")
    $avg = [math]::Round($global:totalHashes / (((Get-Date)-$global:lastBlockTime).TotalSeconds + 1),2)
    Write-Host "Status:" -ForegroundColor Cyan
    Write-Host " Wallet: $global:walletAddress" -ForegroundColor Yellow
    Write-Host " Total Hashes: $global:totalHashes" -ForegroundColor Green
    Write-Host " Blocks: $global:blocksFound" -ForegroundColor Green
    Write-Host " Balance: $global:balance BTC" -ForegroundColor Green
    Write-Host " Difficulty: $global:difficulty" -ForegroundColor Yellow
    Write-Host " Hashrate: $avg MH/s" -ForegroundColor Green
    Write-Host " Uptime: $uptime" -ForegroundColor Magenta
}

function Wallet-Op {
    param([string]$Op)
    switch ($Op) {
        'check' { Write-Host "Balance: $global:balance BTC" -ForegroundColor Green }
        'transfer' {
            if ($global:balance -le 0) { Write-Host "No funds." -ForegroundColor Red; break }
            $maxSat = [int]($global:balance * 100000000)
            $amtSat = Get-Random -Min 1 -Max $maxSat
            $amt = [math]::Round($amtSat/100000000,8)
            $global:balance -= $amt
            Write-Host "Transferred $amt BTC" -ForegroundColor Green
        }
        default { Write-Host "Unknown wallet command." -ForegroundColor Red }
    }
}

# Start
Wallet-Search
$running = $true
while ($running) {
    Write-Host "CORE> " -NoNewline -ForegroundColor Red
    $cmd = Read-Host
    switch ($cmd.ToLower()) {
        'help' {
            Write-Host "start [min] | status | wallet check | wallet transfer | search wallet | clear | exit" -ForegroundColor Yellow
        }
        { $_ -match '^start\s*(\d*)$' } {
            $m = if ($matches[1]) { [int]$matches[1] } else { 60 }
            if ($global:walletAddress) { Start-Mining -Minutes $m } else { Write-Host "No wallet." -ForegroundColor Red }
        }
        'status' { Show-Status }
        'wallet check' { Wallet-Op 'check' }
        'wallet transfer' { Wallet-Op 'transfer' }
        'search wallet' { Wallet-Search }
        'clear' { Clear-Host }
        'exit' { $running = $false; Write-Host "Shutting down..." -ForegroundColor Red }
        default { Write-Host "Unknown command." -ForegroundColor Red }
    }
}
