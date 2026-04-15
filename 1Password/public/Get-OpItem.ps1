function Get-OpItem {
    <#
    .SYNOPSIS
        Retrieves 1Password items by ID, name, or lists all items.

    .DESCRIPTION
        Get-OpItem retrieves items from 1Password using the 1Password CLI. You can retrieve a specific item by ID or name,
        or list all items in a vault. Concealed fields (passwords, tokens, etc.) are automatically converted to secure strings.
        Additional fields are added to the output object for easier access, there full meta data can be found in the fields 
        property of the output object.

    .PARAMETER Name
        The name of the 1Password item to retrieve. Use this parameter set to search for an item by its display name.
        This parameter is mutually exclusive with Id and All.

    .PARAMETER Id
        The ID of the 1Password item to retrieve. Use this parameter set to search for an item by its unique identifier.
        This parameter is mutually exclusive with Name and All.

    .PARAMETER All
        Retrieves all items from the specified vault. When used alone (without Name or Id), lists all items.
        This parameter is mutually exclusive with Name and Id.

    .PARAMETER VaultName
        The name of the 1Password vault to search within. This parameter is optional and works with any parameter set
        (Name, Id, or All). If not specified, all vaults will be searched.

    .OUTPUTS
        System.Management.Automation.PSCustomObject
        Returns one or more objects representing 1Password items. Each object contains the item's properties and
        fields as note properties, with concealed fields converted to SecureString objects.

    .EXAMPLE
        Get-OpItem -Name "GitHub Token"
        Retrieves the 1Password item named "GitHub Token" from all vaults. So you may get multiple results if there are name overlap

    .EXAMPLE
        Get-OpItem -Id "jkl4mnop5qrst6uvw7xy8z"
        Retrieves the 1Password item with the specified ID.

    .EXAMPLE
        Get-OpItem -All
        Lists all items from all vaults.

    .EXAMPLE
        Get-OpItem -All -VaultName "Work"
        Lists all items from the "Work" vault.

    .EXAMPLE
        Get-OpItem -Name "Database Password" -VaultName "Production"
        Retrieves the item named "Database Password" from the "Production" vault.

    .NOTES
        Requires 1Password CLI to be installed and initial setup to be completed by running Connect-Op.
        Runs Test-OpConnect before executing to verify setup.

    .LINK
        1Password CLI reference: https://developer.1password.com/docs/cli/reference/management-commands/item/
        1Password CLI installation guide: https://developer.1password.com/docs/cli/get-started/#install
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'GetItemByName')]
        [string]$Name,
        [Parameter(Mandatory = $true, ParameterSetName = 'GetItemById')]
        [string]$Id,
        [Parameter(Mandatory = $false, ParameterSetName = 'ListAllItems')]
        [switch]$All,

        [Parameter(Mandatory = $false)]
        [string]$VaultName
    )

    Test-OpConnect

    #we use array splatting to pass flags and their values to the op command
    $AllFlags = @()

    #item get command
    if ($PSCmdlet.ParameterSetName -eq 'GetItemById' -or $PSCmdlet.ParameterSetName -eq 'GetItemByName') {
        $AllFlags += 'get'
        if ($PSCmdlet.ParameterSetName -eq 'GetItemById') {
            $AllFlags += $Id 
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'GetItemByName') {
            $AllFlags += $Name 
        }
    }
    #item list command
    elseif ($PSCmdlet.ParameterSetName -eq 'ListAllItems') {
        $AllFlags += 'list'
    }

    #vault can be used with both get and list commands
    if ($VaultName) {
        $AllFlags += '--vault'
        $AllFlags += $VaultName
    }

    #execute the 1Password CLI command with the constructed flags
    $ItemResults = op item @AllFlags 2>&1

    #error and output separation into different variables
    $ItemResultsOut, $ItemResultsErr = $ItemResults.Where({ $_ -is [string] }, 'Split')
    $ItemResultsOut = $ItemResultsOut | ConvertFrom-Json
    if ($ItemResultsErr.Count -ne 0) {
        #writing first line as an error the rest gets dropped, NOT IDEAL
        Write-Error $ItemResultsErr[0].Exception.Message
        return
    }
    elseif ($ItemResultsOut.Count -eq 0) {
        Write-Warning "No Items found"
    }

    #NOTE: Contrary to the documentation for 'op item get', the '--reveal' flag is NOT required to see secrets in the output JSON.
    #So we will go grab each concealed field type and set it as a secure string
    foreach ($Item in $ItemResultsOut) {
        #get all the fields we care about to 
        $FieldsToSecure = $Item.fields | Where-Object { $_.type -eq 'CONCEALED' }
        foreach ($Field in $FieldsToSecure) {
            $Field.value = ConvertTo-SecureString -String $Field.value -AsPlainText
        }
    }

    #Now we will convert the fields for better output without ALL context we could dig deeper on the context later
    foreach ($Item in $ItemResultsOut) {
        $props = @{}
        $Item.fields | ForEach-Object {
            #we will use the id as the name of the field and the value as the value
            $props[$_.id] = $_.value
        }
        $Item | Add-Member -NotePropertyMembers $props
    }

    Write-Output $ItemResultsOut
}