function Test-OpConnect {
    [CmdletBinding()]
    param()

    #checks Connect-Op global variable to see if it has been executed and setup is complete
    if ($Global:1PasswordConnection) {
        Write-Verbose "Confirmed setup has been completed, signed in user is $($Global:1PasswordConnection.WhoAmI.Email)"
    }
    else {
        throw '1Password module setup has not been complete, run Connect-Op'
    }
}