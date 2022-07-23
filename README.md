# WebDrivers Installer

> A script installs the right drivers for your browsers, Chrome/Chromium and Firefox, works on Windows, Linux and Mac.

## Supported Platforms

| OS | Supported | Tested |
|:--:|:---------:|:------:|
| macOS Intel | ✅ | ✅ |
| macOS Apple Silicon | ✅ | N/A |
| Linux x86_64 | ✅ | ✅ |
| Linux i686 | ✅ | N/A |
| Linux aarch64 | N/A | N/A |
| Windows 64bit | ✅ | ✅ |
| Windows 32bit | ✅ | N/A |
| Windows Arm64 | N/A | N/A |

## Requirements

1. [cURL](https://curl.se/docs/install.html) or [Wget](http://mirrors.kernel.org/gnu/wget/) for Windows (WSL), Linux or Mac.

## Run Remotely

### Linux & Mac & Windows (WSL)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Yokozuna59/\
webdriver-installer/master/install.sh)"
# or /bin/bash -c "$(wget -qO- https://raw.githubusercontent.com/Yokozuna59/\
# webdriver-installer/master/install.sh)"
```

### Windows (PowerShell)

```PowerShell
$request = Invoke-RestMethod -URI 'https://raw.githubusercontent.com/\
Yokozuna59/webdriver-installer/master/install.ps1'
Invoke-Expression -Command "$request"
```

## Run Locally

### Linux & Mac

```bash
chmod +x install.sh
./install.sh
```

### Windows (WSL)

```bash
chmod +x install.sh
sed -i 's/\r$//' install.sh
./install.sh
```

### Windows (PowerShell)

```PowerShell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser
.\install.ps1
```
