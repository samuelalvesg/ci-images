# .NET SDK image for CI: the official SDK plus the tools the backend pipeline would otherwise reinstall on every run
# (dotnet-ef, python3 for the repo check scripts, jq). Testcontainers needs the host Docker socket, mounted by the job.
# Licensed under Apache-2.0 (see LICENSE); the .NET SDK and Ubuntu packages keep their own licenses.
ARG DOTNET_VERSION=10.0
FROM mcr.microsoft.com/dotnet/sdk:${DOTNET_VERSION}

ARG DOTNET_EF_VERSION=10.0.*

ENV DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    DOTNET_NOLOGO=1 \
    DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1 \
    DOTNET_CLI_HOME=/usr/local/dotnet-home \
    XDG_DATA_HOME=/usr/local/dotnet-home/.local/share \
    XDG_CONFIG_HOME=/usr/local/dotnet-home/.config \
    DOTNET_TOOLS=/usr/local/dotnet-tools \
    NUGET_PACKAGES=/usr/local/nuget/packages
ENV PATH=${DOTNET_TOOLS}:${PATH}

RUN apt-get update && apt-get install -y --no-install-recommends python3 jq git ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && git config --system --add safe.directory '*' \
    && dotnet tool install dotnet-ef --version "${DOTNET_EF_VERSION}" --tool-path "${DOTNET_TOOLS}" \
    && mkdir -p "${NUGET_PACKAGES}" "${XDG_DATA_HOME}" "${XDG_CONFIG_HOME}" &&chmod -R a+rwX "${NUGET_PACKAGES}" "${DOTNET_TOOLS}" "${DOTNET_CLI_HOME}" \
    && dotnet --version && dotnet-ef --version

LABEL org.opencontainers.image.licenses="Apache-2.0"
