FROM mcr.microsoft.com/azure-cli

# Install required packages
RUN tdnf install -y curl tar jq vim

# Install Docker
ENV DOCKER_CHANNEL=stable
ENV DOCKER_VERSION=20.10.21
ENV DOCKER_API_VERSION=1.41
RUN curl -fsSL "https://download.docker.com/linux/static/${DOCKER_CHANNEL}/x86_64/docker-${DOCKER_VERSION}.tgz" | tar -xzC /usr/local/bin --strip=1 docker/docker

# Configure Azure CLI
RUN az config set bicep.use_binary_from_path=False

# Add Bicep templates and scripts
RUN mkdir -p /azure
ADD /*.sh /azure
ADD /bicep /azure/bicep
ADD /helper-scripts /azure/helper-scripts
ADD /provisioning-scripts /azure/provisioning-scripts

WORKDIR /azure

CMD [ "tail", "-f", "/dev/null" ]
