# 1Password
This module is designed to interact with the 1Password CLI to assist with secret management in PowerShell.

## Prerequisites
Initial install of 1Password CLI package
```
winget install 1password-cli
```
Ensure the desktop app is installed ([download](https://1password.com/downloads)) and follow instructions to enable CLI integration: [1Password doc](https://developer.1password.com/docs/cli/app-integration/).
- As of writing (April 2026) Account > Settings > Developer > check "Integrate with 1Password CLI"

NOTE: The `Connect-Op` command will not attempt to install this winget package or 1Password desktop application both must be manually installed prior to using Connect-Op which will throw errors when checking that both of these prerequisites are complete.

## Initial Setup
Import the module, yes I am sorry this is not on the gallery yet I need to do that!
```powershell
Import-Module .\1Password\
```
Make the initial connection
```powershell
Connect-Op
```

THAT IS IT!

## Overview of high level steps Connect-Op will perform
1. Checks to make sure the 1password-cli package is installed.
2. Initial connection to Desktop app which will request master password: 
`op signin`
    - Really this will work with any command but it is nice to start with teh actual `signin` command.

3. Set environment variable to ensure output is in a JSON format:
    ```powershell
    $Env:OP_FORMAT = 'json'
    ```

4. Dangerous but necessary for tab completion which lets be honest I am firmly addicted to and reliant on:
    ```powershell
    op completion powershell | Out-String | Invoke-Expression
    ```
5. Create a global variable to confirm these steps have been compelted for other module functions to confirm if connection and inital setup has been completed. This is performed in the private function `Test-OpConnect`