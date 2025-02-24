# OZO AD Lab Create VMs

## Description
This script automates [part](https://onezeroone.dev/active-directory-lab-part-iii-create-the-virtual-machines/) of a One Zero One [series](https://onezeroone.dev/active-directory-lab-part-i-introduction/) that illustrates how to automate the process of deploying an AD Lab.

It is an interactive script that creates the required Hyper-V virtual machines. If a virtual machine already exists, it is skipped. This is useful if e.g., you would like to keep the Linux router VM but delete and replace all the Windows VMs.

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
    -ClientISO <String>
    -DCISO     <String>
    -RouterISO <String>
    -ServerISO <String>
    -VHDXPath  <String>
```

## Parameters
|Parameter|Description|
|---------|-----------|
|`ClientISO`|The path to the [customized\] Client ISO. Defaults to `$Env:UserProfile\Downloads\AD-Lab-Client.iso`.|
|`DCISO`|The path to the [customized\] DC ISO. Defaults to `$Env:UserProfile\Downloads\AD-Lab-DC.iso`.|
|`RouterISO`|The path to the [customized\] Router ISO. Defaults to `$Env:UserProfile\Downloads\AD-Lab-Router.iso`.|
|`ServerISO`|The path to the [customized\] Server ISO. Defaults to `$Env:UserProfile\Downloads\AD-Lab-Server.iso`.|
|`VHDXPath`|The path for the VHDX files. Defaults to `$Env:ProgramData\Microsoft\Windows\Virtual Hard Disks`.|

## Examples
### Example 1
When all customized OZO-AD-Lab-* ISOs are in your _Downloads_ folder and named as described in [Active Directory Lab Part II: Customize the Installer ISOs](https://onezeroone.dev/active-directory-lab-part-ii-customize-the-installer-isos/), you can run this script with no parameters:
```powershell
ozo-ad-lab-create-vms
```
### Example 2
If your customized installer ISOs are located elsewhere, you can specify their locations using the relevant parameters, e.g,. if the Client and DC ISOs are in `C:\Temp`:
```powershell
$isoPath = (Join-Path -Path $Env:SystemDrive -ChildPath "Temp")
ozo-ad-lab-create-vms -ClientISO "$isoPath\AD-Lab-Client.iso" -DCISO "$isoPath\AD-Lab-DC.iso"
```

## Notes
Run this script in an _Administrator_ PowerShell.

## Acknowledgements
Special thanks to my employer, [Sonic Healthcare USA](https://sonichealthcareusa.com), who has supported the growth of my PowerShell skillset and enabled me to contribute portions of my work product to the PowerShell community.
