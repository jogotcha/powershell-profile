# mainly quake mode headers for tab switching i think
# oh-my-posh init pwsh --config "~\paradox.omp.json" | Invoke-Expression
function Set-EnvVar {
    $global:GitStatus = Get-GitStatus
    if ($global:GitStatus) {
        $env:POSH_GIT_STRING = $global:GitStatus.RepoName + $(Write-GitStatus -Status $global:GitStatus)
    }
    else {
        $env:POSH_GIT_STRING = $PWD
    }
}
New-Alias -Name 'Set-PoshContext' -Value 'Set-EnvVar' -Scope Global -Force



#Todo Custom module import
$MyModulePath = "C:\Users\usr\Source\repos\PowerShellTools\Modules"
$env:PSModulePath = $env:PSModulePath + "$([System.IO.Path]::PathSeparator)$MyModulePath"
Import-Module ema-tools
Import-Module "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\Common7\Tools\Microsoft.VisualStudio.DevShell.dll"


# not entirely sure why..
Enter-VsDevShell f778da60 -SkipAutomaticLocation