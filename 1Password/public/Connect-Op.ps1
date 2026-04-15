function Connect-Op {
    <#
    .SYNOPSIS
        Establishes a connection to the 1Password CLI tool and performs basic setup for user with 1Password module in PowerShell.

    .DESCRIPTION
        This function performs a series of checks and initializations to prepare the PowerShell environment
        for use with the 1Password module. It handles the following steps:

        1. Validates that the op.exe CLI command is installed and accessible
        2. Ensures the 1Password process is running
        3. Configures the OP_FORMAT environment variable to JSON format
        4. Initializes command completion for the op CLI tool
        5. Authenticates and signs in to the 1Password account via CLI
        6. Verifies the authenticated session by retrieving user information
        7. Sets a global connection object to flag successful initialization

    .EXAMPLE
        Connect-Op

        Establishes a connection to 1Password CLI and initializes the module for use.
        The function will prompt for authentication if not already signed in.

    .OUTPUTS
        None. The function sets the global variable $Global:1PasswordConnection with connection status
        and user information.

    .NOTES
        - Requires the 1Password CLI tool (op.exe) to be installed
        - The OP_FORMAT environment variable is automatically set to 'JSON'
        - This function must be called before using other functions in the 1Password module
        - The function sets up tab completion for the op CLI command
        - Authentication state is tracked in the $Global:1PasswordConnection variable

    .LINK
        1Password CLI installation guide: https://developer.1password.com/docs/cli/get-started/#install

    #>

    [CmdletBinding()]
    param()

    try {
        #check the 1Password process is running, if not attempt to start it, if it fails to start throw an error
        $1PasswordProcess = Get-Process -Name '1Password' -ErrorAction Stop
        Write-Verbose '1Password process found, continuing with setup'
    }
    catch {
        #default file path for 1Password
        $Default1PasswordPath = Join-Path -Path "$Env:ProgramFiles" -ChildPath '\WindowsApps\Agilebits.1Password*\1Password.exe'
        #TODO: find a way to start the process as a detached process, start-process will only spawn a child process that will close if the terminal session closes which is not the behavior we want.
        throw 'Issue encountered looking for 1Password process, and unable to start 1Password, confirm it is installed and running.'
    }

    #Check the existence of the op commands
    $OpCommand = Get-Command -Name op.exe
    if ($OpCommand -and ($OpCommand.Source -match '^.*AgileBits\.1Password\.CLI_Microsoft.*\\op\.exe$')) {
        Write-Verbose 'op cli command found, continuing with setup'
    }
    else {
        throw 'op cli command not found, install 1password-cli'
    }

    #Check JSON environment variable is set, if not throw a warning
    if ($env:OP_FORMAT -ne 'JSON') {
        Write-Verbose '1Password environment variable OP_FORMAT not set, required for JSON format output, setting...'
        $env:OP_FORMAT = 'JSON'
    }

    #Setup tab completion in case we will actually use the terminal cli command op
    try {
        Write-Verbose 'Setting up op completion using 1password-cli powershell feature'
        op completion powershell | Out-String | Invoke-Expression
    }
    catch {
        Write-Warning 'Issue encountered setting up completion engine from op command, completion will not be available.'
    }
    
    #TODO: Move this to its own function
    #TODO: there has to be a better way to grab stderr output from an external command, if not this might be able to be made into a private function?
    $SignInResult = op signin 2>&1
    $SignInResultOut, $SignInResultErr = $SignInResult.Where({ $_ -is [string] }, 'Split')
    #should not be necessary since we do not expect output but we will leave this here in case it is needed.
    $SignInResultOut = $SignInResultOut | ConvertFrom-Json
    if ($SignInResultErr.count -ne 0) {
        throw $SignInResultErr[0].Exception.Message
    }

    #TODO: Move this to its own function
    $WhoAmIResult = op whoami 2>&1
    $WhoAmIResultOut, $WhoAmIResultErr = $WhoAmIResult.Where({ $_ -is [string] }, 'Split')
    $WhoAmIResultOut = $WhoAmIResultOut | ConvertFrom-Json
    if ($WhoAmIResultErr.count -ne 0) {
        throw $WhoAmIResultErr[0].Exception.Message
    }
    else {
        Write-Verbose "Signed in user found, $($WhoAmIResultOut.Email)"
        
        #final step we set the global variable to indicate to other functions in module that a connection has been made
        $Global:1PasswordConnection = [pscustomobject]@{
            Status = $true
            WhoAmI = $WhoAmIResultOut
        }   
    }
}