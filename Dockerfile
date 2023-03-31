FROM ubuntu:20.04

RUN apt-get update && \
    apt-get install curl vim docker.io jq -y && \
    # Install Azure CLI
    curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Required to use Bicep templates
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1

# Install AZ CLI extensions
RUN az config set bicep.use_binary_from_path=false
RUN az bicep install
RUN az extension add -n containerapp

ADD /*.sh /azure/
ADD /bicep /azure/bicep

WORKDIR /azure

CMD [ "tail", "-f", "/dev/null" ]
