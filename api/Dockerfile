
#create build-env image that compiles the project
FROM microsoft/dotnet:2.1-sdk AS build

WORKDIR /app

# copy csproj and restore as distinct layers
COPY *.csproj ./
RUN dotnet restore

# copy everything else and build
COPY . ./
RUN dotnet publish -c Release -o out

#create runtime image that hosts the binaries
FROM microsoft/dotnet:2.1-aspnetcore-runtime AS runtime

WORKDIR /app

COPY --from=build /app/out .

ENTRYPOINT ["dotnet", "aspnet-core-dotnet-core.dll"]
