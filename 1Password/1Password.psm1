#Dot source all public and private functions
$FunctionPaths = @('\public', '\private')
$AllPs1Files = @()
foreach ($Path in $FunctionPaths) {
    $FullPath = Join-Path -Path $PSScriptRoot -ChildPath "$Path\*.ps1"
    $AllPs1Files += Get-ChildItem -Path $FullPath
}

foreach ($Ps1 in $AllPs1Files) {
    . $Ps1.FullName
}