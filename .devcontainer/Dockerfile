# Docker Container Build Version
ARG VARIANT="none"
FROM mcr.microsoft.com/vscode/devcontainers/python:${VARIANT}

# Options
ARG USERNAME="vscode"
ARG PACKER_VERSION="latest"
ARG ANSIBLE_VERSION="latest"
ARG PYWINRM_VERSION="latest"

COPY library-scripts/*.sh /tmp/library-scripts/

RUN SNIPPET="export PROMPT_COMMAND='history -a' && export HISTFILE=/home/$USERNAME/.nutanixdev/.bash_history" \
    && mkdir /home/$USERNAME/.nutanixdev \
    && touch /home/$USERNAME/.nutanixdev/.bash_history \
    && chown -R $USERNAME /home/$USERNAME/.nutanixdev \
    && echo "$SNIPPET" >> "/home/$USERNAME/.bashrc"

# Install Packer
RUN if [ "${PACKER_VERSION}" = "latest" ]; then \
        bash /tmp/library-scripts/packer-debian.sh ; \
    else \
        bash /tmp/library-scripts/packer-debian.sh "${PACKER_VERSION}" ; \
    fi

# Install Ansible
RUN if [ "${ANSIBLE_VERSION}" = "latest" ]; then \
        pip3 --disable-pip-version-check --no-cache-dir install ansible ; \
    else \
        pip3 --disable-pip-version-check --no-cache-dir install ansible==${ANSIBLE_VERSION} ; \
    fi

# Install pywinrm
RUN if [ "${PYWINRM_VERSION}" = "latest" ]; then \
        pip3 --disable-pip-version-check --no-cache-dir install pywinrm ; \
    else \
        pip3 --disable-pip-version-check --no-cache-dir install pywinrm==${PYWINRM_VERSION} ; \
    fi

# Install Additional Packages
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends xorriso udftools growisofs genisoimage

# Install Powershell
RUN bash /tmp/library-scripts/powershell.sh ;

# Install PSWSMan Module (PowerShell Remoting Auth Requirement)
RUN pwsh -Command 'Install-Module -Name PSWSMan -Force' ;
RUN pwsh -Command Install-WSMan ;
RUN apt-get update \ 
    && apt-get -y install gss-ntlmssp ;
RUN apt-get install -y inetutils-ping ;