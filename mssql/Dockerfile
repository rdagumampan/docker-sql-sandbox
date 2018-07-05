#ARG SA_PASSWORD=Denmark2018

FROM microsoft/mssql-server-windows-developer

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

ENV SA_PASSWORD=Denmark2018
ENV ACCEPT_EULA=Y

#copy the migration
WORKDIR /db
COPY db .

RUN powershell -Command (C:\db\Run.ps1 -sqlServerInstance ".\\" -sqlDatabase "ServiceHealth")

#run migration steps from external volume
# CMD .\Run.ps1 -sqlServerInstance ".\\" -sqlDatabase "ServiceHealth"
#CMD .\Run.ps1
 