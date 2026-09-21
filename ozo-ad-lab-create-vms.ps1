#Requires -Modules @{ModuleName="OZO";ModuleVersion="1.7.0"},OZOLogger -RunAsAdministrator

<#PSScriptInfo
    .VERSION 1.1.0
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
    Creates a the Hyper-V virtual machines required for the One Zero One AD Lab.
    .PARAMETER ClientISOPath
    The path to the customized Client ISO. Defaults to $Env:UserProfile\Downloads\AD-Lab-Client.iso.
    .PARAMETER HyperVSwitch
    The Hyper-V switch to use. Defaults to "OZO AD Lab NAT".
    .PARAMETER ServerISOPath
    The path to the customized Server ISO. Defaults to $Env:UserProfile\Downloads\AD-Lab-Server.iso.
    .PARAMETER VHDXDir
    The directory for the VHDX files. Defaults to $Env:ProgramData\Microsoft\Windows\Virtual Hard Disks.
    .EXAMPLE
    ozo-ad-lab-create-vms
    .EXAMPLE
    ozo-ad-lab-create-vms -ClientISOPath "C:\Temp\AD-Lab-Client.iso" -ServerISOPath "C:\Temp\AD-Lab-DC.iso"
    .LINK
    https://github.com/onezeroone-dev/OZO-AD-Lab-Create-VMs/blob/main/README.md
    .NOTES
    Run this script in an Administrator PowerShell.
#> 
Param(
    [Parameter(Mandatory=$false,HelpMessage="Path to the Client ISO")][String] $ClientISOPath = (Join-Path -Path $Env:UserProfile -ChildPath "Downloads\OZO-AD-Lab-Client.iso"),
    [Parameter(Mandatory=$false,HelpMessage="Hyper-V switch to use")][String] $HyperVSwitch = "OZO AD Lab NAT",
    [Parameter(Mandatory=$false,HelpMessage="Path to the Server ISO")][String] $ServerISOPath = (Join-Path -Path $Env:UserProfile -ChildPath "Downloads\OZO-AD-Lab-Server.iso"),
    [Parameter(Mandatory=$false,HelpMessage="Directory for VHDX files")][String] $VHDXDir = (Join-Path -Path $Env:ProgramData -ChildPath "Microsoft\Windows\Virtual Hard Disks")
)

# CLASSES
Class Main {
    # PROPERTIES: PSCustomObjects
    [PSCustomObject] $ozoLogger = @{}
    # PROPERTIES: PSCustomObject Lists
    [System.Collections.Generic.List[PSCustomObject]] $ozoVMs = @()
    # METHODS: Constructor method
    Main($ClientISOPath,$HyperVSwitch,$ServerISOPath,$VHDXDir) {
        # Create a logger object
        $this.ozoLogger = (New-OZOLogger)
        # Log a process start message
        $this.ozoLogger.Write("Process starting.","Information")
        # Determine if environment validate
        If ($this.ValidateEnvironment($HyperVSwitch,$VHDXDir) -eq $true) {
            # Environment validated; create the virtual machine objects
            $this.ozoVMs.Add(([OzoVM]::new("OZO AD Lab Windows AD Domain Controller","Windows",1,2147483648,137438953472,$VHDXDir,$ServerISOPath,$HyperVSwitch)))
            $this.ozoVMs.Add(([OzoVM]::new("OZO AD Lab Windows Client","Windows",2,4294967296,137438953472,$VHDXDir,$ClientISOPath,$HyperVSwitch)))
            # Iterate over the VMs
            ForEach ($ozoVM in $this.ozoVMs) {
                # Log the creation of each VM and messages
                $this.ozoLogger.Write(("Created VM " + $ozoVM.Name + " with the following messages: " + ($ozoVM.Messages -join ";")),"Information")
            }
        } Else {
            # Environment did not validate
            $this.ozoLogger.Write("Environment did not validate.","Error")
        }
        # Log a process complete message
        $this.ozoLogger.Write("Process complete.","Information")
    }
    # METHODS: Validate environment method
    Hidden [Boolean] ValidateEnvironment($HyperVSwitch,$VHDXDir) {
        # Control variable
        [Boolean] $Return = $true
        # Determine if the session is user-interactive
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
        # Determine if the Hyper-V switch is not present
        If ((Get-VMSwitch).Name -NotContains $HyperVSwitch) {
            # Switch is not present
            $this.ozoLogger.Write(("HyperVSwitch not found."),"Error")
            $Return = $false
        }
        # Determine if the VHDXPath is not writable
        If ((Test-OZOPath -Writable -Path $VHDXDir) -eq $false) {
            # Path is not writable
            $this.ozoLogger.Write(("VHDXDir is not writable."),"Error")
            $Return = $false
        }
        # Determine if the Hyper-V Feature is not installed
        If ([Boolean](Get-WindowsOptionalFeature -Online -FeatureName "Microsoft-Hyper-V" -ErrorAction SilentlyContinue) -eq $false) {
            # Feature is not present
            $this.ozoLogger.Write(("The Hyper-V Feature is not installed. Please see https://onezeroone.dev/active-directory-lab-prerequisites."),"Error")
            $Return = $false
        }
        # Return
        return $Return
    }
}

Class OzoVM {
    # PROPERTIES: Arrays, Booleans, Ints, Strings
    [Array] $osList = @("Windows")   
    # PROPERTIES: String Lists
    [System.Collections.Generic.List[String]] $Messages = @()
    # METHODS: Constructor method
    OzoVM($VMName,$OS,$vCPUs,$Memory,$Disk,$VHDXDir,$ISOPath,$Network) {
        # Determine if the VM validates
        If ($this.ValidateVM($VMName,$OS,$ISOPath) -eq $true) {
            # VM validates; create the VM
            $this.CreateVM($VMName,$OS,$vCPUs,$Memory,$Disk,$VHDXDir,$ISOPath,$Network)
        }
    }
    # Validate VM method
    Hidden [Boolean] ValidateVM($VMName,$OS,$ISOPath) {
        # Control variable
        [Boolean] $Return = $true
        # Determine if the VM already exists
        If ((Get-VM).Name -Contains $VMName) {
            # VM exists; skipping
            $this.Messages.Add("VM already exists")
            $Return = $false
        }
        # Determine if the ISO does not exist
        If ([Boolean](Test-Path -Path $ISOPath -ErrorAction SilentlyContinue) -eq $false) {
            # isoPath is not valid
            $this.ozoLogger.Write(("Cannot find " + $ISOPath),"Error")
            $Return = $false
        }
        # Determine if OS is valid
        If ($this.osList -NotContains $OS) {
            # OS is not handled
            $this.Messages.Add("OS is not a supported")
            $Return = $false
        }
        # Return
        return $Return
    }
    # Create VM method
    Hidden [Void] CreateVM($VMName,$OS,$vCPUs,$Memory,$Disk,$VHDXDir,$ISOPath,$Network) {
        # Local variables
        [String] $VHDXPath = (Join-Path -Path $VHDXDir -ChildPath ($VMName + ".vhdx"))
        [String] $VMSBT = $null
        # Switch on OS to set VMSBT
        Switch($OS) {
            "Linux" {
                $VMSBT = "MicrosoftUEFICertificateAuthority"
            }
            default {
                $VMSBT = "MicrosoftWindows"
            }
        }
        # Try to create the VM
        Try {
            New-VM -Name $VMName -Generation 2 -MemoryStartupBytes $Memory -SwitchName $Network -NewVHDPath $VHDXPath -NewVHDSizeBytes $Disk -ErrorAction Stop
            # Configure processor count, automagic start action, and automagic stop action; and disable checkpoints
            Set-VM -Name $VMName -ProcessorCount $vCPUs -AutomaticStartAction "Nothing" -AutomaticStopAction "Shutdown" -CheckpointType "Disabled" -ErrorAction Stop
            # Configure Memory and Memory Buffer
            Set-VMMemory -VMName $VMName -DynamicMemoryEnabled $true -MinimumBytes 536870912 -MaximumBytes $Memory -Buffer 5 -ErrorAction Stop
            # Configure firmware
            Set-VMFirmware -VMName $VMName -EnableSecureBoot "On" -SecureBootTemplate $VMSBT -ErrorAction Stop
            # Enable Key Protector
            Set-VMKeyProtector -VMName $VMName -NewLocalKeyProtector -ErrorAction Stop
            # Enable TPM
            Enable-VMTPM -VMName $VMName -ErrorAction Stop
            # Configure the DVD drive
            Add-VMDvdDrive -VMName $VMName -Path $ISOPath -ErrorAction Stop
            # Set DVD drive as first boot option
            Set-VMFirmware -VMName $VMName -FirstBootDevice (Get-VMDvdDrive -VMName $VMName) -ErrorAction Stop
            # Configure integrations
            Enable-VMIntegrationService -VMName $VMName -Name "Guest Service Interface","Heartbeat","Key-Value Pair Exchange","Shutdown","Time Synchronization","VSS" -ErrorAction Stop
            # Success
            $this.Messages.Add(("Success"))
        } Catch {
            # Failure
            $this.Messages.Add(("Failed to create or configure " + $VMName + " VM with error " + $_ + "; Deleting"))
            # Determine if the VM was created in any capacity or configuration
            If ([Boolean](Get-VM -VMName $VMName) -eq $true) {
                # VM was created; try to remove it
                Try {
                    Remove-VM -VMName $VMName -Force -ErrorAction Stop
                    # Success; determine if a VHDX was created
                    If ([Boolean](Test-Path -Path $VHDXPath -ErrorAction SilentlyContinue) -eq $true) {
                        # VHDX was created; remove it
                        Remove-Item -Path $VHDXPath -Force -ErrorAction Stop
                    }
                } Catch {
                    # Failure
                    $this.Messages.Add(("Unable to delete the " + $VMName + " VM; Lab VM deployment may be in an inconsistent state."))
                }
            }
        }
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
[Main]::new($ClientISOPath,$HyperVSwitch,$ServerISOPath,$VHDXDir) | Out-Null
