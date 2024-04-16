FROM ghcr.io/actions/actions-runner:2.315.0

USER root

RUN apt-get update && apt-get install -y curl wget jq unzip nodejs gnupg software-properties-common && apt-get clean && rm -rf /var/lib/apt/lists/* && ln -s /usr/bin/nodejs /usr/local/bin/node
RUN	curl -sL https://aka.ms/InstallAzureCLIDeb | bash

COPY ./entrypoint.sh ./entrypoint.sh
RUN chmod +x ./entrypoint.sh

USER runner

ENTRYPOINT ["./entrypoint.sh"]