FROM mcr.microsoft.com/azure-cli

# Install cURL
RUN apk update -qq && \
    apk add curl

# Install Docker
ENV DOCKER_CHANNEL stable
ENV DOCKER_VERSION 20.10.21
ENV DOCKER_API_VERSION 1.41
RUN curl -fsSL "https://download.docker.com/linux/static/${DOCKER_CHANNEL}/x86_64/docker-${DOCKER_VERSION}.tgz" | tar -xzC /usr/local/bin --strip=1 docker/docker

# Required to use Bicep templates
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1

# Install AZ CLI extensions
RUN az config set bicep.use_binary_from_path=false
RUN az bicep install
RUN az extension add -n containerapp
RUN az extension add -n storage-preview

ADD /*.sh /azure
ADD /scripts /azure/scripts
ADD /bicep /azure/bicep

WORKDIR /azure

CMD [ "tail", "-f", "/dev/null" ]
