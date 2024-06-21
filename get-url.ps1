<#
  Sometimes, this script does not work due to third-party game modifications.
  If you need help, join our Discord: https://discord.gg/mADnEXwZGT
#>
Add-Type -AssemblyName System.Web

$64 = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
$32 = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
Write-Output "Attempting to find URL automatically..."

# Native
try {
    $gamePath = (Get-ItemProperty -Path $32, $64 | Where-Object { $_.DisplayName -like "*wuthering*" } | Select-Object InstallPath).PSObject.Properties.Value
    if ((Test-Path ($gamePath + '\Client\Saved\Logs\Client.log') -or Test-Path($gamePath + '\Client\Binaries\Win64\ThirdParty\KrPcSdk_Global\KRSDKRes\KRSDKWebView\debug.log'))) {
        $gachaLogPathExists = $true
    }
}
catch {
    $gamePath = $null
    $gachaLogPathExists = $false
}

# MUI Cache
if (!$gachaLogPathExists) {
    $muiCachePath = "Registry::HKEY_CURRENT_USER\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\MuiCache"
    $filteredEntries = (Get-ItemProperty -Path $muiCachePath).PSObject.Properties | Where-Object { $_.Value -like "*wuthering*" } | Where-Object { $_.Name -like "*client-win64-shipping.exe*" }
    if ($filteredEntries.Count -ne 0) {
        $gamePath = ($filteredEntries[0].Name -split '\\client\\')[0]
        if ((Test-Path ($gamePath + '\Client\Saved\Logs\Client.log')) -or (Test-Path ($gamePath + '\Client\Binaries\Win64\ThirdParty\KrPcSdk_Global\KRSDKRes\KRSDKWebView\debug.log'))) {
            $gachaLogPathExists = $true
        }
    }
}

# Firewall 
if (!$gachaLogPathExists) {
    $firewallPath = "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules"
    $filteredEntries = (Get-ItemProperty -Path $firewallPath).PSObject.Properties | Where-Object { $_.Value -like "*wuthering*" } | Where-Object { $_.Name -like "*client-win64-shipping*" }
    if ($filteredEntries.Count -ne 0) {
        $gamePath = (($filteredEntries[0].Value -split 'App=')[1] -split '\\client\\')[0]
        if ((Test-Path ($gamePath + '\Client\Saved\Logs\Client.log')) -or (Test-Path ($gamePath + '\Client\Binaries\Win64\ThirdParty\KrPcSdk_Global\KRSDKRes\KRSDKWebView\debug.log'))) {
            $gachaLogPathExists = $true
        }
    }
}

# Common Installation Paths
if (!$gachaLogPathExists) {
    $diskLetters = (Get-PSDrive).Name -match '^[a-z]$'
    foreach ($diskLetter in $diskLetters) {
        $gamePaths = @(
            "$diskLetter`:\Wuthering Waves Game",
            "$diskLetter`:\Wuthering Waves\Wuthering Waves Game",
            "$diskLetter`:\Epic Games\WutheringWavesj3oFh\Wuthering Waves Game"
        )
    
        foreach ($gamePath in $gamePaths) {
            if ((Test-Path ($gamePath + '\Client\Saved\Logs\Client.log')) -or (Test-Path ($gamePath + '\Client\Binaries\Win64\ThirdParty\KrPcSdk_Global\KRSDKRes\KRSDKWebView\debug.log')) ) {
                $gamePath = $gamePath
                $gachaLogPathExists = $true
                break
            }
        }
    
        if ($gachaLogPathExists -or $gamePath) {
            break
        }
    }
}

# Manual
while (!$gachaLogPathExists) {
    Write-Host "Game install location not found or log files missing. If you think that your installation directory is correct and it's still not working, please join our Discord server for help: https://discord.gg/mADnEXwZGT. Otherwise, please enter the game install location path."
    Write-Host 'Common install locations:'
    Write-Host '  G:\Wuthering Waves' -ForegroundColor Yellow
    Write-Host '  G:\Wuthering Waves\Wuthering Waves Game' -ForegroundColor Yellow
    Write-Host '  G:\Epic Games\WutheringWavesj3oFh' -ForegroundColor Yellow
    $path = Read-Host "Path"
    if ($path) {
        $gamePath = $path
        if ((Test-Path ($gamePath + '\Client\Saved\Logs\Client.log')) -or (Test-Path ($gamePath + '\Client\Binaries\Win64\ThirdParty\KrPcSdk_Global\KRSDKRes\KRSDKWebView\debug.log'))) {
            $gachaLogPathExists = $true
        }
        else {
            Write-Host "Could not find log files. Did you set your game location properly or open your Convene History first?" -ForegroundColor Red
        }
    }
    else {
        Write-Host "Invalid game location. Did you set your game location properly?" -ForegroundColor Red
    }
}

$gachaLogPath = $gamePath + '\Client\Saved\Logs\Client.log'
$debugLogPath = $gamePath + '\Client\Binaries\Win64\ThirdParty\KrPcSdk_Global\KRSDKRes\KRSDKWebView\debug.log'

if (Test-Path $gachaLogPath) {
    $gachaUrlEntry = Get-Content $gachaLogPath | Select-String -Pattern "https://aki-gm-resources-oversea\.aki-game\.(net|com)" | Select-Object -Last 1
}
else {
    $gachaUrlEntry = $null
}

if (Test-Path $debugLogPath) {
    $debugUrlEntry = Get-Content $debugLogPath | Select-String -Pattern '"#url": "(https://aki-gm-resources-oversea\.aki-game\.(net|com)[^"]*)"' | Select-Object -Last 1
    $debugUrl = $debugUrlEntry.Matches.Groups[1].Value
}
else {
    $debugUrl = $null
}

if ($gachaUrlEntry -or $debugUrl) {
    if ($gachaUrlEntry) {
        $urlToCopy = $gachaUrlEntry -replace '.*?(https://aki-gm-resources-oversea\.aki-game\.(net|com)[^"]*).*', '$1'
    }
    if ([string]::IsNullOrWhiteSpace($urlToCopy)) {
        $urlToCopy = $debugUrl
    }

    if ([string]::IsNullOrWhiteSpace($urlToCopy)) {
        Write-Host "Cannot find the convene history URL in both Client.log and debug.log! Please open your Convene History first!" -ForegroundColor Red
    }
    else {
        Write-Host "`nConvene Record URL: $urlToCopy"
        Set-Clipboard $urlToCopy
        Write-Host "`nLink copied to clipboard, paste it in wuwatracker.com and click the Import History button." -ForegroundColor Green
    }
}
else {
    Write-Host "Cannot find the convene history URL in both Client.log and debug.log! Please open your Convene History first!" -ForegroundColor Red
}
