#Requires -Modules @{ModuleName="OZO";ModuleVersion="1.5.0"},@{ModuleName="OZOLogger";ModuleVersion="1.1.0"} -RunAsAdministrator

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
    An interactive script that creates a the Hyper-V virtual machines required for the One Zero One AD Lab.
    .PARAMETER ClientISO
    The path to the customized Client ISO. Defaults to C:\ozo-ad-lab\ISO\AD-Lab-Client.iso.
    .PARAMETER DCISO
    The path to the customized DC ISO. Defaults to C:\ozo-ad-lab\ISO\AD-Lab-DC.iso.
    .PARAMETER LaofISO
    The path to the Windows 11 Lanuages & Optional Features ISO. Defaults to C:\ozo-ad-lab\ISO\Windows-11-Lanuages-and-Optional-Features.iso.
    .PARAMETER RouterISO
    The path to the customized Router ISO. Defaults to C:\ozo-ad-lab\ISO\AD-Lab-Router.iso.
    .PARAMETER ServerISO
    The path for the VHDX files. Defaults to $Env:ProgramData\Microsoft\Windows\Virtual Hard Disks.
    .EXAMPLE
    ozo-ad-lab-create-vms
    .EXAMPLE
    $isoPath = (Join-Path -Path $Env:USERPROFILE -ChildPath "Downloads")
    ozo-ad-lab-create-vms -ClientISO "$isoPath\AD-Lab-Client.iso" -DCISO "$isoPath\AD-Lab-DC.iso"
    .LINK
    https://github.com/onezeroone-dev/OZO-AD-Lab-Create-VMs/blob/main/README.md
    .NOTES
    Run this script in an Administrator PowerShell.
#> 
Param(
    [Parameter(Mandatory=$false,HelpMessage="The path to the Client ISO")][String]$ClientISO = "C:\ozo-ad-lab\ISO\AD-Lab-Client.iso",
    [Parameter(Mandatory=$false,HelpMessage="The path to the DC ISO")][String]$DCISO = "C:\ozo-ad-lab\ISO\AD-Lab-DC.iso",
    [Parameter(Mandatory=$false,HelpMessage="The path to the Lanugages & Optional Features ISO")][String]$LaofISO = "C:\ozo-ad-lab\ISO\Windows-11-Lanuages-and-Optional-Features.iso",
    [Parameter(Mandatory=$false,HelpMessage="The path to the Router ISO")][String]$RouterISO = "C:\ozo-ad-lab\ISO\AD-Lab-Router.iso",
    [Parameter(Mandatory=$false,HelpMessage="The path to the Server ISO")][String]$ServerISO = "C:\ozo-ad-lab\ISO\AD-Lab-Server.iso",
    [Parameter(Mandatory=$false,HelpMessage="The path for VHDX files")][String]$VHDXPath = (Join-Path -Path $Env:ProgramData -ChildPath "Microsoft\Windows\Virtual Hard Disks")
)

# CLASSES
Class ADLCVM {
    # PROPERTIES: Arrays, Strings
    [Array]  $hyperVSwitches = @("AD Lab External","AD Lab Private")
    [String] $clientISO      = $null
    [String] $dcISO          = $null
    [String] $laofISO        = $null
    [String] $routerISO      = $null
    [String] $serverISO      = $null
    [String] $vhdxPath       = $null
    # PROPERTIES: PSCustomObjects
    [PSCustomObject] $ozoLogger = @{}
    # PROPERTIES: Lists
    [System.Collections.Generic.List[PSCustomObject]] $ozoVMs = @()
    # METHODS
    # Constructor method
    ADLCVM($ClientISO,$DCISO,$LaofISO,$RouterISO,$ServerISO,$VHDXPath) {
        # Set properties
        $this.clientISO = $clientISO
        $this.dcISO     = $DCISO
        $this.laofISO   = $LaofISO
        $this.routerISO = $RouterISO
        $this.serverISO = $ServerISO
        $this.vhdxPath  = $VHDXPath
        $this.ozoLogger = (New-OZOLogger)
        # Announce ourselves to the world.
        $this.ozoLogger.Write("Process starting.","Information")
        $this.ozoLogger
        # Call validate configuration and validate environment to determine if we can proceed
        If (($this.ValidateConfiguration() -And $this.ValidateEnvironment()) -eq $true) {
            # Report
            $this.ozoLogger.Write("Configuration and environment validated; evaluating VMs.","Information")
            # Create the virtual machine objects
            $this.ozoVMs.Add(([ADLCVMVirtualMachine]::new("AD Lab 01 router.contoso.com","Linux",1,1073741824,68719476736,$this.vhdxPath,$this.routerISO,"AD Lab External","AD Lab Private")))
            # Creat an ADLCVMVirtualMachine object for the DC
            $this.ozoVMs.Add(([ADLCVMVirtualMachine]::new("AD Lab 02 dc.contoso.com","Windows",1,2147483648,137438953472,$this.vhdxPath,$this.dcISO,"AD Lab Private",$null)))
            # Creat an ADLCVMVirtualMachine object for the Server
            $this.ozoVMs.Add(([ADLCVMVirtualMachine]::new("AD Lab 03 server.contoso.com","Windows",1,2147483648,137438953472,$this.vhdxPath,$this.serverISO,"AD Lab Private",$null)))
            # Creat an ADLCVMVirtualMachine object for the Client
            $this.ozoVMs.Add(([ADLCVMVirtualMachine]::new("AD Lab 04 client.contoso.com","Windows",2,4294967296,137438953472,$this.vhdxPath,$this.clientISO,"AD Lab Private",$null)))
            # Configuration and environment validate; iterate through the VM objects
            ForEach ($VM in $this.ozoVMs) {
                If ($VM.Create -eq $true) {
                    # VM validated; call the CreateVM method to create the VM and set Created on the VM object
                    If ($VM.CreateVM() -eq $true) {
                        # VM was created
                        $this.ozoLogger.Write(("Creating the " + $VM.vmName + " VM."),"Information")
                    } Else {
                        # VM was not created
                        $this.ozoLogger.Write(("Error creating the " + $VM.vmName + " virtual machine for the following reasons:`r`n" + ($VM.Messages -Join("`r`n"))),"Warning")
                    }
                } Else {
                    # VM did not validate; report
                    $this.ozoLogger.Write(("Skipping the " + $VM.vmName + " virtual machine for the following reasons:`r`n" + ($VM.Messages -Join("`r`n"))),"Warning")
                }
                
            }
        } Else {
            $this.ozoLogger.Write("Configuration and/or environment did not validate.","Error")
        }
        # Bid the world adieu.
        $this.ozoLogger.Write("Process complete.","Information")
    }
    # Validate configuration method
    Hidden [Boolean] ValidateConfiguration() {
        # Control variable
        [Boolean] $Return = $true
        ForEach ($Path in $this.clientISO,$this.dcISO,$this.laofISO,$this.serverISO) {
            # Determine if the path is invalid
            If ((Test-Path -Path $Path) -eq $false) {
                # Path is invalid
                $this.ozoLogger.Write(("Cannot find " + $Path),"Error")
                $Return = $false
            }
        }
        # Return
        return $Return
    }
    # Validate environment methods
    Hidden [Boolean] ValidateEnvironment() {
        # Control variable
        [Boolean] $Return = $true
        # Test if session is user-interactive
        If ((Get-OZOUserInteractive) -eq $false) {
            # Session is not user-interactive
            $this.ozoLogger.Write("Please run this script in a user-interactive session.","Error")
            $Return = $false
        }
        # Determine if current user is an Administrator or a member of Hyper-V Administrators
        If ((Test-OZOLocalAdministrator) -eq $false -And (Test-OZOHyperVAdministrator) -eq $false) {
            # User is neither an Administrator or a Hyper-V Administrator
            $this.ozoLogger.Write("User is not an Administrator or a member of Hyper-V Administrators. Run this script in an Administrator PowerShell session or add your user to the local Hyper-V Administrators group.")
            $Return = $false
        }
        # Iterate through the Hyper-V virtual switches
        ForEach ($virtualSwitch in $this.hyperVSwitches) {
            # Determine if the switch is not present
            If ((Get-VMSwitch).Name -NotContains $virtualSwitch) {
                # Switch is not present
                $this.ozoLogger.Write(("Hyper-V virtual switch " + $virtualSwitch + " not found."),"Error")
                $Return = $false
            }
        }
        # Determine if the VHDXPath is not writable
        If ((Test-OZOPath -Writable -Path $this.vhdxPath) -eq $false) {
            # Path is not writable
            $this.ozoLogger.Write(("The VHDX path is not writable."),"Error")
            $Return = $false
        }
        # Determine if the Hyper-V Feature is not installed
        If ([Boolean](Get-WindowsOptionalFeature -Online -FeatureName "Microsoft-Hyper-V") -eq $false) {
            # Feature is not present
            $this.ozoLogger.Write(("The Hyper-V Feature is not installed. Please see https://onezeroone.dev/active-directory-lab-prerequisites."),"Error")
            $Return = $false
        }
        # Return
        return $Return
    }
}

Class ADLCVMVirtualMachine {
    # PROPERTIES: Arrays, Booleans, Ints, Strings
    [Array]   $osList   = @("Linux","Windows")
    [Boolean] $Create   = $true
    [Int16]   $vmVCPUs  = $null
    [Int64]   $vmDisk   = $null
    [Int64]   $vmMemory = $null
    [String]  $vhdxPath = $null
    [String]  $vmISO    = $null
    [String]  $vmName   = $null
    [String]  $vmOS     = $null
    [String]  $vmSBT    = $null
    [String]  $vmSwitch = $null
    [String]  $vmSwit2h = $null    
    # Properties: Lists
    [System.Collections.Generic.List[String]] $Messages = @()
    # METHODS
    # Constructor method
    ADLCVMVirtualMachine($Name,$OS,$vCPUs,$Memory,$Disk,$VHDXPath,$ISO,$Network,$Netwo2k) {
        # Set properties
        $this.vmName   = $Name
        $this.vmOS     = $OS
        $this.vmVCPUs  = $vCPUs
        $this.vmMemory = $Memory
        $this.vmDisk   = $Disk
        $this.vhdxPath = (Join-Path -Path $VHDXPath -ChildPath ($this.vmName + ".vhdx"))
        $this.vmISO    = $ISO
        $this.vmSwitch = $Network
        $this.vmSwit2h = $Netwo2k
        # Switch on OS to set vmSBT
        Switch($this.vmOS) {
            "Linux" {
                $this.vmSBT = "MicrosoftUEFICertificateAuthority"
            }
            default {
                $this.vmSBT = "MicrosoftWindows"
            }
        }
        # Call ValidateVM to set Create
        $this.Create = $this.ValidateVM()
    }
    # Validate VM method
    Hidden [Boolean] ValidateVM() {
        # Control variable
        [Boolean] $Return = $true
        # Determine if the VM already exists
        If ((Get-VM).Name -Contains $this.vmName) {
            # VM exists; skipping
            $this.Messages.Add("VM already exists.")
            $Return = $false
        }
        If ((Test-Path -Path $this.vhdxPath) -eq $true) {
            # VM disk exists; skipping
            $this.Messages.Add("VM disk already exists.")
            $Return = $false
        }
        # Determine if OS is valid
        If ($this.osList -NotContains $this.vmOS) {
            # OS is not handled
            $this.Messages.Add(("Operating system " + $this.vmOS + " is invalid."))
        }
        # Return
        return $Return
    }
    # Create VM method
    [Boolean] CreateVM() {
        # Control variables
        [Boolean] $Return = $true
        # Create the VM
        Try {
            New-VM -Name $this.vmName -Generation 2 -MemoryStartupBytes $this.vmMemory -SwitchName $this.vmSwitch -NewVHDPath $this.vhdxPath -NewVHDSizeBytes $this.vmDisk -ErrorAction Stop
            # Success; configure processor count, automagic start action, and automagic stop action; and disable checkpoints
            Set-VM -Name $this.vmName -ProcessorCount $this.vmVCPUs -AutomaticStartAction "Nothing" -AutomaticStopAction "Shutdown" -CheckpointType "Disabled"
            # Configure Memory and Memory Buffer
            Set-VMMemory -VMName $this.vmName -DynamicMemoryEnabled $true -MinimumBytes 536870912 -MaximumBytes $this.vmMemory -Buffer 5 -ErrorAction Stop
            # Configure firmware
            Set-VMFirmware -VMName $this.vmName -EnableSecureBoot "On" -SecureBootTemplate $this.vmSBT -ErrorAction Stop
            # Enable TPM and Key Protector
            Set-VMKeyProtector -VMName $this.vmName -NewLocalKeyProtector
            Enable-VMTPM -VMName $this.vmName -ErrorAction Stop
            # Configure the DVD drive
            Add-VMDvdDrive -VMName $this.vmName -Path $this.vmISO
            # Set DVD drive as first boot option
            Set-VMFirmware -VMName $this.vmName -FirstBootDevice (Get-VMDvdDrive -VMName $this.vmName)
            # Configure integrations
            Enable-VMIntegrationService -VMName $this.vmName -Name "Guest Service Interface","Heartbeat","Key-Value Pair Exchange","Shutdown","Time Synchronization","VSS" -ErrorAction Stop
            # Determine if this VM should ahve a second vSwitch
            If ([String]::IsNullOrEmpty($this.vmSwit2h) -eq $false) {
                # Add second vSwitch
                Add-VMNetworkAdapter -VMName $this.vmName -SwitchName $this.vmSwit2h -ErrorAction Stop
            }
        } Catch {
            # Failure
            $this.Messages.Add(("Error creating or configuring " + $this.vmName + " VM. Error message is " + $_ + "`r`nDeleting."))
            $Return = $false
            # Determine if the VM was created in any capacity or configuration
            If ([Boolean](Get-VM -VMName $this.vmName) -eq $true) {
                # VM was created; try to remove it
                Try {
                    Remove-VM -VMName $this.vmName -Force -ErrorAction Stop
                    # Success; determine if a VHDX was created
                    If ((Test-Path -Path $this.vhdxPath) -eq $true) {
                        # VHDX was created; remove it
                        Remove-Item -Path $this.vhdxPath -Force -ErrorAction Stop
                    }
                } Catch {
                    # Failure
                    $this.Messages.Add(("Unable to delete the " + $this.vmName + " VM. AD Lab configuration may be in an inconsistent state."))
                }
            }
        }

        # Return
        return $Return
    }
}

# FUNCTIONS
Function Test-OZOHyperVAdministrator {
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
[ADLCVM]::new($ClientISO,$DCISO,$LaofISO,$RouterISO,$ServerISO,$VHDXPath) | Out-Null
