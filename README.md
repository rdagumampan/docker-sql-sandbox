# docker-sqlsandbox (WORK IN PROGRESS)
A portal sandbox container sql server, api, web and gherkin-based tests

Pre-requisites:

- Git for Windows
- Docker for Windows
- VS Code / VS 2017
- .NET Core 2.1 SDK
- .NET Framework 4.5 SDK

docker network create -d nat --subnet=192.168.1.0/24 --gateway=192.168.1.254 sandbox-vn
