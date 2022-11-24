# Docker Container Build Version
ARG VARIANT=3-bullseye
FROM mcr.microsoft.com/vscode/devcontainers/python:${VARIANT}

# Options
ARG USERNAME="vscode"
ARG PACKER_VERSION="none"
ARG ANSIBLE_VERSION="none"
ARG PYWINRM_VERSION="none"

COPY library-scripts/*.sh /tmp/library-scripts/

RUN SNIPPET="export PROMPT_COMMAND='history -a' && export HISTFILE=/home/$USERNAME/.nutanixdev/.bash_history" \
    && mkdir /home/$USERNAME/.nutanixdev \
    && touch /home/$USERNAME/.nutanixdev/.bash_history \
    && chown -R $USERNAME /home/$USERNAME/.nutanixdev \
    && echo "$SNIPPET" >> "/home/$USERNAME/.bashrc"

# Install Packer
RUN if [ "${PACKER_VERSION}" != "none" ]; then \
        bash /tmp/library-scripts/packer-debian.sh "${PACKER_VERSION}"; \
    fi

# Install Ansible
RUN if [ "${ANSIBLE_VERSION}" != "none" ]; then \
        pip3 --disable-pip-version-check --no-cache-dir install \
        ansible==${ANSIBLE_VERSION} \
        pywinrm==${PYWINRM_VERSION}; \
    fi

# Install Additional Packages
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends xorriso udftools growisofs genisoimage

# Install Powershell
RUN curl -L -o /tmp/powershell.tar.gz https://github.com/PowerShell/PowerShell/releases/download/v7.3.0/powershell-7.3.0-linux-arm64.tar.gz
RUN sudo mkdir -p /opt/microsoft/powershell/7
RUN sudo tar zxf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/7
RUN sudo chmod +x /opt/microsoft/powershell/7/pwsh
RUN sudo ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh
