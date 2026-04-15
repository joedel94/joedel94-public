function Get-OpVault {
    <#
    .SYNOPSIS
        Retrieves 1Password vault information using the 1Password CLI.

    .DESCRIPTION
        This function allows you to fetch details about 1Password vaults by name, ID, or list all available vaults.
        It requires the 1Password CLI to be installed and the OP_FORMAT environment variable set to 'JSON'.

    .PARAMETER Name
        The name of the vault to retrieve.
        Cannot be used with -Id or -All.

    .PARAMETER Id
        The ID of the vault to retrieve.
        Cannot be used with -Name or -All.

    .PARAMETER All
        Lists all vaults in your 1Password account. Since this variable is optional, if neither -Name or -Id are provided, this parameter set will be used by default. Resulting in the default behavior of this function being to list all vaults.
        Cannot be used with -Name or -Id.

    .EXAMPLE
        Get-OpVault -Name "Personal"
        Retrieves the vault named "Personal".

    .EXAMPLE
        Get-OpVault -Id "abc123"
        Retrieves the vault with the specified ID.

    .EXAMPLE
        Get-OpVault -All
        Lists all vaults.

    .NOTES
        Requires 1Password CLI and OP_FORMAT environment variable set to 'JSON'.

    .LINK
        1Password CLI reference: https://developer.1password.com/docs/cli/reference/management-commands/vault
        1Password CLI installation guide: https://developer.1password.com/docs/cli/get-started/#install
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'GetVaultByName')]
        [string]$Name,
        [Parameter(Mandatory = $true, ParameterSetName = 'GetVaultById')]
        [string]$Id,
        [Parameter(Mandatory = $false, ParameterSetName = 'ListAllVaults')]
        [switch]$All
    )

    Test-OpConnect

    if ($PSCmdlet.ParameterSetName -eq 'GetVaultById') {
        $VaultResults = op vault get $Id 2>&1
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'GetVaultByName') {
        $VaultResults = op vault get $Name 2>&1
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'ListAllVaults') {
        $VaultResults = op vault list 2>&1
    }

    #error and output separation into different variables
    $VaultResultsOut, $VaultResultsErr = $VaultResults.Where({ $_ -is [string] }, 'Split')
    $VaultResultsOut = $VaultResultsOut | ConvertFrom-Json
    if ($VaultResultsErr.Count -ne 0) {
        #writing first line as an error the rest gets dropped, NOT IDEAL
        Write-Error $VaultResultsErr[0].Exception.Message
    }
    elseif ($VaultResultsOut.Count -eq 0) {
        Write-Warning "No Vaults found"
    }

    Write-Output $VaultResultsOut
}