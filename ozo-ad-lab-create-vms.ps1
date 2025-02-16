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
    [Parameter(Mandatory=$false,HelpMessage="Path to the Router ISO")][String]$RouterISO = "C:\ozo-ad-lab\ISO\AD-Lab-Router.iso",
    [Parameter(Mandatory=$false,HelpMessage="Path to the Server ISO")][String]$ServerISO = "C:\ozo-ad-lab\ISO\AD-Lab-Server.iso",
    [Parameter(Mandatory=$false,HelpMessage="Path for VHDX files")][String]$VHDXPath = (Join-Path -Path $Env:ProgramData -ChildPath "Microsoft\Windows\Virtual Hard Disks")
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
        # Create the virtual machine objects
        $this.ozoVMs.Add(([ADLCVMVirtualMachine]::new("AD Lab 01 router.contoso.com","Linux",1,"1GB","64GB",$this.vhdxPath,$this.routerISO,"AD Lab External","AD Lab Private")))
        # Creat an ADLCVMVirtualMachine object for the DC
        $this.ozoVMs.Add(([ADLCVMVirtualMachine]::new("AD Lab 02 dc.contoso.com","Windows",1,"2GB","128GB",$this.vhdxPath,$this.dcISO,"AD Lab Private")))
        # Creat an ADLCVMVirtualMachine object for the Server
        $this.ozoVMs.Add(([ADLCVMVirtualMachine]::new("AD Lab 03 server.contoso.com","Windows",1,"2GB","128GB",$this.vhdxPath,$this.serverISO,"AD Lab Private")))
        # Creat an ADLCVMVirtualMachine object for the Client
        $this.ozoVMs.Add(([ADLCVMVirtualMachine]::new("AD Lab 04 client.contoso.com","Windows",2,"4GB","128GB",$this.vhdxPath,$this.clientISO,"AD Lab Private")))
        # Call validate configuration and validate environment to determine if we can proceed
        If ($this.ValidateConfiguration() -eq $true -And $this.ValidateEnvironment() -eq $true) {
            # Configuration and environment validate; iterate through the VM objects
            ForEach ($VM in ($this.ozoVMs | Where-Object {$_.Create -eq $true})) {
                # Call the CreateVM method to set Created on the VM object
                $VM.Created = $VM.CreateVM()
            }
        }
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
        # Return
        return $Return
    }
    # Report method
    Hidden [Void] Report() {
        # Report created VMs
        ForEach ($VM in ($this.ozoVMs | Where-Object {$_.Created -eq $true})) {
            # Report success
            $this.ozoLogger.Write(("Created the " + $VM.vmName + " virtual machine."),"Information")
        }
        # Report skipped VMs
        ForEach ($VM in ($this.ozoVMs | Where-Object {$_.Created -eq $false})) {
            $this.ozoLogger.Write(("Skipped the " + $VM.vmName + " virtual machine. Messages:`r`n" + ($VM.Messages -Join("`r`n"))),"Warning")
        }
    }
}

Class ADLCVMVirtualMachine {
    # PROPERTIES: Arrays, Booleans, Ints, Strings
    [Array]   $osList   = @("Linux","Windows")
    [Boolean] $Create   = $true
    [Boolean] $Created  = $false
    [Int16]   $vmVCPUs  = $null
    [String]  $vhdxPath = $null
    [String]  $vmDisk   = $null
    [String]  $vmMemory = $null
    [String]  $vmName   = $null
    [String]  $vmOS     = $null
    [String]  $vmSBT    = $null
    [String]  $vmSwitch = $null
    [String]  $vmSwit2h = $null    
    # Properties: Lists
    [System.Collections.Generic.List[String]] $Messages = @()
    # METHODS
    # Constructor method (first overload)
    ADLCVMVirtualMachine($Name,$OS,$vCPUs,$Memory,$Disk,$VHDXPath,$ISO,$Network) {
        # Set properties
        $this.vmName   = $Name
        $this.vmOS     = $OS
        $this.vmVCPUs  = $vCPUs
        $this.vmMemory = $Memory
        $this.vmDisk   = $Disk
        $this.vhdxPath = (Join-Path -Path $VHDXPath -ChildPath ($this.vmName + ".vhdx"))
        $this.vmSwitch = $Network
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
    # Constructor method (second overload)
    ADLCVMVirtualMachine($Name,$OS,$vCPUs,$Memory,$Disk,$VHDXPath,$ISO,$Network,$Netwo2k) {
        # Set properties
        $this.vmSwit2h = $Netwo2k
        # Call the first overload
        $this.ADLCVMVirtualMachine($Name,$OS,$vCPUs,$Memory,$Disk,$VHDXPath,$ISO,$Network)
    }
    # Validate VM method
    Hidden [Boolean] ValidateVM() {
        # Control variable
        [Boolean] $Return = $true
        # Determine if the VM already exists
        If ((Get-VM).Name -Contains $this.vmName) {
            # VM exists; skipping
            $this.Messages.Add("VM already exists; skipping.")
            $Return = $false
        }
        If ((Test-Path -Path $this.vhdxPath) -eq $true) {
            # VM disk exists; skipping
            $this.Messages.Add("VM disk already exists; skipping.")
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
            New-VM -Name $this.vmName -Generation 2 -MemoryStartupBytes $this.vmMemory -SwtichName $this.vmSwitch -NewVHDPath $this.vhdxPath -NewVHDSizeBytes $this.vmDisk -ErrorAction Stop
            # Success; configure processor count, automagic start action, and automagic stop action; and disable checkpoints
            Set-VM -Name $this.vmName -ProcessorCount $this.vmVCPUs -AutomaticStartAction "Nothing" -AutomaticStopAction "Shutdown" -CheckpointType "Disabled"
            # Configure Memory and Memory Buffer
            Set-VMMemory -VMName $this.vmName -DynamicMemoryEnabled $true -MiniumumBytes "512MB" -MemoryMaximumBytes $this.vmMemory -Buffer 5 -ErrorAction Stop
            # Configure firmware
            Set-VMFirmware -VMName $this.vmName -EnableSecureBoot "On" -SecureBootTemplate $this.vmSBT -FirstBootDevice "DVDDrive" -ErrorAction Stop
            # Enable TPM
            Enable-VMTPM -VMName $this.vmName
            # Configure Integrations
            # Configure the DVD drive
            Set-VMDvdDrive -VMName $this.vmName -Path $this.
            Enable-VMIntegrationService -VMName $this.vmName -Name "Guest Service Interface","Heartbeat","Key-Value Pair Exchange","Shutdown","Time Synchronization","VSS" -ErrorAction Stop
            # Determine if this VM should ahve a second vSwitch
            IF ($null -ne $this.vmSwit2h) {
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
                    Remove-VM -VMName $this.vmName -ErrorAction Stop
                    # Success
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
Test-OZOHyperVAdministrator {
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
