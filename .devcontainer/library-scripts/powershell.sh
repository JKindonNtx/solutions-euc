# !/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# Syntax: ./powershell.sh

architecture="$(uname -m)"
case ${architecture} in
    x86_64) architecture="amd64";;
    aarch64 | armv8*) architecture="arm64";;
esac

if [ "${architecture}" = "arm64" ]; then
    echo "Architecture is ARM"
    posh="https://github.com/PowerShell/PowerShell/releases/download/v7.3.0/powershell-7.3.0-linux-arm64.tar.gz"
else
    echo "Architecture is X86_64"
    posh="https://github.com/PowerShell/PowerShell/releases/download/v7.3.0/powershell-7.3.0-linux-x64.tar.gz"
fi

echo "Downloading PowerShell from $posh"
curl -L -o /tmp/powershell.tar.gz $posh

echo "Installing PowerShell"
sudo mkdir -p /opt/microsoft/powershell/7
sudo tar zxf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/7
sudo chmod +x /opt/microsoft/powershell/7/pwsh
sudo ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh
