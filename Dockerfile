FROM mcr.microsoft.com/azure-cli@sha256:cf40cc2f8895161698cfb16aec989c60250e66c105b57752b30a20d87d515963

# Install required packages
RUN tdnf update -y; \
	tdnf upgrade -y; \
    tdnf install -y curl tar jq vim openssh-clients; \
    PYTHONPATH=/usr/lib/az/lib/python3.12/site-packages \
        python3.12 -m pip install --upgrade --prefix /usr/lib/az \
        "PyJWT>=2.13.0" "cryptography>=50.0.0" "certifi>=2026.10.18" "pip>=26.2.2"; \
    PYTHONPATH=/usr/lib/az/lib/python3.12/site-packages \
        python3.12 -m pip install --upgrade --prefix /usr \
        "msgpack>=1.2.1" "setuptools>=78.1.1"

# Install Docker
ENV DOCKER_CHANNEL=stable
ENV DOCKER_VERSION=29.10.0
ENV DOCKER_API_VERSION=1.52
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
