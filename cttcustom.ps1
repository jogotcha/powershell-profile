# This runs after Microsoft.PowerShell_profile.ps1
# Write-Host "loading cttcustom.ps1"

Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
        [Console]::InputEncoding = [Console]::OutputEncoding = $OutputEncoding = [System.Text.Utf8Encoding]::new()
        $Local:word = $wordToComplete.Replace('"', '""')
        $Local:ast = $commandAst.ToString().Replace('"', '""')
        winget complete --word="$Local:word" --commandline "$Local:ast" --position $cursorPosition | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
}

#Visual Studio DevShell Integration
$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
if (-not (Test-Path -Path $vswhere)) {
    Write-Warning "vswhere not found at '$vswhere'. Visual Studio DevShell not loaded."
} else {
    $vs = & $vswhere -latest -products * -requires Microsoft.Component.MSBuild -format json | ConvertFrom-Json | Select-Object -First 1
    if (-not $vs) {
        Write-Warning "No Visual Studio instance found. Visual Studio DevShell not loaded."
    } else {
        $devShellDll = Join-Path $vs.installationPath 'Common7\Tools\Microsoft.VisualStudio.DevShell.dll'
        if (-not (Test-Path -Path $devShellDll)) {
            Write-Warning "DevShell DLL not found at '$devShellDll'. Visual Studio DevShell not loaded."
        } else {
            Import-Module $devShellDll
            Enter-VsDevShell -VsInstanceId $vs.instanceId -SkipAutomaticLocation -DevCmdArguments """-arch=x64 -host_arch=x64 -no_logo"""
        }
    }
}

if (Get-Module -ListAvailable -Name PSKubectlCompletion) {
    Import-Module -Name PSKubectlCompletion
} else {
    Write-Warning "PSKubectlCompletion module not found. Run setup.ps1 to install it."
}

function ex() {
    explorer.exe .
}

function env {
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [string] $Pattern,
        [switch] $Regex,
        [switch] $Raw
    )

    $items = Get-ChildItem Env: | Sort-Object Name
    if ($Pattern) {
        if ($Regex) {
            $items = $items | Where-Object { $_.Name -match $Pattern -or $_.Value -match $Pattern }
        } else {
            $items = $items | Where-Object { $_.Name -like "*$Pattern*" -or $_.Value -like "*$Pattern*" }
        }
    }

    if ($Raw) { return $items }

    $items | Format-Table -AutoSize Name, Value
}

mise activate pwsh | Out-String | Invoke-Expression
