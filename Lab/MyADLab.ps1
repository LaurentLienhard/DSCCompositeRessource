#This intro script is pretty almost the same like the previous one. But this lab is connected to the internet over the external virtual switch.
#The IP addresses are assigned automatically like in the previous samples but AL also assignes the gateway and the DNS servers to all machines
#that are part of the lab. AL does that if it finds a machine with the role 'Routing' in the lab.

$LabName = "MyAdLab"

New-LabDefinition -Name $LabName -DefaultVirtualizationEngine HyperV -VmPath C:\LabSources\Labs

Set-LabInstallationCredential -Username Install -Password Somepass1

Add-LabVirtualNetworkDefinition -Name $LabName -AddressSpace '192.168.11.0/24'
Add-LabVirtualNetworkDefinition -Name 'External' -HyperVProperties @{ SwitchType = 'External'; AdapterName = 'Wi-Fi' }
Add-LabDomainDefinition -Name contoso.com -AdminUser Install -AdminPassword Somepass1 

$netAdapter = @()
$netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch $LabName
$netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch 'External' -UseDhcp

$roles = @()
$roles += Get-LabMachineRoleDefinition -Role RootDC
$roles += Get-LabMachineRoleDefinition -Role Routing

$postInstallActivitycDC = @()
$postInstallActivitycDC += Get-LabPostInstallationActivity -ScriptFileName 'PrepareRootDomain.ps1' -DependencyFolder $labSources\PostInstallationActivities\PrepareRootDomain

Add-LabMachineDefinition -Name SRV-DC01 -Memory 4GB -OperatingSystem 'Windows Server 2022 Datacenter (Desktop Experience)' -Roles $roles -NetworkAdapter $netAdapter -DomainName contoso.com -PostInstallationActivity $postInstallActivitycDC

Add-LabMachineDefinition -Name SRV-BORKER01 -Memory 2GB -OperatingSystem 'Windows Server 2022 Datacenter' -Network $LabName -DomainName contoso.com
Add-LabMachineDefinition -Name SRV-RDS01 -Memory 2GB -OperatingSystem 'Windows Server 2022 Datacenter' -Network $LabName -DomainName contoso.com
Add-LabMachineDefinition -Name PC-ADMIN01 -Memory 8GB -OperatingSystem 'Windows 11 Enterprise' -Network $LabName -DomainName contoso.com

Install-Lab

Import-Lab -Name $LabName -NoValidation
Invoke-LabCommand -ComputerName PC-ADMIN01 -ScriptBlock {Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://ohmyposh.dev/install.ps1'))}
Get-LabVM | ForEach-Object {
    Invoke-LabCommand -ComputerName $_.Name -ScriptBlock {Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force}
    Invoke-LabCommand -ComputerName $_.Name -ScriptBlock {Install-Module xPSDesiredStateConfiguration,Chocolatey,ComputerManagementDsc,ActiveDirectoryDsc -Scope AllUsers -Force -Confirm:$false}
}

Import-Lab -Name $LabName -NoValidation
Configuration LocalConfig {

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xPSDesiredStateConfiguration
    Import-DscResource -ModuleName Chocolatey

           ChocolateySoftware ChocoInst {
            Ensure = "Present"
        }

        ChocolateyPackage "cascadiacodepl" {
            Name = "cascadiacodepl"
            Ensure = "Present"
        }

        ChocolateyPackage "cascadia-code-nerd-font" {
            Name = "cascadia-code-nerd-font"
            Ensure = "Present"
        }

        ChocolateyPackage "Git" {
            Name = "Git"
            Ensure = 'Present'
            ChocolateyOptions = @{PackageParameters = "/GitAndUnixToolsOnPath /NoGitLfs /SChannel /NoAutoCrlf"}
        }

        ChocolateyPackage 'VSCode' {
            Name = 'vscode'
            Ensure = 'Present'
        }
}
Invoke-LabDscConfiguration -Configuration (get-command -Name LocalConfig) -ComputerName PC-ADMIN01

Restart-LabVM -ComputerName PC-ADMIN01

Show-LabDeploymentSummary -Detailed
