# OZO AD Lab Create VMs

## Description
An interactive script that creates a the Hyper-V virtual machines required for the One Zero One AD Lab as described in [Active Directory Lab: Create the Virtual Machines](https://onezeroone.dev/active-directory-lab-create-the-virtual-machines).

## Prerequisites
To use this script you must first install Hyper-V and restart. Run the following in an _Administrator_ PowerShell:
```powershell
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
Restart-Computer
```

If your user is not an _Administrator_, have an administrator add your user to the _Hyper-V Administrators_ group.

## Installation
This script is published to [PowerShell Gallery](https://learn.microsoft.com/en-us/powershell/scripting/gallery/overview?view=powershell-5.1). Ensure your system is configured for this repository then execute the following in an _Administrator_ PowerShell:

```powershell
Install-Script ozo-ad-lab-create-vms
```

## Usage
Execute this script in an _Administrator_ PowerShell to implement the "One Zero One" Windows event log provider:

```powershell
ozo-ad-lab-create-vms
    -ClientISO <String>
    -DCISO     <String>
    -LaofISO   <String>
    -ServerISO <String>
```

## Parameters
|Parameter|Description|
|---------|-----------|
|`ClientISO`|Path to the [customized\] Client ISO. Defaults to `C:\ozo-ad-lab\ISO\AD-Lab-Client.iso`.|
|`DCISO`|Path to the [customized\] DC ISO. Defaults to `C:\ozo-ad-lab\ISO\AD-Lab-DC.iso`.|
|`LaofISO`|Path to the Windows 11 Lanuages & Optional Features ISO. Defaults to `C:\ozo-ad-lab\ISO\Windows-11-Lanuages-and-Optional-Features.iso`.|
|`ServerISO`|Path to the [customized\] Server ISO. Defaults to `C:\ozo-ad-lab\ISO\AD-Lab-Server.iso`.|

## Examples
```powershell
ozo-ad-lab-create-vms -ClientISO (Join-Path -Path $Env:USERPROFILE -ChildPath "Downloads\AD-Lab-Client.iso")
```

## Notes
This script automates part 5/8 in a [series that illustrates how to customize the Windows installer media to automate the process of installing a Windows AD domain controller, a Windows file server, and a Windows desktop environment](https://onezeroone.dev/active-directory-lab-introduction).

## Acknowledgements
Special thanks to my employer, [Sonic Healthcare USA](https://sonichealthcareusa.com), who has supported the growth of my PowerShell skillset and enabled me to contribute portions of my work product to the PowerShell community.
