FROM ubuntu:20.04

RUN apt-get update && \
    apt-get install curl vim openssh-client mariadb-server unzip zip docker.io -y && \
    # Install Azure CLI
    curl -sL https://aka.ms/InstallAzureCLIDeb | bash

ADD /provisioning/ /provisioning
COPY /entrypoint.sh /entrypoint.sh
RUN chmod +x /provisioning/**/*.sh

# Required to use Bicep templates
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1

WORKDIR /provisioning

RUN az config set bicep.use_binary_from_path=false
RUN az bicep install
RUN az extension add -n containerapp

ENTRYPOINT [ "bash", "/entrypoint.sh" ]
