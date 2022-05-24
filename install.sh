#!/bin/bash

set -e

# check if bash is exist
if [ -z "${BASH_VERSION}" ]; then
    abort "Bash is required to interpret this script."
fi

# print a red error message
function red {
    echo -e "\x1B[31m✗ $@\x1B[0m" >&2
}

# print a yellow massage
function yellow {
    echo -e "\x1B[33m! $@\x1B[0m" >&2
}

# print a grean message
function green {
    echo -e "\x1B[32m✓ $@\x1B[0m" >&2
}

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
            red "Your operating system isn't supported by this script."
            exit 1
            ;;
    esac
    green "$os operating system detected."
}

# check what CPU is running
function get_cpu {
    case $(uname -a) in
        *"x86_64"* | *"amd64"*)
            readonly cpu="64-bit"
            ;;
        *"x32"* | "x86" | *"i386"* | *"i486"* | *"i586"* | *"i686"*)
            readonly cpu="32-bit"
            ;;
        *"arm64"* | *"aarch64"*)
            readonly cpu="M1"
            ;;
        *)
            red "Your CPU isn't supported by this script."
            exit 1
            ;;
    esac
    green "$cpu CPU detected."
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
            red "Your package manager isn't supported by this script."
            exit 1
        fi
    elif [[ "$os" == "mac" ]]; then
        if brew --version > /dev/null 2>&1; then
            readonly package_manager="brew"
        elif ports --version > /dev/null 2>&1; then
            readonly package_manager="port"
        else
            return 0
        fi
    fi
    green "$package_manager package manager detected detected"
}

# update and upgrade packages
function update_upgrade_packages {
    yellow "You need \`sudo\` access to update packages!"
    if [[ "$package_manager" == "apk" ]]; then
        sudo apk update -q
        sudo apk upgrade -q
    elif [[ "$package_manager" == "apt-get" ]]; then
        sudo apt-get update -qq
        sudo apt-get upgrade -qq
    elif [[ "$package_manager" == "yum" ]]; then
        sudo yum check-update -q
        sudo yum update -q
    elif [[ "$package_manager" == "emerge" ]]; then
        sudo emaint --auto sync --quiet
    elif [[ "$package_manager" == "pacman" ]]; then
        sudo pacman -Syu -q
    elif [[ "$package_manager" == "zypper" ]]; then
        sudo zypper refresh -q
        sudo zypper update -q
    elif [[ "$package_manager" == "brew" ]]; then
        brew update
        brew upgrade
    elif [[ "$package_manager" == "port" ]]; then
        sudo port selfupdate
        sudo port upgrade outdated
    fi
}

# check if br is installed
function check_br {
    if ! bc --version > /dev/null 2>&1; then
        update_upgrade_packages
        updated=true
        yellow "The script needs \`bc\` to be able to continue!"
        if [[ "$package_manager" == "apk" ]]; then
            sudo apk install bc -q
        elif [[ "$package_manager" == "apt-get" ]]; then
            sudo apt-get install bc -qq
        elif [[ "$package_manager" == "yum" ]]; then
            sudo yum install bc -q
        elif [[ "$package_manager" == "emerge" ]]; then
            sudo emerge bc -qq
        elif [[ "$package_manager" == "pacman" ]]; then
            sudo pacman -S bc -q
        elif [[ "$package_manager" == "zypper" ]]; then
            sudo zypper install bc -q
        elif [[ "$package_manager" == "brew" ]]; then
            brew isntall bc
        elif [[ "$package_manager" == "port" ]]; then
            sudo port install bc
        fi
        good "bc installed!"
    fi
}

# check if wget or curl is installed
function check_curl_or_wget {
    if curl --version > /dev/null 2>&1; then
        readonly utility="curl"
    elif wget --version > /dev/null 2>&1; then
        readonly utility="wget"
    else
        if [[ "$updated" != true ]]; then
            update_upgrade_packages
            updated=true
        fi
        yellow "The script needs \`wget\` or \`curl\` to be able to continue!"
        ask_user "C" "cURL" "W" "Wget"

        if [[ "$package_manager" == "apk" ]]; then
            sudo apk add --no-cache "$utility" -q
        elif [[ "$package_manager" == "apt-get" ]]; then
            sudo apt-get install "$utility" -qq
        elif [[ "$package_manager" == "yum" ]]; then
            sudo yum install "$utility" -q
        elif [[ "$package_manager" == "emerge" ]]; then
            sudo emerge "$utility" -q
        elif [[ "$package_manager" == "pacman" ]]; then
            sudo pacman -S "$utility" -q
        elif [[ "$package_manager" == "zypper" ]]; then
            sudo zypper install "$utility" -q
        elif [[ "$package_manager" == "brew" ]]; then
            brew install "$utility"
        elif [[ "$package_manager" == "port" ]]; then
            sudo port install "$utility"
        else
            echo -e "You need to install \x1B[1mHomebrew\x1B[0m or \x1B[1mPorts\x1B[0m to continue"
            ask_user "B" "Brew" "P" "Port"

            if [[ "$package_manager" == "brew" ]]; then
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                brew install "$utility"
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
        good "$utility installed!"
    fi
}

# check if zip installed
function check_zip {
    if ! zip --version > /dev/null 2>&1; then
        if [[ "$updated" != true ]]; then
            update_upgrade_packages
            updated=true
        fi
        yellow "The script needs \`zip\` to be able to continue!"
        if [[ "$package_manager" == "apk" ]]; then
            sudo apk install zip -q
        elif [[ "$package_manager" == "apt-get" ]]; then
            sudo apt-get install zip -qq
        elif [[ "$package_manager" == "yum" ]]; then
            sudo yum install zip -q
        elif [[ "$package_manager" == "emerge" ]]; then
            sudo emerge zip -q
        elif [[ "$package_manager" == "pacman" ]]; then
            sudo pacman -S zip -q
        elif [[ "$package_manager" == "zypper" ]]; then
            sudo zypper install zip -q
        elif [[ "$package_manager" == "brew" ]]; then
            brew isntall zip
        elif [[ "$package_manager" == "port" ]]; then
            sudo port install zip
        fi
    fi
}

# check if zip installed
function check_tar {
    if ! tar --version > /dev/null 2>&1; then
        if [[ "$updated" != true ]]; then
            update_upgrade_packages
            updated=true
        fi
        yellow "The script needs \`zip\` to be able to continue!"
        if [[ "$package_manager" == "apk" ]]; then
            sudo apk install tar -q
        elif [[ "$package_manager" == "apt-get" ]]; then
            sudo apt-get install tar -qq
        elif [[ "$package_manager" == "yum" ]]; then
            sudo yum install tar -q
        elif [[ "$package_manager" == "emerge" ]]; then
            sudo emerge tar -q
        elif [[ "$package_manager" == "pacman" ]]; then
            sudo pacman -S tar -q
        elif [[ "$package_manager" == "zypper" ]]; then
            sudo zypper install tar -q
        elif [[ "$package_manager" == "brew" ]]; then
            brew isntall tar
        elif [[ "$package_manager" == "port" ]]; then
            sudo port install tar
        fi
    fi
}

# ask user to choose between two options
function ask_user {
    trap "red Operation aborted." SIGINT
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
            red "Unknown option, try again"
        fi
    done
}

function chrome_driver_install {
    # if [[ "$os" == "linux" ]]; then
    #     if google-chrome --version > /dev/null 2>&1; then
    #         chrome_local_version=$(google-chrome --version | cut -d " " -f 3)
    #     elif chromium-browser --version > /dev/null 2>&1; then
    #         chrome_local_version=$(chromium-browser --version | cut -d " " -f 2)
    #     fi
    # elif [[ "$os" == "mac" ]]; then
    #     if /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --version > /dev/null 2>&1; then
    #         chrome_local_version=$(/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --version | cut -d " " -f 3)
    #     elif /Applications/Chromium.app/Contents/MacOS/Chromium --version > /dev/null 2>&1; then
    #         chrome_local_version=$(/Applications/Chromium.app/Contents/MacOS/Chromium --version | cut -d " " -f 2)
    #     fi
    # elif [[ "$os" == "windows" ]]; then
    #     readonly current_path=`pwd`
    #     if [[ "$cpu" == "64-bit" ]]; then
    #         cd /mnt/c/Program\ Files/Mozilla\ Firefox
    #     elif [[ "$cpu" == "32-bit" ]]; then
    #         cd /mnt/c/Program\ Files\ \(x86\)/Mozilla\ Firefox
    #     fi
    #     firefox_local_version="$(cmd.exe /c "firefox -v | more" | cut -d " " -f 3 | cut -d "." -f 1,2 | tr -d '\r')"
    #     cd $current_path
    # fi
    # geckodriver_versions=$(curl -fsSL https://github.com/mozilla/geckodriver/tags | grep '<a href="/mozilla/geckodriver/releases/tag/' | sed 's/.*href="\/\(.*\)">.*/\1/')
    # if [[ "$chrome_local_version" == "" ]]; then
    #     yellow "You don't have Chrome nor Chromium installed, so the script won't download the driver for you."
    #     return 0
    # fi

    LEAST_CHROME_VERSION=`curl -fsSL https://chromedriver.storage.googleapis.com/LATEST_RELEASE`
    if [[ $os == "linux" ]]; then
        if [[ $cpu == "64-bit" ]]; then
            chrome_url="https://chromedriver.storage.googleapis.com/$LEAST_CHROME_VERSION/chromedriver_linux64.zip"
        elif [[ $cpu == "32-bit" ]]; then
            chrome_url="https://chromedriver.storage.googleapis.com/$LEAST_CHROME_VERSION/chromedriver_linux32.zip"
        fi
    elif [[ $os == "mac" ]]; then
        if [[ $cpu == "64-bit" ]]; then
            chrome_url="https://chromedriver.storage.googleapis.com/$LEAST_CHROME_VERSION/chromedriver_mac64.zip"
        elif [[ $cpu == "32-bit" ]]; then
            chrome_url="https://chromedriver.storage.googleapis.com/$LEAST_CHROME_VERSION/chromedriver_mac32.zip"
        elif [[ $cpu == "M1" ]]; then
            chrome_url="https://chromedriver.storage.googleapis.com/$LEAST_CHROME_VERSION/chromedriver_mac64_m1.zip"
        fi
        echo $chrome_url
    elif [[ $os == "windows" ]]; then
        chrome_url="https://chromedriver.storage.googleapis.com/$LEAST_CHROME_VERSION/chromedriver_win32.zip"
    fi

    if curl -fsSL -o chromedriver.zip "$chrome_url" > /dev/null 2>&1; then
        unzip -qq chromedriver.zip
        rm chromedriver.zip
        green "Chrome driver installed successfully."
    else
        red "Your device architecture does not support chrome driver version $LEAST_CHROME_VERSION"
    fi
}

function firefox_driver_install {
    if [[ "$os" == "linux" ]]; then
        if firefox --version > /dev/null 2>&1; then
            firefox_local_version=$(firefox --version | cut -d " " -f 3 | cut -d "." -f 1,2)
        fi
    elif [[ "$os" == "mac" ]]; then
        if /Applications/Firefox.app/Contents/MacOS/firefox -v > /dev/null 2>&1; then
            firefox_local_version=$(/Applications/Firefox.app/Contents/MacOS/firefox -v | cut -d " " -f 3 | cut -d "." -f 1,2)
        fi
    elif [[ "$os" == "windows" ]]; then
        readonly current_path=`pwd`
        if [[ "$cpu" == "64-bit" ]]; then
            firefox_path="/mnt/c/Program Files/Mozilla Firefox"
        elif [[ "$cpu" == "32-bit" ]]; then
            firefox_path="/mnt/c/Program Files (x86)/Mozilla Firefox"
        fi
        if [[ -d "$firefox_path" ]]; then
            cd "$firefox_path"
            firefox_local_version="$(cmd.exe /c "firefox -v | more" | cut -d " " -f 3 | cut -d "." -f 1,2 | tr -d '\r')"
            cd "$current_path"
        fi
    fi
    if [[ "$firefox_local_version" == "" ]]; then
        yellow "You don't have Firefox broswer, so the script won't download the driver for you."
        return 0
    fi
    geckodriver_versions=$(curl -fsSL https://github.com/mozilla/geckodriver/tags | grep '<a href="/mozilla/geckodriver/releases/tag/' | sed 's/.*href="\/\(.*\)">.*/\1/')

    if [ $(bc <<< "$firefox_local_version > 90.0") -eq 1 ]; then
        firefox_url="https://github.com/$(echo $geckodriver_versions | cut -d " " -f 1)"
    elif [ $(bc <<< "$firefox_local_version > 79.0") -eq 1 ]; then
        firefox_url="https://github.com/$(echo $geckodriver_versions | cut -d " " -f 2)"
    elif [ $(bc <<< "$firefox_local_version >= 62.0") -eq 1 ]; then
        firefox_url="https://github.com/$(echo $geckodriver_versions | cut -d " " -f 9)"
    else
        red "Your Firefox version is not supported"
        return 0
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
        red "Your device architecture does not support firefox driver"
    fi
    if [[ "$os" == "linux" ]] || [[ $os == "mac" ]]; then
        curl -fsSL -o geckodriver.tar.gz "$firefox_url"
        tar -xzf geckodriver.tar.gz
        rm geckodriver.tar.gz
    elif [[ "$os" == "windows" ]]; then
        curl -fsSL -o geckodriver.zip "$firefox_url"
        unzip -qq geckodriver.zip
        rm geckodriver.zip
    fi
    green "Firefox driver installed successfully."
}

function main {
    get_os
    get_cpu
    get_package_manager
    check_br
    check_curl_or_wget
    check_zip
    check_tar
    chrome_driver_install
    firefox_driver_install
}

main