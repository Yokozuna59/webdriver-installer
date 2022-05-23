#!/bin/bash

set -u

function abort() {
    echo -e "\x1B[31m✗ $@\x1B[0m" >&2
    exit 1
}

function bad() {
    echo -e "\x1B[31m✗ $@\x1B[0m" >&2
}

function good() {
    echo -e "\x1B[32m✓ $@\x1B[0m" >&2
}

if [ -z "${BASH_VERSION}" ]; then
    abort "Bash is required to interpret this script."
fi

# check what OS is running
function get_os {
    case "$OSTYPE" in
        *"linux"*)
            case "$(uname -a)" in
                *"microsoft"*)
                    readonly os="windows"
                    ;;
                *)
                    readonly os="linux"
                    ;;
            esac
            ;;
        *"darwin"*)
            readonly os="mac"
            ;;
        *"msys"* | *"win32"*)
            readonly os="windows"
            ;;
        *)
            abort "Your operating system isn't supported by this script."
            ;;
    esac
    good "$os operating system detected."
}

# check what CPU is running
function get_cpu {
    case $(uname -a) in
        *"x86_64"* | *"amd64"*)
            readonly cpu="64-bit"
            ;;
        *"x32"* | *"x86_32" | *"i386"* | *"i686"*)
            readonly cpu="32-bit"
            ;;
        *"arm64"* | *"aarch64"*)
            readonly cpu="M1"
            ;;
        *)
            abort "Your CPU isn't supported by this script."
            exit 1
            ;;
    esac
    good "$cpu CPU detected."
}

# check what package manager is running
function get_package_manager {
    if [[ "$os" == "linux" ]] || [[ "$os" == "windows" ]]; then
        declare -Ag osInfo;
        osInfo[/etc/alpine-release]=apk
        osInfo[/etc/debian_version]=apt-get
        osInfo[/etc/redhat-release]=yum
        osInfo[/etc/gentoo-release]=emerge
        osInfo[/etc/arch-release]=pacman
        osInfo[/etc/SuSE-release]=zypper
        osInfo[/etc/zypp]=zypper
        for f in ${!osInfo[@]}; do
            if [[ -f $f ]] || [[ -d $f ]];then
                readonly package_manager="${osInfo[$f]}"
                break
            fi
        done
        if [[ "$package_manager" == "" ]]; then
            abort "Your package manager isn't supported by this script."
        fi
    elif [[ "$os" == "mac" ]]; then
        if brew --version > /dev/null 2>&1; then
            readonly package_manager="brew"
        elif ports --version > /dev/null 2>&1; then
            readonly package_manager="port"
        fi
    fi
    good "$package_manager package manager detected detected"
}

function ask_user {
    trap "abort Operation aborted." SIGINT
    while true; do
        echo -e "- Press \x1B[1m${1}\x1B[0m to install \x1B[1m$2\x1B[0m"
        echo -e "- Press \x1B[1m${3}\x1B[0m to install \x1B[1m$4\x1B[0m"
        echo -e "- Press \x1B[1mControl-C\x1B[0m to cancel installation"
        echo -n "[${1}/${3}] "
        read -rsn1 answer
        if [[ "${answer,,}" == "${1,,}" ]]; then
            echo -e "\x1B[1mInstalling $2\x1B[0m"
            readonly utility="${2,,}"
            break
        elif [[ "${answer,,}" == "${3,,}" ]]; then
            echo -e "\x1B[1mInstalling $4\x1B[0m"
            readonly utility="${4,,}"
            break
        else
            bad "Unknown option, try again"
        fi
    done
}

function donwload_requiments {
    if curl --version > /dev/null 2>&1; then
        readonly utility="curl"
    elif wget --version > /dev/null 2>&1; then
        readonly utility="wget"
    else
        bad "No curl or wget found..."
        ask_user "C" "cURL" "W" "Wget"

        if [[ "$package_manager" == "apk" ]]; then
            sudo apk update
            sudo apk upgrade
            sudo apk add --no-cache "$utility"
        elif [[ "$package_manager" == "apt-get" ]]; then
            sudo apt-get update
            sudo apt-get upgrade
            sudo apt-get install "$utility"
        elif [[ "$package_manager" == "yum" ]]; then
            sudo yum check-update
            sudo yum update
            sudo yum install "$utility"
        elif [[ "$package_manager" == "emerge" ]]; then
            sudo emaint sync -a
            sudo emerge "$utility"
        elif [[ "$package_manager" == "pacman" ]]; then
            sudo pacman -Syu
            sudo pacman -S "$utility"
        elif [[ "$package_manager" == "zypper" ]]; then
            sudo zypper refresh
            sudo zypper update
            sudo zypper install "$utility"
        elif [[ "$package_manager" == "brew" ]]; then
            brew update
            brew upgrade
            brew install "$utility"
        elif [[ "$package_manager" == "port" ]]; then
            sudo port selfupdate
            sudo port upgrade outdated
            sudo port install "$utility"
        else
            echo -e "You need to install \x1B[1mHomebrew\x1B[0m or \x1B[1mPorts\x1B[0m to continue"
            ask_user "B" "Brew" "P" "Port"

            if [[ "$package_manager" == "brew" ]]; then
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                donwload_requiments
            elif [[ "$package_manager" == "port" ]]; then
                echo "Installing MacPorts currently not supported"
                exit 1
                # mac_version=`sw_vers -productVersion`
                # if [[ "$mac_version" -ge "10.10" ]]; then
                #     if ! xcode-select -p > /dev/null 2>&1; then
                #         echo -e "\x1B[31mNo Xcode found...\x1B[0m"
                #         echo -e "You need to install \x1B[1mXcode\x1B[0m to continue..."
                #         echo "Do you want to install Xcode? [Y/n] "
                #         trap "cntl_c" SIGINT
                #         function cntl_c {
                #             echo -e "\x1b[2mCancelled by user\x1B[0m"
                #             exit 1
                #         }
                #         while true; do
                #             echo -e "- Press \x1B[1mY\x1B[0m to install \x1B[1mXcode\x1B[0m"
                #             echo -e "- Press \x1B[1mN\x1B[0m to cancel installatin"
                #             echo -e "- Press \x1B[1mControl-C\x1B[0m to cancel installation"
                #             echo -n "[Y/n] "
                #             read -rsn1 answer
                #             if [[ "${answer,,}" == "y" ]]; then
                #                 echo -e "\x1B[1mInstalling Xcode\x1B[0m"
                #                 xcode-select --install
                #                 sudo xcodebuild -license
                #                 break
                #             elif [[ "${answer,,}" == "n" ]]; then
                #                 cntl_c
                #             else
                #                 echo -e "\x1B[31mUnknown option, try again\x1B[0m"
                #             fi
                #         done
                #     fi
                # else
                #     echo -e "\x1B[31mUnsupported Mac OS version...\x1B[0m"
                #     exit 1
                # fi
                # donwload_requiments
            fi
        fi
    fi
}

function chrome_driver_install {
    LEAST_CHROME_VERSION=`curl -fsSL https://chromedriver.storage.googleapis.com/LATEST_RELEASE`
    if [[ $os == "linux" ]]; then
        if [[ $cpu == "64-bit" ]]; then
            chrome_url="https://chromedriver.storage.googleapis.com/$LEAST_CHROME_VERSION/chromedriver_linux64.zip"
        elif [[ $cpu == "32-bit" ]]; then
            chrome_url="https://chromedriver.storage.googleapis.com/$LEAST_CHROME_VERSION/chromedriver_linux32.zip"
        fi
    elif [[ $os == "macOS" ]]; then
        if [[ $cpu == "64-bit" ]]; then
            chrome_url="https://chromedriver.storage.googleapis.com/$LEAST_CHROME_VERSION/chromedriver_mac64.zip"
        elif [[ $cpu == "32-bit" ]]; then
            chrome_url="https://chromedriver.storage.googleapis.com/$LEAST_CHROME_VERSION/chromedriver_mac32.zip"
        elif [[ $cpu == "M1" ]]; then
            chrome_url="https://chromedriver.storage.googleapis.com/$LEAST_CHROME_VERSION/chromedriver_mac64_m1.zip"
        fi
    elif [[ $os == "windows" ]]; then
        chrome_url="https://chromedriver.storage.googleapis.com/$LEAST_CHROME_VERSION/chromedriver_win32.zip"
    fi

    if curl -fsSL -o chromedriver.zip "$chrome_url" > /dev/null 2>&1; then
        unzip -qq chromedriver.zip
        rm chromedriver.zip
        good "Chrome driver installed successfully."
    else
        bad "Your device architecture does not support chrome driver version $LEAST_CHROME_VERSION"
    fi
}

function firefox_driver_install {
    if [[ "$os" == "linux" ]]; then
        firefox_local_version=$(firefox --version | cut -d " " -f 3 | cut -d "." -f 1,2)
    elif [[ "$os" == "mac" ]]; then
        firefox_local_version=$(/Applications/Firefox.app/Contents/MacOS/firefox -v | cut -d " " -f 3 | cut -d "." -f 1,2)
    elif [[ "$os" == "windows" ]]; then
        readonly current_path=`pwd`
        if [[ "$cpu" == "64-bit" ]]; then
            `cd /mnt/c/Program\ Files/Mozilla\ Firefox`
        elif [[ "$cpu" == "32-bit" ]]; then
            `cd /mnt/c/Program\ Files\ \(x86\)/Mozilla\ Firefox`
        fi
        firefox_local_version=$(cmd.exe /c "firefox -v | more" | cut -d " " -f 3 | cut -d "." -f 1,2)
        cd current_path
    fi
    geckodriver_versions=$(curl -fsSL https://github.com/mozilla/geckodriver/tags | grep '<a href="/mozilla/geckodriver/releases/tag/' | sed 's/.*href="\/\(.*\)">.*/\1/')

    if [ $(bc <<< "$firefox_local_version > 90.0") -eq 1 ]; then
        firefox_url="https://github.com/$(echo $geckodriver_versions | cut -d " " -f 1)"
    elif [ $(bc <<< "$firefox_local_version > 79.0") -eq 1 ]; then
        firefox_url="https://github.com/$(echo $geckodriver_versions | cut -d " " -f 2)"
    elif [ $(bc <<< "$firefox_local_version >= 62.0") -eq 1 ]; then
        firefox_url="https://github.com/$(echo $geckodriver_versions | cut -d " " -f 9)"
    else
        bad "Your Firefox version is not supported"
        return 1
    fi
    firefox_drivers=`curl -fsSL $firefox_url | grep 'data-skip-pjax' | sed 's/^.*href="\/\(.*\)".*$/\1/' | sed 's/" rel="nofollow//'`

    for i in $firefox_drivers; do
        if [[ "$i" == *"linux"* ]] && [[ "$os" == "linux" ]]; then
            if [[ "$i" == *"64"* ]] && [[ "$cpu" == "64-bit" ]]; then
                firefox_url="https://github.com/$i"
                break
            elif [[ "$i" == *"32"* ]] && [[ "$cpu" == "32-bit" ]]; then
                firefox_url="https://github.com/$i"
                break
            fi
        elif [[ "$i" == *"macos"* ]] && [[ "$os" == "mac" ]]; then
            if [[ "$i" == *"aarch64"* ]] && [[ "$cpu" == "M1" ]]; then
                firefox_url="https://github.com/$i"
                break
            elif [[ $cpu == "64-bit" ]]; then
                firefox_url="https://github.com/$i"
                break
            fi
        elif [[ "$i" == *"win"* ]] && [[ "$os" == "windows" ]]; then
            if [[ "$i" == *"64"* ]] && [[ "$cpu" == "64-bit" ]]; then
                firefox_url="https://github.com/$i"
                break
            elif [[ "$i" == *"32"* ]] && [[ "$cpu" == "32-bit" ]]; then
                firefox_url="https://github.com/$i"
                break
            fi
        fi
    done
    if [[ "$firefox_url" == "" ]]; then
        bad "Your device architecture does not support firefox driver"
    fi
    if [[ "$os" == "linux" ]] || [[ $os == "macOS" ]]; then
        curl -fsSL -o geckodriver.tar.gz "$firefox_url"
        tar -xzf geckodriver.tar.gz
        rm geckodriver.tar.gz
    elif [[ "$os" == "windows" ]]; then
        curl -fsSL -o geckodriver.zip "$firefox_url"
        unzip -qq drivers/geckodriver.zip
        rm drivers/geckodriver.zip
    fi
    good "Firefox driver installed successfully."
}

function main {
    get_os
    get_cpu
    get_package_manager
    donwload_requiments
    chrome_driver_install
    firefox_driver_install
    # internet_explorer_driver_install https://www.selenium.dev/downloads/
    # opera_driver_install https://github.com/operasoftware/operachromiumdriver/releases
    # edge_driver_install https://developer.microsoft.com/en-us/microsoft-edge/tools/webdriver/
}

main