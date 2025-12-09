# PowerShell_Install_SCRIPT.ps1
# PowerShell script to configure network FIRST, download & install the latest Chrome, import bookmarks, install TrinityG, and import certificates
# You can change out the programs and add whatever programs you wish
# Good for Baselining multiple PC/Laptops

# Ensure the script runs as an administrator
function Ensure-Admin {
    $currentUser = [Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
    if (-not $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "This script must be run as an Administrator. Restarting with elevated privileges..."
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
        exit
    }
}
Ensure-Admin

# Function for guided network configuration (Tests for connectivity. If you have a connection, it skips asking for SSID/Password or Static IP settings.
function Configure-Network {
    while ($true) {
        $choice = Read-Host "Choose Network Configuration: (1) DHCP (2) Static"
        if ($choice -eq "1") {
            if (Test-Connection -ComputerName 8.8.8.8 -Count 2 -Quiet) {
                Write-Host "DHCP is already providing connectivity. Skipping configuration."
                break
            } else {
                $SSID = Read-Host "Enter WiFi SSID"
                $Password = Read-Host "Enter WiFi Password"
                netsh wlan add profile name="$SSID" keyMaterial=$Password
                netsh wlan connect name="$SSID"
                Write-Host "Connected to WiFi $SSID using DHCP."
                break
            }
        } elseif ($choice -eq "2") {
            $IP = Read-Host "Enter Static IP Address"
            $Subnet = Read-Host "Enter Subnet Mask"
            $Gateway = Read-Host "Enter Gateway"
            netsh interface ip set address name="Ethernet" static $IP $Subnet $Gateway
            netsh interface ip set dns name="Ethernet" static 8.8.8.8
            Write-Host "Static IP configuration set: IP=$IP, Subnet=$Subnet, Gateway=$Gateway, DNS=8.8.8.8"
            break
        } else {
            Write-Host "Invalid choice. Please try again."
        }
    }
}

# Run network configuration FIRST
Configure-Network

# Function to Download and install latest full version of Chrome (No Updater)
function Install-Chrome {
    $chromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
    $DownloadURL = "https://dl.google.com/tag/s/appguid%3D%7B8A69D345-D564-463C-AFF1-A69D9E530F96%7D%26iid%3D%7B623D4731-D7BD-F54B-0B2E-EB32ABDB865B%7D%26lang%3Den%26browser%3D4%26usagestats%3D0%26appname%3DGoogle%2520Chrome%26needsadmin%3Dtrue%26brand%3DGCEB/dl/chrome/install/googlechromestandaloneenterprise64.msi"
    $InstallerPath = "$env:TEMP\chrome_installer.msi"

    if (Test-Path $chromePath) {
        Write-Host "Google Chrome is already installed. Skipping installation."
        return
    }

    Write-Host "Downloading the Chrome Standalone Installer (No Updater)..."
    Invoke-WebRequest -Uri $DownloadURL -OutFile $InstallerPath

    if (!(Test-Path $InstallerPath)) {
        Write-Host "Chrome installer failed to download. Exiting script."
        exit
    }

    Write-Host "Installing Google Chrome. Please wait..."
    
    # Install using MSI without updater
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i $InstallerPath /qn /norestart" -Wait

    Start-Sleep -Seconds 10
    if (Test-Path $chromePath) {
        Write-Host "Chrome installation completed successfully. You can update manually later."
    } else {
        Write-Host "Chrome installation failed. Exiting script."
        exit
    }
}


# Install Chrome
Install-Chrome

# Function to import bookmarks into Chrome
function Import-Bookmarks {
    $BookmarksFile = "C:\[PATH]\[filename].html" #Enter your 'PATH' and 'filename' (no brackets)
    $ChromeBookmarksDir = "$env:USERPROFILE\Documents"

    if (Test-Path $BookmarksFile) {
        Write-Host "Copying bookmarks file to $ChromeBookmarksDir..."
        Copy-Item -Path $BookmarksFile -Destination "$ChromeBookmarksDir\[filename].html" -Force #Enter your 'filename' (no brackets)
        Write-Host "Bookmarks file copied successfully."

        Write-Host "Opening Chrome's bookmark import page. Please manually select '[filename].html' from Documents." #Enter your 'filename' (no brackets)
        Start-Process "chrome.exe" -ArgumentList "chrome://settings/importData"

    } else {
        Write-Host "Bookmarks file '[filename].html' not found at D:\NGC2." #Enter your 'filename' (no brackets)
        exit
    }
}

# Import bookmarks
Import-Bookmarks

# Function to install software
function Install-[PROGRAM_NAME] { #Enter program name (no brackets)
    param ([string]$[PROGRAM_NAME]Path) #Enter program name (no brackets)
    $attempts = 0
    while ($attempts -lt 3) {
        if (Test-Path $[PROGRAM_NAME]Path) { #Enter program name (no brackets)
            Write-Host "Installing [PROGRAM_NAME]. Please wait..." #Enter program name (no brackets)
            Start-Process -FilePath $[PROGRAM_NAME]Path -ArgumentList "/silent" -Wait #Enter program name (no brackets)
            Start-Sleep -Seconds 10
            Write-Host "[PROGRAM_NAME] installation completed." #Enter program name (no brackets)
            return
        } else {
            Write-Host "[PROGRAM_NAME] setup not found." #Enter program name (no brackets)
            $[PROGRAM_NAME]Path = Read-Host "Enter the correct path for setup file" #Enter program name (no brackets)
            $attempts++
        }
    }
    Write-Host "Failed to install [PROGRAM_NAME] after 3 attempts. Exiting."
    exit
}

# Install exe file
Install-[PROGRAM_NAME] "C:\[PATH]\[PROGRAM_NAME].exe" 

# Import Trusted Root Certificate (CER)
function Import-CERCertificate {
    param ([string]$CertPath)

    if (Test-Path $CertPath) {
        Write-Host "Importing $CertPath into Trusted Root Store..."
        certutil -addstore -f "ROOT" $CertPath
        Write-Host "Certificate imported successfully."
    } else {
        Write-Host "Certificate not found: $CertPath"
        exit
    }
}

# Import .cer into the Trusted Root Store
Import-CERCertificate "C:\[PATH]\[CERTIFICATE].cer" 

Write-Host "Setup complete. Restart Chrome to apply changes."

