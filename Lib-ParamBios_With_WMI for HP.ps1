###############################################################################
# Nom : Lib-ParamBios.ps1
# Auteur : Sylvain AICARDO
# Date Création Initial : 10/06/2014
# Version : V3.5
# Dernière Modification : 24/08/2016
###############################################################################
$LibPath = (Split-Path $MyInvocation.MyCommand.path)
###############################################################################
# constructor determination
function Get-Manufacturer 
{
	<#
		.SYNOPSIS
		    constructor determination.
		.DESCRIPTION
		    constructor determination.
		.EXAMPLE
		    Get-Manufacturer -computername <computername>
		.EXAMPLE
		    Get-Manufacturer -computername <computername> -cred <Credential var>
		.LINK
		    Based on script https://github.com/PowerShellSith (Twitter: @PowerShellSith)
		.CONNEX LINK

	#>
	Param 	(
			# ComputerName, Type string, System to Get Bios option.
        	[Parameter(Position=0,
                   ValueFromPipeline=$true)]
        	[ValidateScript({ if (-not(Test-Connection -ComputerName $_ -Quiet -Count 2)) { throw "Failed to connect to $ComputerName. Please ensure the system is available." } else { $true} })]
        	[string[]]
        	$ComputerName = $env:COMPUTERNAME
			,
			# Cred, Type Credential, The credential of the command.
	    	[Parameter(Position=3)]
			$cred = $null
			)
	#credentials management
	if ($cred -eq $null)
	{
		$CredentialParams = @{}
	}
	Elseif (($cred -ne $null) -and (($Computername -eq $env:COMPUTERNAME) -or ($computername -eq "localhost") -or ($computername -eq ".")))
	{
		$CredentialParams = @{}
	}
	Else
	{
		$CredentialParams = @{credential = $cred}
	}
	#Constructor determination
	Try {
		#Write-Host "constructor determination"
	    [string]$Constructeur = ((Get-WmiObject -Class Win32_ComputerSystem -Namespace "root\CIMV2" -ComputerName $ComputerName -ErrorAction Stop @CredentialParams).manufacturer).Trim()
	    if ($Constructeur -eq "HP") {$Constructeur = "Hewlett-Packard"}
		#For debug : Write-debug "Manufacturer : $Constructeur"
		#For test : $Constructeur = "Sony"
		return $Constructeur
	} Catch {
		Write-Host "WMI Determination Manufacturer request was unsuccessful" -foregroundColor Red
		return "ERROR : WMI Determination Manufacturer request was unsuccessful"
	}
}
###############################################################################
# command execute
Function ExecuteCmd([STRING]$FileName, [STRING]$Arguments)
{
	<#
		.SYNOPSIS
		    command execute.
		.DESCRIPTION
		    command execute.
		.EXAMPLE
		    ExecuteCmd -FileName <FileName>
		.EXAMPLE
		    ExecuteCmd -FileName <FileName> -Arguments <Arguments>
		.LINK
		    Based on script of 
		.CONNEX LINK

	#>
	Try
	{	$pinfo = New-Object System.Diagnostics.ProcessStartInfo
		$pinfo.FileName = $FileName
		$pinfo.Arguments = $Arguments

		$pinfo.RedirectStandardError = $true
		$pinfo.RedirectStandardOutput = $true

		$pinfo.UseShellExecute = $false

		$p = New-Object System.Diagnostics.Process
		$p.StartInfo = $pinfo
		$p.Start() | Out-Null
		$p.WaitForExit()

		$stdout = $p.StandardOutput.ReadToEnd()
		$stderr = $p.StandardError.ReadToEnd()

		$lResult= @{}
		$lResult.Add('Command', $FileName)
		$lResult.Add('Args', $Arguments)
		$lResult.Add('stdout', $stdout)
		$lResult.Add('stderr', $stderr)
		$lResult.Add('ExitCode', $p.ExitCode)

		return ($lResult)
	}

	Catch
		{Return ($null)}
}
###############################################################################
# UTF16 to KBD string conversion
function ConvertTo-KBDString
{
    <#
		.SYNOPSIS
		    Converts string to KBD encoded string.
		.DESCRIPTION
		    Converts UTF16 string to Keyboard Scan Hex Value (KBD).  Older HP BIOS's only accept this encoding method for setup passwords, useful for WMI BIOS Administration.
		.EXAMPLE
		    ConvertTo-KBDString -UnicodeString "MyStringToConvert"
		.LINK
		    http://www.codeproject.com/Articles/7305/Keyboard-Events-Simulation-using-keybd_event-funct
		    http://msdn.microsoft.com/en-us/library/aa299374%28v = vs.60%29.aspx
		    http://h20331.www2.hp.com/HPsub/downloads/cmi_whitepaper.pdf  Page: 14
		    Based on script https://github.com/PowerShellSith (Twitter: @PowerShellSith)
		.CONNEX LINK
			function Set-HPSetupPassword
			function Set-HPBiosOption
	#>
	
	[CmdletBinding()]
    [OutputType([string])]
    Param
    (
        # Input, Type string, String to be encoded with EN Keyboard Scan Code Hex Values.
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true)]
        [Alias("UniStr")]
        [AllowEmptyString()]
        [string]
        $UnicodeString
    )

    $kbdHexVals = New-Object System.Collections.Hashtable

    $kbdHexVals."a" = "1E"
    $kbdHexVals."b" = "30"
    $kbdHexVals."c" = "2E"
    $kbdHexVals."d" = "20"
    $kbdHexVals."e" = "12"
    $kbdHexVals."f" = "21"
    $kbdHexVals."g" = "22"
    $kbdHexVals."h" = "23"
    $kbdHexVals."i" = "17"
    $kbdHexVals."j" = "24"
    $kbdHexVals."k" = "25"
    $kbdHexVals."l" = "26"
    $kbdHexVals."m" = "32"
    $kbdHexVals."n" = "31"
    $kbdHexVals."o" = "18"
    $kbdHexVals."p" = "19"
    $kbdHexVals."q" = "10"
    $kbdHexVals."r" = "13"
    $kbdHexVals."s" = "1F"
    $kbdHexVals."t" = "14"
    $kbdHexVals."u" = "16"
    $kbdHexVals."v" = "2F"
    $kbdHexVals."w" = "11"
    $kbdHexVals."x" = "2D"
    $kbdHexVals."y" = "15"
    $kbdHexVals."z" = "2C"
    $kbdHexVals."A" = "9E"
    $kbdHexVals."B" = "B0"
    $kbdHexVals."C" = "AE"
    $kbdHexVals."D" = "A0"
    $kbdHexVals."E" = "92"
    $kbdHexVals."F" = "A1"
    $kbdHexVals."G" = "A2"
    $kbdHexVals."H" = "A3"
    $kbdHexVals."I" = "97"
    $kbdHexVals."J" = "A4"
    $kbdHexVals."K" = "A5"
    $kbdHexVals."L" = "A6"
    $kbdHexVals."M" = "B2"
    $kbdHexVals."N" = "B1"
    $kbdHexVals."O" = "98"
    $kbdHexVals."P" = "99"
    $kbdHexVals."Q" = "90"
    $kbdHexVals."R" = "93"
    $kbdHexVals."S" = "9F"
    $kbdHexVals."T" = "94"
    $kbdHexVals."U" = "96"
    $kbdHexVals."V" = "AF"
    $kbdHexVals."W" = "91"
    $kbdHexVals."X" = "AD"
    $kbdHexVals."Y" = "95"
    $kbdHexVals."Z" = "AC"
    $kbdHexVals."1" = "02"
    $kbdHexVals."2" = "03"
    $kbdHexVals."3" = "04"
    $kbdHexVals."4" = "05"
    $kbdHexVals."5" = "06"
    $kbdHexVals."6" = "07"
    $kbdHexVals."7" = "08"
    $kbdHexVals."8" = "09"
    $kbdHexVals."9" = "0A"
    $kbdHexVals."0" = "0B"
    $kbdHexVals."!" = "82"
    $kbdHexVals."@" = "83"
    $kbdHexVals."#" = "84"
    $kbdHexVals."$" = "85"
    $kbdHexVals."%" = "86"
    $kbdHexVals."^" = "87"
    $kbdHexVals."&" = "88"
    $kbdHexVals."*" = "89"
    $kbdHexVals."(" = "8A"
    $kbdHexVals.")" = "8B"
    $kbdHexVals."-" = "0C"
    $kbdHexVals."_" = "8C"
    $kbdHexVals."=" = "0D"
    $kbdHexVals."+" = "8D"
    $kbdHexVals."[" = "1A"
    $kbdHexVals."{" = "9A"
    $kbdHexVals."]" = "1B"
    $kbdHexVals."}" = "9B"
    $kbdHexVals.";" = "27"
    $kbdHexVals.":" = "A7"
    $kbdHexVals."'" = "28"
    $kbdHexVals."`"" = "A8"
    $kbdHexVals."``" = "29"
    $kbdHexVals."~" = "A9"
    $kbdHexVals."\" = "2B"
    $kbdHexVals."|" = "AB"
    $kbdHexVals."," = "33"
    $kbdHexVals."<" = "B3"
    $kbdHexVals."." = "34"
    $kbdHexVals.">" = "B4"
    $kbdHexVals."/" = "35"
    $kbdHexVals."?" = "B5"

    $kbdEncodedString = ""
    foreach ($char in $UnicodeString.ToCharArray())
    {
        $kbdEncodedString += $kbdHexVals.Get_Item($char.ToString())
    }
    return $kbdEncodedString
}
###############################################################################
# Dell Bios parameter Writing results function
function Out-CCTKErrorCodes
{
    <#
		.SYNOPSIS
		    Converts the CCTK return values to user friendly text.
		.DESCRIPTION
		    Converts the CCTK return values to user firendly verbose output.
		.EXAMPLE
		    Out-CCTKErrorCodes -CCTKReturnValue 0
		.EXAMPLE
		    Out-CCTKErrorCodes -CCTKReturnValue (Set-BiosOption -option "" -Optionvalue "" -Manufacturer "Hewlett-Packard")
		.LINK
		    Based on script https://github.com/PowerShellSith (Twitter: @PowerShellSith)
		.CONNEX LINK

	#>
	
	[CmdletBinding()]
    [OutputType([string])]
    Param
    (
        # CCTKReturnValue, Type int, The Return Property Value to be converted to verbose output.
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true)]
        [Alias("RetVal")]
        [int]
        $CCTKReturnValue
    )

    switch ($CCTKReturnValue)
    {
        0 { [string]$Res= "Success";break }
        1 { [string]$Res= "Attempt to read write-only parameter '%s'";break  }
        2 { [string]$Res= "Password cannot exceed 16 characters";break }
        3 { [string]$Res= "A BMC was either not detected or is not supported";break }
        4 { [string]$Res= "This username is already in use. Enter a unique username";break }
        5 { [string]$Res= "Access mode not supported";break }
        6 { [string]$Res= "Cannot return number of requested data bytes";break }
		7 { [string]$Res= "User ID 1 cannot be assigned a username";break }
		10 { [string]$Res= "Clear SEL cannot be accompanied with any other option";break }
		11 { [string]$Res= "racreset cannot be accompanied with any other option";break }
		12 { [string]$Res= "Cannot execute command '%s'. Command, or request parameter(s), not supported in present state";break }
		
		13 { [string]$Res= "Failed to change setting";break }
		14 { [string]$Res= "BCU not ready to write file";break }
		15 { [string]$Res= "Command line syntax error";break }
		16 { [string]$Res= "Unable to write to file or system";break }
		17 { [string]$Res= "Help is invoked";break }
		18 { [string]$Res= "Setting is unchanged";break }
		19 { [string]$Res= "Setting is read-only";break }
		20 { [string]$Res= "Invalid setting name";break }
		20 { [string]$Res= "Invalid setting name";break }
		21 { [string]$Res= "Invalid setting value";break }
		23 { [string]$Res= "Unable to connect to HP BIOS WMI namespace";break }
		24 { [string]$Res= "Unable to connect to HP WMI namespace";break }
		25 { [string]$Res= "Unable to connect to PUBLIC WMI namespace";break }
		30 { [string]$Res= "Password file error";break }
		31 { [string]$Res= "Password is not F10 compatible";break }
		32 { [string]$Res= "Platform does not support Unicode passwords";break }
		33 { [string]$Res= "No settings to apply found in Config file";break }
		default { [string]$Res= "Unknown error"}
    }
	return $res
}
###############################################################################
# HP Bios parameter Writing results function
function Out-VerboseReturnValues
{
    <#
		.SYNOPSIS
		    Converts the return values to user friendly text.
		.DESCRIPTION
		    Converts the return values from the .SetBIOSSetting() WMI Method to user firendly verbose output.
		.EXAMPLE
		    Out-VerboseReturnValues -WmiMethodReturnValue 0
		.EXAMPLE
		    Out-VerboseReturnValues -WmiMethodReturnValue ((Get-WmiObject -Class HPBIOS_BIOSSettingInterface -Namespace "root\HP\InstrumentedBIOS").SetBIOSSetting("Setup Password"," ","MyPassword"))
		.LINK
		    http://h20331.www2.hp.com/HPsub/downloads/cmi_whitepaper.pdf  Page: 14
		    Based on script https://github.com/PowerShellSith (Twitter: @PowerShellSith)
		.CONNEX LINK

	#>
	
	[CmdletBinding()]
    [OutputType([string])]
    Param
    (
        # WmiMethodReturnValue, Type int, The Return Property Value to be converted to verbose output.
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true)]
        [Alias("RetVal")]
        [int]
        $WmiMethodReturnValue
    )

    switch ($WmiMethodReturnValue)
    {
        0 { [string]$Res= "Success";break }
        1 { [string]$Res= "Not Supported";break  }
        2 { [string]$Res= "Unspecified Error";break }
        3 { [string]$Res= "Timeout";break }
        4 { [string]$Res= "Failed";break }
        5 { [string]$Res= "Invalid Parameter";break }
        6 { [string]$Res= "Access Denied";break }
        default { [string]$Res= "Unknown error"}
    }
	return $res
}
###############################################################################
# Get if option on Bios exist
function Get-BiosOptionExist
{
	<#
		.SYNOPSIS
	    	Get if option on Bios exist.
		.DESCRIPTION
			This function can be used to get if option on the Bios exist.
		.EXAMPLE
			Get-BiosOptionExist -Option "USB Wake Support"
		.EXAMPLE
			Get-BiosOptionExist -computerName "computername.domain.fr" -Option "USB Wake Support" -Manufacturer "Dell inc." -cred (get-credential)
		.EXAMPLE
			Get-BiosOptionExist -Option "USB Wake Support" -Manufacturer "Dell inc."
		.LINK
		
		.CONNEX LINK
			
	#>
	
	[CmdletBinding()]
	Param 	(
			# ComputerName, Type string, System to Get Bios option.
        	[Parameter(Position=0,
                   ValueFromPipeline=$true)]
        	[ValidateScript({ if (-not(Test-Connection -ComputerName $_ -Quiet -Count 2)) { throw "Failed to connect to $ComputerName. Please ensure the system is available." } else { $true} })]
        	[string[]]
        	$ComputerName = $env:COMPUTERNAME
			,
			# Option, Bios option to check.
        	[Parameter(Mandatory=$true,
                   Position=1)]
			$option
			,
			# Manufacturer, Type String, constructor.
	    	[Parameter(Position=2)]
			$Manufacturer = $null
			,
		 	# Cred, Type Credential, The credential of the command.
	    	[Parameter(Position=3)]
			$cred = $null
			)
	#credentials management
	if ($cred -eq $null)
	{
		$CredentialParams = @{}
	}
	Elseif (($cred -ne $null) -and (($Computername -eq $env:COMPUTERNAME) -or ($computername -eq "localhost") -or ($computername -eq ".")))
	{
		$CredentialParams = @{}
	}
	Else
	{
		$CredentialParams = @{credential = $cred}
	}
	#constructor searching
	if ($Manufacturer -eq $Null) {
		$Manufacturer = Get-Manufacturer
		if ($Manufacturer -match "ERROR :") {return $Manufacturer}
	}
	switch ($Manufacturer) {
		"Hewlett-Packard" {
            try {
				$option_value = Get-WmiObject -Computername $ComputerName -Class HP_BiosSetting -Namespace "root\HP\InstrumentedBIOS" @CredentialParams | Where-Object {($_.Name -eq "$option")}
				if ($option_value -eq $null) {
					return $false
				} Else {
					return $true
				}
			} catch {
				return "ERROR : Unable to connect to WMI namespace HP_BiosSetting, CurrentValue from Name $option, verify that the system is available and that you have permissions to access the namespace."
			}
			Break
		}
		"Dell Inc." {
			try {
				$Getexist = ExecuteCmd -FileName "$LibPath\CCTK\cctk.exe" -Arguments "--$($option)"
				if ($Getexist.stdout) {
					return $true
				} Else {
					return $false
				}
			} catch {
				return "ERROR : $($_.exception.Message)"
			}
			Break
		}
		"LENOVO" {
			try {
				$opt = (Get-WmiObject -Computername $ComputerName -Class Lenovo_BiosSetting -Namespace root\wmi @CredentialParams | Where-Object {((($_.CurrentSetting).split(','))[0] -eq "$option")})
                if ($Opt -eq $null) {
					return $false
				} Else {
					return $true
				}
			} catch {
				return "ERROR : Unable to connect to the Lenovo_BiosSetting WMI namespace, CurrentSetting $option, verify that the system is available and that you have permissions to access the namespace."
			}
			Break
		}
		Default {
			return "INFO : Brand not covered by this script"
		}
	}
}
###############################################################################
# Get one option value on Bios for HP,Dell et Lenovo computer
function Get-BiosOption
{
	<#
		.SYNOPSIS
	    	Get one option value on Bios.
		.DESCRIPTION
			This function can be used to get one option value on the Bios.
		.EXAMPLE
			Get-BiosOption -Option "USB Wake Support"
		.EXAMPLE
			Get-BiosOption -computerName "computername.domain.fr" -Option "USB Wake Support" -Manufacturer "Dell Inc." -cred (get-credential)
		.EXAMPLE
			Get-BiosOption -Option "USB Wake Support" -Manufacturer "Dell inc."
		.LINK
		
		.CONNEX LINK
			
	#>
	
	[CmdletBinding()]
	[OutputType([string])]
	Param 	(
			# ComputerName, Type string, System to Get Bios option.
        	[Parameter(Position=0,
                   ValueFromPipeline=$true)]
        	[ValidateScript({ if (-not(Test-Connection -ComputerName $_ -Quiet -Count 2)) { throw "Failed to connect to $ComputerName. Please ensure the system is available." } else { $true} })]
        	[string[]]
        	$ComputerName = $env:COMPUTERNAME
			,
			# Option, L'option à interroger.
        	[Parameter(Mandatory=$true,
                   Position=1)]
			$option
			,
			# Manufacturer, Type String, Constructor.
	    	[Parameter(Position=2)]
			$Manufacturer = $null
			,
		 	# Cred, Type Credential, The credential of the command.
	    	[Parameter(Position=3)]
			$cred = $null
			)
	#credentials management
	if ($cred -eq $null)
	{
		$CredentialParams = @{}
	}
	Elseif (($cred -ne $null) -and (($Computername -eq $env:COMPUTERNAME) -or ($computername -eq "localhost") -or ($computername -eq ".")))
	{
		$CredentialParams = @{}
	}
	Else
	{
		$CredentialParams = @{credential = $cred}
	}
	#Constructor searching
	if ($Manufacturer -eq $Null) {
		$Manufacturer = Get-Manufacturer
		if ($Manufacturer -match "ERROR :") {return $Manufacturer}
	}
	switch ($Manufacturer) {
		"Hewlett-Packard" {
			try {
				$option_value = (Get-WmiObject -Computername $ComputerName -Class HP_BiosSetting -Namespace "root\HP\InstrumentedBIOS" @CredentialParams | Where-Object {($_.Name -eq "$option")}).Currentvalue
				if ($option_value -eq $null) {
					return "ERROR : Option $option Not defined or not existing"
				} Else {
					return $option_value
				}
			} catch {
				return "ERROR : Unable to connect to WMI namespace HP_BiosSetting, CurrentValue from Name $option, verify that the system is available and you have permissions to access the namespace."
			}
			Break
		}
		"Dell Inc." {
			try 
			{
				$GetOpt = ExecuteCmd -FileName "$LibPath\CCTK\cctk.exe" -Arguments "--$($option)"
				if ($GetOpt.stdout)
				{
					$Resopt = (($GetOpt.stdout.trim()).split('='))[1]
					return $Resopt
				}
				Else
				{
					return "ERROR : $($Resopt)"
				}
			} 
			catch 
			{
				return "ERROR : $($_.exception.Message)"
			}
			Break
		}
		"LENOVO" {
			try {
				$opt = (Get-WmiObject -Computername $ComputerName -Class Lenovo_BiosSetting -Namespace root\wmi @CredentialParams | Where-Object {((($_.CurrentSetting).split(','))[0] -eq "$option")}).CurrentSetting
				$Option_value = ($opt.split(','))[1]
				if ($Option_value -eq $null) {
					return "ERROR : Lenovo option $option Not defined or not existing"
				} Else {
					return $Option_value
				}
			} catch {
				return "ERROR : Unable to connect to the Lenovo_BiosSetting WMI namespace, CurrentSetting $option, verify that the system is available and that you have permissions to access the namespace."
			}
			Break
		}
		Default {
			return "INFO : Brand not processed by this script"
		}
	}
}
###############################################################################
# sets one option Bios on HP, Dell or Lenovo computers
function Set-BiosOption
{
	<#
		.SYNOPSIS
	    	Sets option on Bios.
		.DESCRIPTION
			This function can be used to set one option on the Bios.
		.EXAMPLE
			Set-BiosOption -Option "USB Wake Support" -OptionValue "2"
		.EXAMPLE
			Set-BiosOption -computername "computername.domain.fr" -Option "USB Wake Support" -OptionValue "2" -cred (get-credential)
		.EXAMPLE
			Set-BiosOption -Option "USB Wake Support" -OptionValue "2" -Manufacturer "Dell inc." -CurrentPassword "MyCurrentPassword"
		.LINK
		    Based on the code https://github.com/PowerShellSith (Twitter: @PowerShellSith)	
		.CONNEX LINK
			function Out-VerboseReturnValues
			function ConvertTo-KBDString
	#>
	
	[CmdletBinding()]
	[OutputType([string])]
	Param 	(
			# ComputerName, Type string, System to Get Bios option.
        	[Parameter(Position=0,
                   ValueFromPipeline=$true)]
        	[ValidateScript({ if (-not(Test-Connection -ComputerName $_ -Quiet -Count 2)) { throw "Failed to connect to $ComputerName.  Please ensure the system is available." } else { $true} })]
        	[string[]]
        	$ComputerName = $env:COMPUTERNAME
			,
			# Option, option to change.
        	[Parameter(Mandatory=$true,
                   Position=1)]
			$option
			,
			# OptionValue, option new value.
        	[Parameter(Mandatory=$true,
                   Position=2)]
			$OptionValue
			,
			# Manufacturer, Type String, Constructor.
	    	[Parameter(Position=3)]
			$Manufacturer = $null
			,
		 	# CurrentPassword, Type string, current password of the Setup Password.
        	[Parameter(Position=4)]
        	[string]
        	$CurrentPassword = $null
			,
		 	# Cred, Type Credential, The credential of the command.
        	[Parameter(Position=5)]
        	$cred = $null
			)
	#credentials management
	if ($cred -eq $null)
	{
		$CredentialParams = @{}
	}
	Elseif (($cred -ne $null) -and (($Computername -eq $env:COMPUTERNAME) -or ($computername -eq "localhost") -or ($computername -eq ".")))
	{
		$CredentialParams = @{}
	}
	Else
	{
		$CredentialParams = @{credential = $cred}
	}
	#Constructor searching
	if ($Manufacturer -eq $Null) {
		$Manufacturer = Get-Manufacturer
		if ($Manufacturer -match "ERROR :") {return $Manufacturer}
	}
	switch ($Manufacturer) {
		"Hewlett-Packard" {
			try {
				$hpBios = Get-WmiObject -Class HP_BiosSetting -Namespace "root\HP\InstrumentedBIOS" -ComputerName $ComputerName @CredentialParams
		    	$hpBiosSettings = Get-WmiObject -Class HPBIOS_BIOSSettingInterface -Namespace "root\HP\InstrumentedBIOS" -ComputerName $ComputerName @CredentialParams
		    } Catch {
				return  "ERROR : Failed to connect to the HP WMI namespace, Check if the system is available and if you have permission to access the namespace."
			}
			switch (($hpBios | where-object { $_.Name -eq "Setup Password" }).SupportedEncoding) {
		        "kbd" { 
		            $CurrentSetupPassword = "<kbd/>"+(ConvertTo-KBDString -UnicodeString $CurrentPassword) 
		        	break
				}
		        "utf-16" { 
		            $CurrentSetupPassword = "<utf-16/>"+$CurrentPassword 
		        	break
				}
		        default { 
					return "ERROR : Unknown encoding on current Setup Password"
				}
		    }
			# Verifie si l'option est supporté sur le system
			try {
				$Check_option = Get-WmiObject -Computername $ComputerName -Class HP_BiosSetting -Filter "Name like `'$option`'" -Namespace "root\HP\InstrumentedBIOS" @CredentialParams
			} catch {
		    	return "ERROR : Failed to connect to the HP WMI namespace, Check if the system is available and if you have permission to access the namespace."
			}
			if ($Check_option) {
				try {
					$Resultat = Out-VerboseReturnValues -WmiMethodReturnValue ($hpBiosSettings.SetBIOSSetting($Option,$OptionValue,$CurrentSetupPassword)).Return
				} Catch {
					return "ERROR : Echec de connexion sur l'espace de nom WMI HP lors du résultat, Vérifier si le system est disponible et si vous avez l'authorisation d'accéder à l'espace de nom."
				}
				if ($Resultat -ne $null) {
					return $resultat
				} Else {
					return "ERROR : Valeur inconnue retourné, lors du changement de l'option $option"
				}
			} Else {
				return "ERROR : The option $option is not supported on the system"
			}
			Break
		}
		"Dell Inc." 
		{
			try 
			{
				$Checkoption = Get-BiosOptionExist -option $option -Manufacturer "Dell Inc."
				if ($Checkoption -eq $true)
				{
					$OptVal = Get-BiosOption  -option $option -Manufacturer "Dell Inc."
					if ($OptVal -ne $optionvalue)
					{
						if ($CurrentPassword)
						{
							$SetOpt = ExecuteCmd -FileName "$LibPath\CCTK\cctk.exe" -Arguments "--$($option)=$($OptionValue) --valsetuppwd=$($CurrentPassword)"
						}
						Else
						{
							$SetOpt = ExecuteCmd -FileName "$LibPath\CCTK\cctk.exe" -Arguments "--$($option)=$($OptionValue)"
						}
						$OptVal = Get-BiosOption  -option $option -Manufacturer "Dell Inc."
						if ($OptVal -eq $optionvalue)
						{
							return "SUCCESS"
						}
						Else
						{
							return "ERROR : $($SetOpt.stdout.trim())"
						}
					}
					Else
					{
						return "Option déjà à la bonne valeur"
					}
				}
				Elseif ($Checkoption -eq $false)
				{
					return "ERROR : L'option ""$($option)"" n'existe pas"
				}
				Else
				{
					return $Checkoption
				}
			} 
			catch 
			{
				return "ERROR : $($_.exception.Message)"
			}
			Break
		}
		"LENOVO" {
			$encodage = "ascii"
			$kbdLang = "fr"
            
            # Création du paramètre WMI à passer
			$StrRequestSet = "$option,$optionValue"
            $StrRequestSave = ""
			If (($CurrentPassword -ne $NULL) -and ($CurrentPassword -ne "")) { 
                $CurrentPassword += ",$encodage,$kbdLang"
                $StrRequestSet = $StrRequestSet + ",$CurrentPassword"
                $StrRequestSave = "$CurrentPassword"
            }
			$StrRequestSet = $StrRequestSet + ";"
			$StrRequestSave = $StrRequestSave + ";"
            
			# Check if option is supported on the System
			try {
				$Check_option = Get-WmiObject -Computername $ComputerName -Class Lenovo_BiosSetting -Filter "CurrentSetting like `'$option%`'" -Namespace root\wmi @CredentialParams
			} catch {
		    	return "ERROR : Failed to connect to the Lenovo WMI namespace, Check if the system is available and if you have permission to access the namespace."
			}
			if ($Check_option) {
				try {
					[string]$Resultat = ((gwmi -Computername $ComputerName -class Lenovo_SetBiosSetting -namespace root\wmi @CredentialParams).SetBiosSetting($StrRequestSet)).Return
				} Catch {
					return "ERROR : Failed to connect to the Lenovo WMI namespace with the result, Check if the system is available and if you have permission to access the namespace."
				}
				switch($Resultat) {
					'Success' {
						try {
							(gwmi -Computername $ComputerName -class Lenovo_SaveBiosSettings -namespace root\wmi @CredentialParams).SaveBiosSettings($StrRequestSave) | out-null
							return "Success"
							break
						} catch {
							return "ERROR : Echec de l'enregistrement, le changement de l'option $option à échoué."
						}
					}
					'Not Supported' {
						return "ERROR : The feature is not supported on this system."
						break
					}
					'Access Denied' {
						return "ERROR : The change cannot be made due to an authentication problem. If a supervisor password exists, you must provide the correct one."
						break
					}
					'System Busy' {
						return "ERROR : BIOS changes have been made system pending. Restart the system and try again"
						break
					}
					'Invalid Parameter' {
						return "ERROR : The object or value entered is not valid"
						break
					}
					Default {
						return "ERROR : Unable to determine the error"
					}
				}	
			} Else {
				return "ERROR : The option $option is not supported on the system"
			}
			Break
		}
		Default {
			return "INFO : Marque non géré par ce script"
		}
	}
}
###############################################################################
# Fonction d'etat  du mot de passe Bios sur les ordinateurs HP,Dell et Lenovo
function Get-SetupPasswordIsSet
{
    <#
		.SYNOPSIS
		    Gets the current state of the setup password.  It is not possible to return the current setup password value.
		.DESCRIPTION
		    This function will determine if the password is set on the system, automation of BIOS Settings cannot be used until the password is set.
		.EXAMPLE
		    Get-SetupPasswordIsSet
		.EXAMPLE
		    Get-SetupPasswordIsSet -ComputerName "computername.domain.fr" -Manufacturer "Dell inc." -cred (get-credential)
		.LINK
		    based on https://github.com/PowerShellSith (Twitter: @PowerShellSith)
		.CONNEX LINK
		
	#>
	
	[CmdletBinding()]
    Param
    (
        # ComputerName, Type string, System to evaluate Setup Password state against.
        [Parameter(Position=0,
					ValueFromPipeline=$true)]
        [ValidateScript({ if (-not(Test-Connection -ComputerName $_ -Quiet -Count 2)) { throw "Failed to connect to $ComputerName.  Please ensure the system is available." } else { $true } })]
        [string[]]
        $ComputerName = $env:COMPUTERNAME
		,
		# Manufacturer, Type String, Constructor.
	    	[Parameter(Position=1)]
			$Manufacturer = $null
		,
		# $Passw, Type String, Current password
	    	[Parameter(Position=2)]
			$Passw = $null
		,
	 	# Cred, Type Credential, The credential of the command.
    	[Parameter(Position=3)]
		$cred = $null
    )
	#credentials management
    if ($cred -eq $null)
	{
		$CredentialParams = @{}
	}
	Elseif (($cred -ne $null) -and (($Computername -eq $env:COMPUTERNAME) -or ($computername -eq "localhost") -or ($computername -eq ".")))
	{
		$CredentialParams = @{}
	}
	Else
	{
		$CredentialParams = @{credential = $cred}
	}
	#Constructor searching
	if ($Manufacturer -eq $Null) {
		$Manufacturer = Get-Manufacturer
		if ($Manufacturer -match "ERROR :") {return $Manufacturer}
	}
	switch ($Manufacturer) {
		"Hewlett-Packard" {
			try {
				$hpBios = (Get-WmiObject -Class HP_BiosSetting -Namespace "root\HP\InstrumentedBIOS" -ComputerName $ComputerName @CredentialParams | where-object { $_.Name -eq 'Setup Password' }).IsSet
		    } catch {
				return "ERROR : Echec de connexion sur l'espace de nom WMI HP, Vérifier si le système est disponible et si vous avez l'authorisation d'accéder à l'espace de noms."
			}
			if ($hpBios -eq 0) {
		        return $false
		    } elseif ($hpBios -eq 1) {
		    	return $true
			}  Else {  
				return "ERROR : Valeur non déterminé lors du test d'existance du MdP Setup retourné : $hpBios"
		    }
			Break
		}
		"Dell Inc." 
		{
			#Test de parametrage d'une option sans mot de passe
			$Test1 = ExecuteCmd -FileName "$LibPath\CCTK\cctk.exe" -Arguments "--usbwake=enable"
			Write-host "---> Test de parametrage d'une option sans mot de passe --> $($Test1.stdout.trim())"
			if (($Test1.stdout.trim()) -eq "usbwake=enable") {
				return $False
			} Else {
                #Test de parametrage d'une option avec mot de passe
                $Test2 = ExecuteCmd -FileName "$LibPath\CCTK\cctk.exe" -Arguments "--usbwake=enable --valsetuppwd=$($Passw)"
				Write-host "---> Test de parametrage d'une option avec mot de passe --> $($Test2.stdout.trim())"
				if (($test2.stdout.trim()) -eq "usbwake=enable") {
					return $true
				} Else {
					return "ERROR : $($test2.stdout.trim())"
				}
			}
			Break
		}
		"LENOVO" {
			#Test de parametrage d'une option sans mot de passe
            $Test1 = Set-BiosOption -Option "ComputraceModuleActivation" -OptionValue "Disable" -Manufacturer "Lenovo"
			Write-host "---> Test de parametrage d'une option sans mot de passe --> $Test1"
			if ($test1 -match "Success") {
                return $false
            } Else {
				#Test de parametrage d'une option avec mot de passe
                $Test2 = Set-BiosOption -Option "ComputraceModuleActivation" -OptionValue "Disable" -Manufacturer "Lenovo" -CurrentPassword $Passw
				Write-host "---> Test de parametrage d'une option avec mot de passe --> $Test2"
				if ($test2 -match "Success") {
					return $true
				} Else {
					return "$($test2)"
				}
			}
			Break
		}
		Default {
			return "INFO : This brand is not yet managed by this script"
		}
	}
}
###############################################################################
# Fonction de paramétrage du "Setup password" sur les ordinateur HP,Dell et Lenovo
function Set-SetupPassword
{
    <#
		.SYNOPSIS
    		Sets the Setup Password on Bios.
		.DESCRIPTION
		    This function can be used to set a password on the Bios, it can also be used to clear the password, the current password is needed to change the value.
		    If a new value is being set, and not cleared, it must be between 8 and 30 characters.
		.EXAMPLE
		    Set-SetupPassword -NewPassword "MyNewPassword"
		.EXAMPLE
		    Set-SetupPassword -ComputerName "computername.domain.fr" -Manufacturer "Hewlett-Packard" -NewPassword " " -CurrentPassword "MyCurrentPassword" -cred (get-credential)
		.EXAMPLE
		    Set-SetupPassword -NewPassword "MyNewSetupPassword" -CurrentPassword "MyCurrentPassword"
		.LINK
		    Based on script https://github.com/PowerShellSith (Twitter: @PowerShellSith)  
		.CONNEX LINK
			function Out-VerboseReturnValues
			function ConvertTo-KBDString
	#>
	[CmdletBinding()]
    [OutputType([void])]
    Param
    (
        # ComputerName, Type string, System to set Bios Setup Password.
        [Parameter(Position=0,
                   ValueFromPipeline=$true)]
        [ValidateScript({ if (-not(Test-Connection -ComputerName $_ -Quiet -Count 2)) { throw "Failed to connect to $ComputerName.  Please ensure the system is available." } else { $true} })]
        [string[]]
        $ComputerName = $env:COMPUTERNAME
		,
		# Manufacturer, Type String, Constructor.
	    	[Parameter(Position=1)]
			$Manufacturer = $null
		,
        # NewPassword, Type string, The value of the password to be set.  The password can be cleared by using a space surrounded by double quotes, IE: " ".
        [Parameter(Mandatory=$true,
                   Position=2)]
        [string]
        $NewPassword
		,
        # CurrentPassword, Type string, The value of the current setup password.
        [Parameter(Position=3)]
        [string]
        $CurrentPassword = $null
		,
	 	# Cred, Type Credential, The credential of the command.
    	[Parameter(Position=4)]
		$cred = $null
    )
	#credentials management
	if ($cred -eq $null)
	{
		$CredentialParams = @{}
	}
	Elseif (($cred -ne $null) -and (($Computername -eq $env:COMPUTERNAME) -or ($computername -eq "localhost") -or ($computername -eq ".")))
	{
		$CredentialParams = @{}
	}
	Else
	{
		$CredentialParams = @{credential = $cred}
	}
	#Constructor searching
	if ($Manufacturer -eq $Null) {
		$Manufacturer = Get-Manufacturer
		if ($Manufacturer -match "ERROR :") {return $Manufacturer}
	}
	switch ($Manufacturer) {
		"Hewlett-Packard" {
			#if (-not([String]::IsNullOrWhiteSpace($NewPassword))) {
		        if (($NewPassword.Length -lt 8) -or ($NewPassword.Length -gt 30)) {
		            return "ERROR : La valeur du mot de passe doit être comprise entre 8 et 30 caractères si vous ne voulez pas réinitialiser le mot de passe."
				}
		    #}
		    try {
				$hpBios = Get-WmiObject -Class HP_BiosSetting -Namespace "root\HP\InstrumentedBIOS" -ComputerName $ComputerName -ErrorAction Stop @CredentialParams
		    } Catch {
				return "ERROR : $($error[0]) : Echec de connexion sur l'espace de nom WMI HP classe HP_BiosSetting, Vérifier si le system est disponible et si vous avez l'authorisation d'accéder à l'espace de nom."
			}
			try {
				$hpBiosSettings = Get-WmiObject -Class HPBIOS_BIOSSettingInterface -Namespace "root\HP\InstrumentedBIOS" -ComputerName $ComputerName -ErrorAction stop @CredentialParams
		    } Catch {
				return "ERROR : $($error[0]) : Failed to connect to the HP WMI namespace HPBIOS_BIOSSettingInterface class, Check if the system is available and if you have permission to access the namespace."
			}			
			switch (($hpBios | ?{ $_.Name -eq "Setup Password" }).SupportedEncoding) {
		        "kbd" { 
					$NewSetupPassword = "<kbd/>"+(ConvertTo-KBDString -UnicodeString $NewPassword) 
		            $CurrentSetupPassword = "<kbd/>"+(ConvertTo-KBDString -UnicodeString $CurrentPassword) 
		        	break
				}
		        "utf-16" { 
					$NewSetupPassword = "<utf-16/>"+$NewPassword 
		            $CurrentSetupPassword = "<utf-16/>"+$CurrentPassword 
		        	break
				}
		        default { 
					return "ERROR : Unknown encoding on current Setup Password"
				}
		    }
			$Resultat = Out-VerboseReturnValues -WmiMethodReturnValue ($hpBiosSettings.SetBIOSSetting("Setup Password",$NewSetupPassword,$CurrentSetupPassword)).Return
			if ($Resultat -ne $null) {
				return $resultat
			} Else {
				return "ERROR : Return unknown value, When changing password"
			}
			Break
		}
		"Dell Inc." {
			try
			{
				if ($CurrentPassword)
                {
                    $Setuppwd = ExecuteCmd -FileName "$LibPath\CCTK\cctk.exe" -Arguments "--setuppwd=$($NewPassword) --valsetuppwd=$($CurrentPassword)"
                }
                Else
                {
                    $Setuppwd = ExecuteCmd -FileName "$LibPath\CCTK\cctk.exe" -Arguments "--setuppwd=$($NewPassword)"
                }
    			if (($Setuppwd.stdout.trim()) -like "*Success*")
    			{
    				return "SUCCESS"
    			}
    			Else
    			{
    				return "ERROR : $($Setuppwd.stdout.trim())"
    			}
                  
			}
			catch
			{
				return "ERROR : $($_.exception.Message)"
			}
			Break
		}
		"LENOVO" {
			$PwdType = "pap"
			$encodage = "ascii"
			$kbdLang = "fr"
            
            # Creation of the WMI parameter to pass
			If (($CurrentPassword -ne $NULL) -and ($CurrentPassword -ne "")) { 
                $StrRequestSet = "$PwdType,$CurrentPassword,$NewPassword,$encodage,$kbdLang;"
            } else {
               return "ERROR : A Current password is required on Lenovo"
            }
			# Check if option is supported on the System
			try {
				$Check_option = Get-WmiObject -Computername $ComputerName -Class Lenovo_SetBiosPassword -Namespace root\wmi @CredentialParams
			} catch {
				return "ERROR : Failed to connect to the Lenovo WMI namespace, Check if the system is available and if you have permission to access the namespace."
			}
			if ($Check_option) {
				try {
					[string]$Resultat = ((gwmi -Computername $ComputerName -class Lenovo_SetBiosPassword -namespace root\wmi @CredentialParams).SetBiosPassword($StrRequestSet)).Return
				} Catch {
					return "ERROR : Failed to connect to the Lenovo WMI namespace with the result, Check if the system is available and if you have permission to access the namespace."
				}
				switch($Resultat) {
					'Success' {
						return "Success"
						break
					}
					'Not Supported' {
						return "ERROR : The feature is not supported on this system."
						break
					}
					'Access Denied' {
						return "ERROR : The change cannot be made due to an authentication problem. If a supervisor password exists, you must provide the correct one."
						break
					}
					'System Busy' {
						return "ERROR : BIOS changes have been made system pending. Restart the system and try again"
						break
					}
					'Invalid Parameter' {
						return "ERROR : The object or value entered is not valid."
						break
					}
					Default {
						return "ERROR : Unable to determine the error"
					}
				}	
			} Else {
				return "ERROR : Password configuration option is not supported on this Lenovo system"
			}
			Break
		}
		Default {
			return "INFO : This brand is not yet managed by this script"
		}
	}
}
###############################################################################
# Fonction de supression d'un mot de passe Setup Bios sur les ordinateurs HP, Dell et Lenovo
function Remove-SetupPassword
{
    <#
		.SYNOPSIS
    		Remove the Setup Password on Bios.
		.DESCRIPTION
		    This function can be used to clear a Setup password on the Bios, the current password is needed to change the value.
		    If a new value is being set, and not cleared, it must be between 8 and 30 characters.
		.EXAMPLE
		    Remove-SetupPassword
		.EXAMPLE
		    Remove-SetupPassword -ComputerName "computername.domain.fr" -Manufacturer "Dell Inc." -CurrentPassword "MyCurrentPassword" -NewPassword "" -cred (get-credential)
		.EXAMPLE
		    Remove-SetupPassword -CurrentPassword "MyCurrentPassword"
		.LINK
		    Based on script https://github.com/PowerShellSith (Twitter: @PowerShellSith)  
		.CONNEX LINK
			function Out-VerboseReturnValues
			function ConvertTo-KBDString
	#>
	[CmdletBinding()]
    [OutputType([void])]
    Param
    (
        # ComputerName, Type string, System to clear Bios Setup Password.
        [Parameter(Position=0,
                   ValueFromPipeline=$true)]
        [ValidateScript({ if (-not(Test-Connection -ComputerName $_ -Quiet -Count 2)) { throw "Failed to connect to $ComputerName.  Please ensure the system is available." } else { $true} })]
        [string[]]
        $ComputerName = $env:COMPUTERNAME
        ,
        # Manufacturer, Type String, Constructor.
	    [Parameter(Position=1)]
		$Manufacturer = $null
		,
		# CurrentPassword, Type string, The value of the current setup password.
        [Parameter(Position=2)]
        [string]
        $CurrentPassword
		,
		# NewPassword, Type string, The value for remove setup password.
        [Parameter(Position=3)]
        [string]
        $NewPassword = ""
		,
	 	# Cred, Type Credential, The credential of the command.
    	[Parameter(Position=4)]
		$cred = $null
    )
	#credentials management
	if ($cred -eq $null)
	{
		$CredentialParams = @{}
	}
	Elseif (($cred -ne $null) -and (($Computername -eq $env:COMPUTERNAME) -or ($computername -eq "localhost") -or ($computername -eq ".")))
	{
		$CredentialParams = @{}
	}
	Else
	{
		$CredentialParams = @{credential = $cred}
	}
	#Constructor searching
	if ($Manufacturer -eq $Null) {
		$Manufacturer = Get-Manufacturer
		if ($Manufacturer -match "ERROR :") {return $Manufacturer}
	}
	switch ($Manufacturer) {
		"Hewlett-Packard" {
		    $hpBios = (Get-WmiObject -Class HP_BiosSetting -Namespace "root\HP\InstrumentedBIOS" -ComputerName $ComputerName -ErrorAction Stop @CredentialParams | ?{ $_.Name -eq "Setup Password" }).SupportedEncoding
		    $hpBiosSettings = Get-WmiObject -Class HPBIOS_BIOSSettingInterface -Namespace "root\HP\InstrumentedBIOS" -ComputerName $ComputerName -ErrorAction stop @CredentialParams
		    switch ($hpBios) {
		        "kbd" { 
					$NewSetupPassword = "<kbd/>"+(ConvertTo-KBDString -UnicodeString $NewPassword) 
		            $CurrentSetupPassword = "<kbd/>"+(ConvertTo-KBDString -UnicodeString $CurrentPassword) 
		        	break
				}
		        "utf-16" { 
					$NewSetupPassword = "<utf-16/>"+$NewPassword 
		            $CurrentSetupPassword = "<utf-16/>"+$CurrentPassword 
		        	break
				}
		        default { 
					return "ERROR : Unknown encoding on current Setup Password"
				}
		    }
			$Resultat = Out-VerboseReturnValues -WmiMethodReturnValue ($hpBiosSettings.SetBIOSSetting("Setup Password",$NewSetupPassword,$CurrentSetupPassword)).Return
			if ($Resultat -ne $null) {
				return $resultat
			} Else {
				return "ERROR : Return unknown value, When deleting the setup password"
			}
			Break
		}
		"Dell Inc." {
			try
			{
				$RemoveSetuppwd = ExecuteCmd -FileName "$LibPath\CCTK\cctk.exe" -Arguments "--setuppwd= --valsetuppwd=$($CurrentPassword)"
				if (($RemoveSetuppwd.stdout.trim()) -like "*Success*")
				{
					return "SUCCESS"
				}
				Else
				{
					return "ERROR : $($RemoveSetuppwd.stdout.trim())"
				}
			}
			catch
			{
				return "ERROR : $($_.exception.Message)"
			}
			Break
		}
		"LENOVO" {
			$PwdType = "pap"
			$encoding = "ascii"
			$kbdLang = "fr"
			$NewPassword = ""
			# Verifie si l'option est supporté sur le system
			try {
				$Check_option = Get-WmiObject -Computername $ComputerName -Class Lenovo_SetBiosPassword -Namespace root\wmi @CredentialParams
			} catch {
				return "ERROR : Failed to connect to the Lenovo WMI namespace, Check if the system is available and if you have permission to access the namespace."
			}
			if ($Check_option) {
				try {
					[string]$Resultat = ((gwmi -Computername $ComputerName -class Lenovo_SetBiosPassword -namespace root\wmi @CredentialParams).SetBiosPassword("$PwdType,$CurrentPassword,$NewPassword,$encoding,$kbdLang;")).Return
				} Catch {
					return "ERROR : Failed to connect to the Lenovo WMI namespace with the result, Check if the system is available and if you have permission to access the namespace."
				}
				switch($Resultat) {
					'Success' {
						return "Success"
						break
					}
					'Not Supported' {
						return "ERROR : The feature is not supported on this system."
						break
					}
					'Access Denied' {
						return "ERROR : The change cannot be made due to an authentication problem. If a supervisor password exists, you must provide the correct one."
						break
					}
					'System Busy' {
						return "ERROR : BIOS changes have been made system pending. Restart the system and try again"
						break
					}
					'Invalid Parameter' {
						return "ERROR : The object or value entered is not valid."
						break
					}
					Default {
						return "ERROR : Unable to determine the error"
					}
				}	
			} Else {
				return "ERROR : Password configuration option is not supported on the system"
			}
			Break
		}
		Default {
			return "INFO : This brand is not yet managed by this script"
		}
	}
}
###############################################################################
# lists the Bios options with their value on HP, Dell and Lenovo PCs
function Get-BiosOptionslist
{
	<#
		.SYNOPSIS
	    	Get list of options on Bios.
		.DESCRIPTION
			This function can be used to get list of options on the Bios.
		.EXAMPLE
			Get-BiosOption -computerName "computername.domain.fr" -Manufacturer "Hewlett-Packard" -cred (get-credential)
		.LINK
		
		.CONNEX LINK
			
	#>
	
	[CmdletBinding()]
	[OutputType([string])]
	Param (
		# ComputerName, Type string, System to Get Bios option.
		[Parameter(Position = 0,
				   ValueFromPipeline = $true)]
		[ValidateScript({ if (-not (Test-Connection -ComputerName $_ -Quiet -Count 2)) { throw "Failed to connect to $ComputerName.  Please ensure the system is available." }
				else { $true } })]
		[string[]]$ComputerName = $env:COMPUTERNAME
		 ,
		# Manufacturer, Type String, Constructor.

		[Parameter(Position = 1)]
		$Manufacturer = $null
		 ,
		# WithValue, Type Switch, list with value.

		[Parameter(Position = 2)]
		[switch]$withValue
		 ,
		# Cred, Type Credential, The credential of the command.

		[Parameter(Position = 3)]
		$cred = $null
	)
	#credentials management
	if ($cred -eq $null)
	{
		$CredentialParams = @{ }
	}
	Elseif (($cred -ne $null) -and (($Computername -eq $env:COMPUTERNAME) -or ($computername -eq "localhost") -or ($computername -eq ".")))
	{
		$CredentialParams = @{ }
	}
	Else
	{
		$CredentialParams = @{ credential = $cred }
	}
	#Constructor searching
	if ($Manufacturer -eq $Null)
	{
		$Manufacturer = Get-Manufacturer
		if ($Manufacturer -match "ERROR :") { return $Manufacturer }
	}
	$ResListoptions = @()
	switch ($Manufacturer)
	{
		"Hewlett-Packard"
		{
			try
			{
				[array]$ListOptions = Get-WmiObject -Computername $ComputerName -Namespace "root\HP\InstrumentedBIOS" -Class HP_BiosSetting -ErrorAction Stop @CredentialParams
			}
			catch
			{
				return "ERROR : $($_.exception.Message)"
			}
			
			if ($ListOptions)
			{
				#return $ListOptions
				foreach ($opt in $ListOptions)
				{
					[string]$nameopt = $opt.name.trim()
					if ($nameopt)
					{
						if ($withValue)
						{
							$ValueoptTemp = $opt.Value
							if ($ValueoptTemp)
							{
								[string]$Valueopt = $ValueoptTemp.trim()
							}
							Else
							{
								[string]$Valueopt = $null
							}
							[array]$ResListoptions += ,("$($nameopt)=$($Valueopt)")
						}
						Else
						{
							[array]$ResListoptions += ,("$($nameopt)")
						}
					}
				}
				if ($ResListoptions) { return $ResListoptions }
				Else { return $null }
			}
			Else
			{
				return $null
			}
			Break
		}
		"Dell Inc."
		{
			try
			{
				[Array]$ListOptions = (Get-WmiObject -Computername $ComputerName -Class DCIM_BIOSEnumeration -Namespace root\dcim\sysman -Erroraction Stop @CredentialParams)
			}
			catch
			{
				return "ERROR : $($_.exception.Message)"
			}
			if ($ListOptions)
			{
				return $ListOptions
			}
			Else
			{
				return $null
				
			}
			Break
		}
		"LENOVO"
		{
			try
			{
				$ListOptions = gwmi -ComputerName $ComputerName -namespace root\wmi -class Lenovo_BiosSetting -ErrorAction Stop @CredentialParams
				#| ForEach-Object {if ($_.CurrentSetting -ne "") {Write-Host $_.CurrentSetting.replace(","," = ")}}
			}
			catch
			{
				return "ERROR : $($_.exception.Message)"
			}
			if ($ListOptions)
			{
				foreach ($opt in $ListOptions)
				{
					$ValueOptTemp = $opt.CurrentSetting
					if ($ValueOptTemp)
					{
						if ($withValue)
						{
							[string]$Valueopt = ($ValueOptTemp.replace(",", " = ")).trim()
						}
						Else
						{
							[string]$Valueopt = (($ValueOptTemp.split(','))[0]).trim()
						}
						if ($Valueopt) { [array]$ResListoptions += ,("$($Valueopt)") }
					}
				}
				if ($ResListoptions) { return $ResListoptions }
				Else { return $null }
				
			}
			Else
			{
				return $null
			}
			Break
		}
		Default
		{
			return "INFO : This Mark is not managed by this script"
		}
	}
}
###############################################################################
# get Boot Legacy order settings on HP, Dell and Lenovo PCs
function Get-BiosBootOrderLegacy
{
	<#
		.SYNOPSIS
	    	Get Bios Boot Order Legacy.
		.DESCRIPTION
			This function can be used to get the Bios Boot Order Legacy.
		.EXAMPLE
			Get-BiosBootOrderLegacy
		.EXAMPLE
			Get-BiosBootOrderLegacy -computerName "computername.domain.fr" -manufacturer "Lenovo" -Option "BootOrder" -cred (get-credential)
		.LINK
		
		.CONNEX LINK
			
	#>
	
	[CmdletBinding()]
	[OutputType([string])]
	Param (
		# ComputerName, Type string, System to Get Bios option.
		[Parameter(Position = 0,
				   ValueFromPipeline = $true)]
		[ValidateScript({ if (-not (Test-Connection -ComputerName $_ -Quiet -Count 2)) { throw "Failed to connect to $ComputerName. Please ensure the system is available." }
				else { $true } })]
		[string[]]$ComputerName = $env:COMPUTERNAME
		 ,
		# Manufacturer, Type String, Constructor.

		[Parameter(Position = 1)]
		$Manufacturer = $null
		 ,
		# Option, L'option à interroger.

		[Parameter(Position = 2)]
		$Option = $null
		 ,
		# Cred, Type Credential, The credential of the command.

		[Parameter(Position = 3)]
		$cred = $null
	)
	#credentials management
	if ($cred -eq $null)
	{
		$CredentialParams = @{ }
	}
	Elseif (($cred -ne $null) -and (($Computername -eq $env:COMPUTERNAME) -or ($computername -eq "localhost") -or ($computername -eq ".")))
	{
		$CredentialParams = @{ }
	}
	Else
	{
		$CredentialParams = @{ credential = $cred }
	}
	#Constructor searching
	if ($Manufacturer -eq $Null)
	{
		$Manufacturer = Get-Manufacturer
		if ($Manufacturer -match "ERROR :") { return $Manufacturer }
	}
	switch ($Manufacturer)
	{
		"Hewlett-Packard" {
			if ($Option -eq $null) { $Option = "Legacy Boot Order" }
			try
			{
				$Liste_Boot_Order = (Get-WmiObject -Computername $ComputerName -Class HP_BIOSOrderedList -Namespace "root\HP\InstrumentedBIOS" @CredentialParams | Where-Object { ($_.Name -eq $Option) }).value
				if ($Liste_Boot_Order)
				{
					return $Liste_Boot_Order
				}
				Else
				{
					return "ERROR : Option $Option Not defined or not existing"
				}
			}
			catch
			{
				return "ERROR : Unable to connect to WMI namespace HP_BIOSOrderedList, Option name: $Option, verify that the system is available and that you have permissions to access the namespace."
			}
			Break
		}
		"Dell Inc." {
			[string]$Liste_Boot_Order = $null
			[array]$GetOpt = @()
			if ($Option -eq $null) { $Option = "bootorder" } #--bootlisttype=legacy"}
			try
			{
				[array]$GetOpt = cmd.exe /c """$LibPath\CCTK\cctk.exe"" $($option) --bootlisttype=legacy"
				if ($GetOpt)
				{
					$i = 3
					while (($getopt[$i]) -notmatch "----------")
					{
						$getopt[$i] = (($getopt[$i]) -replace "\s{2,}", ";").trim(';')
						$deviceStatus = (($getopt[$i]).split(';'))[0].trim(';')
						$deviceNumber = (($getopt[$i]).split(';'))[1].trim(';')
						$devicetype = (($getopt[$i]).split(';'))[2].trim(';')
						$shortform = (($getopt[$i]).split(';'))[3].trim(';')
						$devicedescription = (($getopt[$i]).split(';'))[4].trim(';')
						if ($deviceStatus -eq "Enabled") { [string]$Liste_Boot_Order += $shortform + "," }
						write-host "$($shortform)=$($deviceStatus)"
						$i++
					}
					if ($Liste_Boot_Order)
					{
						$Liste_Boot_Order = $Liste_Boot_Order.trim(',')
						return $Liste_Boot_Order
					}
					Else
					{
						return "ERROR : No Enabled element found in the list"
					}
					
				}
				Else
				{
					return "ERROR : No boot list recovered"
				}
			}
			catch
			{
				return "ERROR : $($_.exception.Message)"
			}
			Break
		}
		"LENOVO" {
			if ($Option -eq $null) { $Option = "BootOrder" }
			try
			{
				[string]$Liste_Boot_Order = $null
				$opt = (Get-WmiObject -Computername $ComputerName -Class Lenovo_BiosSetting -Namespace root\wmi @CredentialParams | Where-Object { ((($_.CurrentSetting).split(','))[0] -eq "BootOrder") }).CurrentSetting
				if ($opt)
				{
					$Liste_Boot_Order = (($opt.split(','))[1]) #.replace(':',',')
					if ($Liste_Boot_Order -eq $null)
					{
						return "ERROR : Lenovo Boot Order List Undefined or non-existent"
					}
					Else
					{
						return $Liste_Boot_Order
					}
				}
				Else
				{
					return "ERROR : BootOrder option not found"
				}
			}
			catch
			{
				return "ERROR : Unable to connect to the WMI namespace Lenovo_BiosSetting, CurrentSetting Boot Order, verify that the system is available and that you have permissions to access the namespace."
			}
			Break
		}
		Default
		{
			return "INFO : Brand not processed by this script"
		}
	}
}
###############################################################################
# Fonction de lecture des paramétres de l'ordre de Boot Legacy sur les ordinateurs HP, Dell et Lenovo
function Get-BiosBootOrderUEFI
{
	<#
		.SYNOPSIS
	    	Get Bios Boot Order UEFI.
		.DESCRIPTION
			This function can be used to get the Bios Boot Order UEFI.
		.EXAMPLE
			Get-BiosBootOrderUEFI
		.EXAMPLE
			Get-BiosBootOrderUEFI -computerName "computername.domain.fr" -manufacturer "Lenovo" -Option "BootOrder" -cred (get-credential)
		.LINK
		
		.CONNEX LINK
			
	#>
	
	[CmdletBinding()]
	[OutputType([string])]
	Param (
		# ComputerName, Type string, System to Get Bios option.
		[Parameter(Position = 0,
				   ValueFromPipeline = $true)]
		[ValidateScript({ if (-not (Test-Connection -ComputerName $_ -Quiet -Count 2)) { throw "Failed to connect to $ComputerName. Please ensure the system is available." }
				else { $true } })]
		[string[]]$ComputerName = $env:COMPUTERNAME
		 ,
		# Manufacturer, Type String, Constructor.

		[Parameter(Position = 1)]
		$Manufacturer = $null
		 ,
		# Option, L'option à interroger.

		[Parameter(Position = 2)]
		$Option = $null
		 ,
		# Cred, Type Credential, The credential of the command.

		[Parameter(Position = 3)]
		$cred = $null
	)
	#credentials management
	if ($cred -eq $null)
	{
		$CredentialParams = @{ }
	}
	Elseif (($cred -ne $null) -and (($Computername -eq $env:COMPUTERNAME) -or ($computername -eq "localhost") -or ($computername -eq ".")))
	{
		$CredentialParams = @{ }
	}
	Else
	{
		$CredentialParams = @{ credential = $cred }
	}
	#Constructor searching
	if ($Manufacturer -eq $Null)
	{
		$Manufacturer = Get-Manufacturer
		if ($Manufacturer -match "ERROR :") { return $Manufacturer }
	}
	switch ($Manufacturer)
	{
		"Hewlett-Packard" {
			if ($Option -eq $null) { $Option = "EFI Boot Order" }
			try
			{
				$Liste_Boot_Order = (Get-WmiObject -Computername $ComputerName -Class HP_BIOSOrderedList -Namespace "root\HP\InstrumentedBIOS" @CredentialParams | Where-Object { ($_.Name -eq $Option) }).value
				if ($Liste_Boot_Order)
				{
					return $Liste_Boot_Order
				}
				Else
				{
					return "ERROR : Option $Option Not defined or not existing"
				}
			}
			catch
			{
				return "ERROR : Unable to connect to WMI namespace HP_BIOSOrderedList, Option name: $Option, verify that the system is available and that you have permissions to access the namespace."
			}
			Break
		}
		"Dell Inc." {
			[string]$Liste_Boot_Order = $null
			[array]$GetOpt = @()
			if ($Option -eq $null) { $Option = "bootorder" } #--bootlisttype=legacy"}
			try
			{
				[array]$GetOpt = cmd.exe /c """$LibPath\CCTK\cctk.exe"" $($option) --bootlisttype=legacy"
				if ($GetOpt)
				{
					$i = 3
					while (($getopt[$i]) -notmatch "----------")
					{
						$getopt[$i] = (($getopt[$i]) -replace "\s{2,}", ";").trim(';')
						$deviceStatus = (($getopt[$i]).split(';'))[0].trim(';')
						$deviceNumber = (($getopt[$i]).split(';'))[1].trim(';')
						$devicetype = (($getopt[$i]).split(';'))[2].trim(';')
						$shortform = (($getopt[$i]).split(';'))[3].trim(';')
						$devicedescription = (($getopt[$i]).split(';'))[4].trim(';')
						if ($deviceStatus -eq "Enabled") { [string]$Liste_Boot_Order += $shortform + "," }
						write-host "$($shortform)=$($deviceStatus)"
						$i++
					}
					if ($Liste_Boot_Order)
					{
						$Liste_Boot_Order = $Liste_Boot_Order.trim(',')
						return $Liste_Boot_Order
					}
					Else
					{
						return "ERROR : No Enabled element found in the list"
					}
					
				}
				Else
				{
					return "ERROR : No boot list recovered"
				}
			}
			catch
			{
				return "ERROR : $($_.exception.Message)"
			}
			Break
		}
		"LENOVO" {
			if ($Option -eq $null) { $Option = "BootOrder" }
			try
			{
				[string]$Liste_Boot_Order = $null
				$opt = (Get-WmiObject -Computername $ComputerName -Class Lenovo_BiosSetting -Namespace root\wmi @CredentialParams | Where-Object { ((($_.CurrentSetting).split(','))[0] -eq "BootOrder") }).CurrentSetting
				if ($opt)
				{
					$Liste_Boot_Order = (($opt.split(','))[1]) #.replace(':',',')
					if ($Liste_Boot_Order -eq $null)
					{
						return "ERROR : Lenovo Boot Order List Undefined or non-existent"
					}
					Else
					{
						return $Liste_Boot_Order
					}
				}
				Else
				{
					return "ERROR : option BootOrder non trouvé"
				}
			}
			catch
			{
				return "ERROR : Unable to connect to the WMI namespace Lenovo_BiosSetting, CurrentSetting Boot Order, verify that the system is available and that you have permissions to access the namespace."
			}
			Break
		}
		Default
		{
			return "INFO : Brand not processed by this script"
		}
	}
}