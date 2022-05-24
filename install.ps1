function get_cpu {
    $cpu=(gwmi win32_operatingsystem | select osarchitecture).osarchitecture
    Write-Host "$cpu CPU detected." -ForegroundColor Green
}

function install_chrome_driver {
    if ("$cpu" -like "64-bit") {
	$chrome_path="C:\Program Files\Google\Chrome\Application"
    } else {
	$chrome_path="C:\Program Files (x86)\Google\Chrome\Application"
    }

    if (Test-Path -Path $chrome_path) {
	$chrome_local_version=((Get-ChildItem -Path "$chrome_path" -Name)[0]).split(".")[0]
    } else {
	Write-Host "You don't have Firefox broswer, so the script won't download the driver for you." -ForegroundColor Yellow
    }

    $ProgressPreference = 'SilentlyContinue'
    $latest_chrome_version=Invoke-RestMethod "https://chromedriver.storage.googleapis.com/LATEST_RELEASE_$chrome_local_version"

    Try {
	    Invoke-WebRequest -URI "https://chromedriver.storage.googleapis.com/$latest_chrome_version/chromedriver_win32.zip" -OutFile "chromedriver.zip"
    } Catch {
	    Write-Host "Your Chrome version don't have a windows driver" -ForegroundColor Red
	    return
    }

    Expand-Archive -Path "chromedriver.zip" -DestinationPath (Get-Location).Path
    Remove-Item -Path "chromedriver.zip" -force
    Write-Host "Chrome driver installed successfully." -ForegroundColor Green
}

# function install_firefox_driver {
# }

function main {
    get_cpu
    install_chrome_driver
    # install_firefox_driver
}

main