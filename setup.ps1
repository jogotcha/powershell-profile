# Ensure the script can run with elevated privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Please run this script as an Administrator!"
    break
}

# Function to test internet connectivity
function Test-InternetConnection {
    try {
        Test-Connection -ComputerName www.google.com -Count 1 -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        Write-Warning "Internet connection is required but not available. Please check your connection."
        return $false
    }
}

# Helper function for cross-edition compatibility
function Get-ProfileDir {
    if ($PSVersionTable.PSEdition -eq "Core") {
        return "$env:userprofile\Documents\PowerShell"
    } elseif ($PSVersionTable.PSEdition -eq "Desktop") {
        return "$env:userprofile\Documents\WindowsPowerShell"
    } else {
        Write-Error "Unsupported PowerShell edition: $($PSVersionTable.PSEdition)"
        break
    }
}

# Check for internet connectivity before proceeding
if (-not (Test-InternetConnection)) {
    break
}

# Profile creation or update
if (!(Test-Path -Path $PROFILE -PathType Leaf)) {
    try {
        $profilePath = Get-ProfileDir
        if (!(Test-Path -Path $profilePath)) {
            New-Item -Path $profilePath -ItemType "directory" -Force
        }
        Invoke-RestMethod https://github.com/jogotcha/powershell-profile/raw/main/Microsoft.PowerShell_profile.ps1 -OutFile $PROFILE
        Write-Host "The profile @ [$PROFILE] has been created."
        Write-Host "If you want to make any personal changes or customizations, please do so at [$profilePath\Profile.ps1] as there is an updater in the installed profile which uses the hash to update the profile and will lead to loss of changes"
    }
    catch {
        Write-Error "Failed to create or update the profile. Error: $_"
    }
}
else {
    try {   
        $backupPath = Join-Path (Split-Path $PROFILE) "oldprofile.ps1"
        Move-Item -Path $PROFILE -Destination $backupPath -Force
        Invoke-RestMethod https://github.com/jogotcha/powershell-profile/raw/main/Microsoft.PowerShell_profile.ps1 -OutFile $PROFILE
        Write-Host "✅ PowerShell profile at [$PROFILE] has been updated."
        Write-Host "📦 Your old profile has been backed up to [$backupPath]"
        Write-Host "⚠️ NOTE: Please back up any persistent components of your old profile to [$HOME\Documents\PowerShell\Profile.ps1] as there is an updater in the installed profile which uses the hash to update the profile and will lead to loss of changes"
    }
    catch {
        Write-Error "❌ Failed to backup and update the profile. Error: $_"
    }
}

# Function to download Oh My Posh theme locally
function Install-OhMyPoshTheme {
    param (
        [string]$ThemeName = "cobalt2",
        [string]$ThemeUrl = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/cobalt2.omp.json"
    )
    $profilePath = Get-ProfileDir
    if (!(Test-Path -Path $profilePath)) {
        New-Item -Path $profilePath -ItemType "directory"
    }
    $themeFilePath = Join-Path $profilePath "$ThemeName.omp.json"
    try {
        Invoke-RestMethod -Uri $ThemeUrl -OutFile $themeFilePath
        Write-Host "Oh My Posh theme '$ThemeName' has been downloaded to [$themeFilePath]"
        return $themeFilePath
    }
    catch {
        Write-Error "Failed to download Oh My Posh theme. Error: $_"
        return $null
    }
}

# OMP Install
try {
    winget install -e --accept-source-agreements --accept-package-agreements JanDeDobbeleer.OhMyPosh
}
catch {
    Write-Error "Failed to install Oh My Posh. Error: $_"
}

# Download Oh My Posh theme locally
#$themeInstalled = Install-OhMyPoshTheme -ThemeName "cobalt2"

# Font Install
oh-my-posh font install CascadiaCode

# Final check and message to the user
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
$fontFamilies = (New-Object System.Drawing.Text.InstalledFontCollection).Families.Name
if ((Test-Path -Path $PROFILE) -and (winget list --name "OhMyPosh" -e) -and ($fontFamilies -contains "CaskaydiaCove NF") -and $themeInstalled) {
    Write-Host "Setup completed successfully. Please restart your PowerShell session to apply changes."
} else {
    Write-Warning "Setup completed with errors. Please check the error messages above."
}

# Choco install
try {
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    $chocoScript = (New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1')
    Invoke-Expression $chocoScript
}
catch {
    Write-Error "Failed to install Chocolatey. Error: $_"
}

# Terminal Icons Install
try {
    Install-Module -Name Terminal-Icons -Repository PSGallery -Force
}
catch {
    Write-Error "Failed to install Terminal Icons module. Error: $_"
}

# PSKubectlCompletion Install
try {
    if (-not (Get-Module -ListAvailable -Name PSKubectlCompletion)) {
        Install-Module -Name PSKubectlCompletion -Repository PSGallery -Scope CurrentUser -Force -AllowClobber -SkipPublisherCheck
    }
}
catch {
    Write-Error "Failed to install PSKubectlCompletion module. Error: $_"
}

# zoxide Install
try {
    winget install -e --id ajeetdsouza.zoxide --accept-source-agreements --accept-package-agreements
    Write-Host "zoxide installed successfully."
    winget install junegunn.fzf --accept-source-agreements --accept-package-agreements
    Write-Host "fzf installed successfully."
}
catch {
    Write-Error "Failed to install zoxide. Error: $_"
}

# mise Install
try {
    winget install jdx.mise --accept-source-agreements --accept-package-agreements
    Write-Host "mise installed successfully."
}
catch {
    Write-Error "Failed to install mise. Error: $_"
}