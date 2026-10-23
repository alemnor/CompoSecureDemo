$wf = ".github\workflows"

@'
name: 01 - Hello World

on:
  push:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Hello
        run: echo "Building Application"
'@ | Set-Content "$wf\01-hello-world.yml"

@'
name: 02 - Build and Test

on:
  push:

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-dotnet@v4
        with:
          dotnet-version: "8.0.x"

      - run: dotnet restore
      - run: dotnet build --configuration Release
      - run: dotnet test --configuration Release
'@ | Set-Content "$wf\02-build-test.yml"

@'
name: 03 - Pull Request Validation

on:
  pull_request:
    branches:
      - main

jobs:
  build:
    runs-on: ubuntu-latest

    permissions:
      contents: read

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-dotnet@v4
        with:
          dotnet-version: "8.0.x"

      - run: dotnet restore
      - run: dotnet build --configuration Release
      - run: dotnet test --configuration Release
'@ | Set-Content "$wf\03-pr-validation.yml"

@'
name: 04 - CodeQL

on:
  pull_request:
    branches:
      - main

permissions:
  contents: read

jobs:
  codeql:
    runs-on: ubuntu-latest

    permissions:
      contents: read
      security-events: write

    steps:
      - uses: actions/checkout@v4

      - uses: github/codeql-action/init@v3
        with:
          languages: csharp

      - uses: github/codeql-action/autobuild@v3
      - uses: github/codeql-action/analyze@v3
'@ | Set-Content "$wf\04-codeql.yml"

@'
name: 05 - Dependency Review

on:
  pull_request:
    branches:
      - main

jobs:
  dependency-review:
    runs-on: ubuntu-latest

    permissions:
      contents: read

    steps:
      - uses: actions/checkout@v4
      - uses: actions/dependency-review-action@v4
'@ | Set-Content "$wf\05-dependency-review.yml"

@'
name: 06 - Package Artifacts

on:
  push:

jobs:
  package:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-dotnet@v4
        with:
          dotnet-version: "8.0.x"

      - run: dotnet publish -c Release -o publish

      - run: tar -czf application.tar.gz publish/

      - uses: actions/upload-artifact@v4
        with:
          name: application-package
          path: application.tar.gz
'@ | Set-Content "$wf\06-package.yml"

@'
name: 07 - Environment Deployment

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest

    environment:
      name: production

    steps:
      - run: echo "Waiting for Environment Approval"
'@ | Set-Content "$wf\07-environment-deploy.yml"

@'
name: 08 - OIDC Azure Login

on:
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest

    permissions:
      id-token: write
      contents: read

    steps:
      - uses: actions/checkout@v4

      - uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - run: az account show
'@ | Set-Content "$wf\08-oidc-deploy.yml"

@'
name: 09 - Build Attestation

on:
  push:

jobs:
  build:
    runs-on: ubuntu-latest

    permissions:
      contents: read
      id-token: write
      attestations: write

    steps:
      - uses: actions/checkout@v4

      - run: |
          mkdir publish
          echo "hello" > publish/app.txt
          tar -czf application.tar.gz publish/

      - uses: actions/upload-artifact@v4
        with:
          name: application-package
          path: application.tar.gz

      - uses: actions/attest-build-provenance@v2
        with:
          subject-path: application.tar.gz
'@ | Set-Content "$wf\09-attestation.yml"

@'
name: 10 - Verify Provenance

on:
  workflow_dispatch:

jobs:
  verify:
    runs-on: ubuntu-latest

    permissions:
      contents: read

    steps:
      - uses: actions/download-artifact@v4
        with:
          name: application-package

      - name: Verify Attestation
        env:
          GH_TOKEN: ${{ github.token }}
        run: |
          gh attestation verify application.tar.gz --repo ${{ github.repository }}
'@ | Set-Content "$wf\10-attestation-verification.yml"
