# Deploy-HyperV-JEA.ps1
# Hyper-V JEA Operator multi-host deployment script

$DomainName    = "AD_NAME"
$OperatorGroup = "GRP-HyperV-Operator"
$JEAName       = "HyperV-Operator"
$ModuleRoot    = "C:\Program Files\WindowsPowerShell\Modules\HyperVJEA"
$TranscriptDir = "C:\JEA-Transcripts"

New-Item -ItemType Directory -Path $ModuleRoot -Force | Out-Null
New-Item -ItemType Directory -Path "$ModuleRoot\RoleCapabilities" -Force | Out-Null
New-Item -ItemType Directory -Path $TranscriptDir -Force | Out-Null

$psm1 = "$ModuleRoot\HyperVJEA.psm1"
if (!(Test-Path $psm1)) {
    "# HyperV JEA Module" | Out-File $psm1 -Encoding UTF8
}

$psrc = "$ModuleRoot\RoleCapabilities\HyperVOperator.psrc"
@"
@{
    VisibleCmdlets = @(
        'Get-VM',
        'Start-VM',
        'Stop-VM',
        'Restart-VM'
    )

    ModulesToImport = @('Hyper-V')
    VisibleExternalCommands = @()
    VisibleProviders        = @()
}
"@ | Out-File $psrc -Encoding UTF8 -Force

$pssc = "$ModuleRoot\HyperV-Operator.pssc"
@"
@{
    SchemaVersion = '2.0.0.0'
    SessionType = 'RestrictedRemoteServer'
    RunAsVirtualAccount = \$true

    RoleDefinitions = @{
        '$DomainName\$OperatorGroup' = @{ RoleCapabilities = 'HyperVOperator' }
    }

    ModulesToImport = 'Hyper-V'
    TranscriptDirectory = '$TranscriptDir'
}
"@ | Out-File $pssc -Encoding UTF8 -Force

if (Get-PSSessionConfiguration -Name $JEAName -ErrorAction SilentlyContinue) {
    Disable-PSSessionConfiguration -Name $JEAName -Force
}

Register-PSSessionConfiguration -Name $JEAName -Path $pssc -Force

Add-LocalGroupMember -Group "Remote Management Users" -Member "$DomainName\$OperatorGroup" -ErrorAction SilentlyContinue

Restart-Service WinRM
Write-Host "JEA deployment completed" -ForegroundColor Green
