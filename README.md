# OZO AD Lab Create VMs

## Description
An interactive script that creates a the Hyper-V virtual machines required for the One Zero One AD Lab as described in [Active Directory Lab: Create the Virtual Machines](https://onezeroone.dev/active-directory-lab-create-the-virtual-machines). If a virtual machine already exists, it is skipped.

## Prerequisites
To use this script you must first install Hyper-V and restart, and create two Hyper-V virtual switches. Please see [Active Directory Lab: Prerequisites](https://onezeroone.dev/active-directory-lab-prerequisites).

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
    -RouterISO <String>
    -ServerISO <String>
```

## Parameters
|Parameter|Description|
|---------|-----------|
|`ClientISO`|Path to the [customized\] Client ISO. Defaults to `C:\ozo-ad-lab\ISO\AD-Lab-Client.iso`.|
|`DCISO`|Path to the [customized\] DC ISO. Defaults to `C:\ozo-ad-lab\ISO\AD-Lab-DC.iso`.|
|`LaofISO`|Path to the Windows 11 Lanuages & Optional Features ISO. Defaults to `C:\ozo-ad-lab\ISO\Windows-11-Lanuages-and-Optional-Features.iso`.|
|`RouterISO`|Path to the [customized\] Router ISO. Defaults to `C:\ozo-ad-lab\ISO\AD-Lab-Router.iso`.|
|`ServerISO`|Path to the [customized\] Server ISO. Defaults to `C:\ozo-ad-lab\ISO\AD-Lab-Server.iso`.|
|`VHDXPath`|Path for the VHDX files. Defaults to `$Env:ProgramData\Microsoft\Windows\Virtual Hard Disks`.|

## Examples
### Example 1
When all assets are named and located as described in the [AD Lab series](https://onezeroone.dev/active-directory-lab-introduction), you can run this script with no parameters:
```powershell
ozo-ad-lab-create-vms
```
### Example 2
If your customized installer ISOs are located elsewhere, you can specify their locations using the relevant parameters, e.g,. if the Client and DC ISOs are in your user _Downloads_ directory:
```powershell
$isoPath = (Join-Path -Path $Env:USERPROFILE -ChildPath "Downloads")
ozo-ad-lab-create-vms -ClientISO "$isoPath\AD-Lab-Client.iso" -DCISO "$isoPath\AD-Lab-DC.iso"
```

## Notes
This script automates part 5/8 in a [series that illustrates how to customize the Windows installer media to automate the process of installing a Windows AD domain controller, a Windows file server, and a Windows desktop environment](https://onezeroone.dev/active-directory-lab-introduction).

## Acknowledgements
Special thanks to my employer, [Sonic Healthcare USA](https://sonichealthcareusa.com), who has supported the growth of my PowerShell skillset and enabled me to contribute portions of my work product to the PowerShell community.
