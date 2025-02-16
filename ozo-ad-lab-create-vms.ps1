#Requires -Modules @{ModuleName="OZO";ModuleVersion="1.5.0"},@{ModuleName="OZOLogger";ModuleVersion="1.1.0"}

<#PSScriptInfo
    .VERSION 1.0.0
    .GUID e2071482-27a4-415c-b3db-43d5351d24bb
    .AUTHOR Andy Lievertz <alievertz@onezeroone.dev>
    .COMPANYNAME One Zero One
    .COPYRIGHT This script is licensed under the GNU Public License ("GPL") version 2.0.
    .TAGS
    .LICENSEURI https://github.com/onezeroone-dev/OZO-AD-Lab-Create-VMs/blob/main/LICENSE
    .PROJECTURI https://github.com/onezeroone-dev/OZO-AD-Lab-Create-VMs
    .ICONURI
    .EXTERNALMODULEDEPENDENCIES 
    .REQUIREDSCRIPTS
    .EXTERNALSCRIPTDEPENDENCIES
    .RELEASENOTES https://github.com/onezeroone-dev/OZO-AD-Lab-Create-VMs/blob/main/CHANGELOG.md
    .PRIVATEDATA
#>

<# 
    .DESCRIPTION 
    Creates the Hyper-V VMs required for the One Zero One AD Lab 
    .LINK
    https://github.com/onezeroone-dev/OZO-AD-Lab-Create-VMs/blob/main/README.md
#> 
Param(
    [Parameter(Mandatory=$false,HelpMessage="Path to the Client ISO")][String]$ClientISO = "C:\ozo-ad-lab\ISO\AD-Lab-Client.iso",
    [Parameter(Mandatory=$false,HelpMessage="Path to the DC ISO")][String]$DCISO = "C:\ozo-ad-lab\ISO\AD-Lab-DC.iso",
    [Parameter(Mandatory=$false,HelpMessage="Path to the Lanugages & Optional Features ISO")][String]$LaofISO = "C:\ozo-ad-lab\ISO\Windows-11-Lanuages-and-Optional-Features.iso",
    [Parameter(Mandatory=$false,HelpMessage="Path to the Server ISO")][String]$ServerISO = "C:\ozo-ad-lab\ISO\AD-Lab-Server.iso"
)

# CLASSES

Class ADLCV {
    # PROPERTIES

    # METHODS
    # Constructor method
    ADLCV() {
        # Set properties
    }
}

# FUNCTIONS
Get-OZOHyperVAdministrator {
    # Determine if current user is a member of Administrators or Hyper-V Administrators
    If ((([ADSI]"WinNT://./Hyper-V Administrators,group").psbase.Invoke("Members") | ForEach-Object {$_.GetType().InvokeMember("Name",'GetProperty', $null, $_, $null)}) -Contains [System.Environment]::UserName) {
        # User is a member of the Hyper-V Administrators group
        return $true
    } Else {
        # User not a member of the Hyper-V Administrators group
        return $false
    }
}

# MAIN
[ADLCV]::new() | Out-Null
