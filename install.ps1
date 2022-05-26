function get_processor {
    $global:processor=(Get-WmiObject win32_operatingsystem | Select-Object osarchitecture).osarchitecture
    Write-Host "$processor processor detected." -ForegroundColor Green
}

function install_chrome_driver {
    if ("$processor" -like "64-bit") {
	    $chrome_path="C:\Program Files\Google\Chrome\Application"
    } else {
	    $chrome_path="C:\Program Files (x86)\Google\Chrome\Application"
    }
    if (Test-Path -Path $chrome_path) {
	    $chrome_local_version=((((Get-Item (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe').'(Default)').VersionInfo).ProductVersion).split("."))[0]
    } else {
	    Write-Host "You don't have Chrome broswer, so the script won't download the driver for you." -ForegroundColor Yellow
	    return
    }
    $ProgressPreference = 'SilentlyContinue'
    $latest_chrome_version=Invoke-RestMethod "https://chromedriver.storage.googleapis.com/LATEST_RELEASE_$chrome_local_version"
    Try {
	    Invoke-WebRequest -URI "https://chromedriver.storage.googleapis.com/$latest_chrome_version/chromedriver_win32.zip" -OutFile "chromedriver.zip"
    } Catch {
	    Write-Host "Your Chrome version don't have a windows driver" -ForegroundColor Red
	    return
    }
    Expand-Archive -Path "chromedriver.zip" -DestinationPath (Get-Location).Path -Force
    Remove-Item -Path "chromedriver.zip" -Force
    Write-Host "Chrome driver installed successfully." -ForegroundColor Green
}

function install_firefox_driver {
    if ("$processor" -like "64-bit") {
        $firefox_path="C:\Program Files/Mozilla Firefox"
    } else {
        $firefox_path="C:\Program Files (x86)/Mozilla Firefox"
    }

    if (Test-Path -Path $firefox_path) {
        $firefox_local_version=[int]((((Get-Item (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\firefox.exe').'(Default)').VersionInfo).ProductVersion).split("."))[0]
    } else {
        Write-Host "You don't have Firefox broswer, so the script won't download the driver for you." -ForegroundColor Yellow
        return
    }
    $ProgressPreference = 'SilentlyContinue'
    $geckodriver_versions=((Invoke-RestMethod "https://api.github.com/repos/mozilla/geckodriver/releases").assets).browser_download_url | Select-String "win" | Select-String ($processor).replace("-bit", "")
    if ( $geckodriver_versions -like "" ) {
        red "Your device architecture does not support firefox driver"
    }
    if ($firefox_local_version -gt 90) {
        $firefox_url=$geckodriver_versions[0]
    } elseif ($firefox_local_version -gt 79) {
        $firefox_url=$geckodriver_version[1]
    } elseif ($firefox_local_version -ge 62) {
        $firefox_url=$geckodriver_versions[8]
    } else {
        Write-Host "Your Firefox version in not supported, so the script won't download the driver for you." -ForegroundColor Red
        return 0
    }
    Invoke-WebRequest -URI "$firefox_url" -OutFile "geckodriver.zip"
    Expand-Archive -Path "geckodriver.zip" -DestinationPath (Get-Location).Path -Force
    Remove-Item -Path "geckodriver.zip" -Force
    Write-Host "Firefox driver installed successfully." -ForegroundColor Green
}

function main {
    get_processor
    install_chrome_driver
    install_firefox_driver
}

main