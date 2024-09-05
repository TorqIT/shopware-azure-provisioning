FROM mcr.microsoft.com/azure-cli

# Install required packages
RUN tdnf install -y curl tar jq

# Install Docker
ENV DOCKER_CHANNEL=stable
ENV DOCKER_VERSION=20.10.21
ENV DOCKER_API_VERSION=1.41
RUN curl -fsSL "https://download.docker.com/linux/static/${DOCKER_CHANNEL}/x86_64/docker-${DOCKER_VERSION}.tgz" | tar -xzC /usr/local/bin --strip=1 docker/docker

# Required to use Bicep templates
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1

# Install AZ CLI extensions
RUN az config set bicep.use_binary_from_path=false
RUN az bicep install
RUN az extension add -n containerapp
RUN az extension add -n storage-preview

# Ensure Bicep extension is up-to-date
RUN az bicep upgrade

# Add Bicep templates and scripts
RUN mkdir -p azure/bicep && mkdir -p azure/scripts
ADD /*.sh /azure
ADD /bicep /azure/bicep
ADD /scripts /azure/scripts

WORKDIR /azure

CMD [ "tail", "-f", "/dev/null" ]
