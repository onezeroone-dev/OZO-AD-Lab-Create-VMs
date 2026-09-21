# OZO AD Lab Create VMs

## Description
This interactive script automates [part](https://onezeroone.dev/active-directory-lab-part-iii-create-the-virtual-machines/) of a One Zero One [series](https://onezeroone.dev/active-directory-lab-part-i-introduction/) that illustrates how to automate the process of deploying an AD Lab. It creates the required Hyper-V virtual machines. If a virtual machine already exists, it is skipped.

## Prerequisites
To use this script you must first install Hyper-V and restart, and create two Hyper-V virtual switches. Please see [Active Directory Lab Part III: Installation Prerequisites](https://onezeroone.dev/active-directory-lab-part-iii-installation-prerequisites/).

## Installation
This script is published to [PowerShell Gallery](https://learn.microsoft.com/en-us/powershell/scripting/gallery/overview?view=powershell-5.1). Ensure your system is configured for this repository then execute the following in an _Administrator_ PowerShell:

```powershell
Install-Script ozo-ad-lab-create-vms
```

## Usage
```powershell
ozo-ad-lab-create-vms
    [-ClientISOPath <String>]
    [-HyperVSwitch <String>]
    [-ServerISOPath <String>]
    [-VHDXDir <String>]
```

## Parameters
|Parameter|Description|
|---------|-----------|
|`ClientISOPath`|The path to the [customized\] Client ISO. Defaults to `$Env:UserProfile\Downloads\OZO-AD-Lab-Client.iso`.|
|`HyperVSwitch`|The Hyper-V switch to use. Defaults to _OZO AD Lab NAT_.|
|`ServerISOPath`|The path to the [customized\] Server ISO. Defaults to `$Env:UserProfile\Downloads\OZO-AD-Lab-Server.iso`.|
|`VHDXDir`|The directory for the VHDX files. Defaults to `$Env:ProgramData\Microsoft\Windows\Virtual Hard Disks`.|

## Examples
### Example 1
When all customized installer ISOs are in your _Downloads_ folder and named as described in [Active Directory Lab Part II: Customize the Installer ISOs](https://onezeroone.dev/active-directory-lab-part-ii-customize-the-installer-isos/), you can run this script with no parameters:
```powershell
ozo-ad-lab-create-vms
```
### Example 2
```powershell
ozo-ad-lab-create-vms -ClientISOPath "C:\Temp\AD-Lab-Client.iso" -ServerISOPath "C:\Temp\AD-Lab-DC.iso"
```

## Notes
Run this script in an _Administrator_ PowerShell.

## Acknowledgements
Special thanks to my employer, [Sonic Healthcare USA](https://sonichealthcareusa.com), who has supported the growth of my PowerShell skillset and enabled me to contribute portions of my work product to the PowerShell community.
