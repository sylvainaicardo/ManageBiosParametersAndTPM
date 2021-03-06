###############################################################################
# Fonction générique pour l'obtention de l'etat d'une option pour TPM
Function Get-OptionTPM_IsSet($Manufacturer,$ListOptions,[Bool]$EgalTest=$true) {
	$Bool_Etat_Option = $true
	$BoolSuiteOpération = $true
	if (($ListOptions -ne $null) -and ($ListOptions -ne "")) {
		[array]$TabOptions = $ListOptions.split(';')
		if ($TabOptions.count -gt 0) {
			foreach ($Opt in $TabOptions) {
				$NameOption = ($Opt.split('#'))[0]
				$ValueOption = ($Opt.split('#'))[1]
				Write-host "------ Vérification de l'option $NameOption"
				add_log $log "------ Vérification de l'option $NameOption"
				if (($NameOption -eq "Activate TPM On Next Boot") -or ($NameOption -eq "Activate Embedded Security On Next Boot"))
				{
					Write-Host "-------- Cas Option $NameOption"
					try
					{
						$EtatTPM = (Get-WmiObject -namespace root\cimv2\security\microsofttpm -class win32_tpm).IsActivated().IsActivated
						if ($EtatTPM)
						{
							$BoolSuiteOpération = $false
						}
					}
					Catch
					{
						Write-Host "-------- $($_.exception.message)"
					}
				}
				if ($BoolSuiteOpération) 
				{
					if ($ValueOption -like "*`+*") {
						Write-Host "-------- Options multiples dans la valeur de la chaine d'option détecté..."
						$ValueOptionTemp = $null
						$VTemp = $null
						$Val = $ValueOption.split(',')
						foreach ($v in $val) {
							Write-Host "-------- Test valeur $v"
							if ($v -like "*`+*") {
								$v.split('`+') | foreach {
									$OptionTest = ($_).trim()
									Write-Host "---------- Test Option : $OptionTest"
									$optionExist = Get-BiosOptionExist -option $OptionTest -Manufacturer $Manufacturer
									if ($optionExist) {
										Write-Host "---------- Option Trouvé : $OptionTest"
										$VTemp = $_
									} Else {
										Write-Host "---------- Option $OptionTest non touvé"
									}
								}
								$ValueOptionTemp = $ValueOptionTemp + $VTemp + ","
							} Else {
								$ValueOptionTemp = $ValueOptionTemp + $v + ","
							}
						}
						$ValueOption = $ValueOptionTemp.trim(',')
						Write-Host "-------- Valeur retenu : $ValueOption"
					}
					$optionExist = Get-BiosOptionExist -option $NameOption -Manufacturer $Manufacturer
					if ($optionExist) {
						$Etat_Option = get-BiosOption -option $NameOption -Manufacturer $Manufacturer
						if (!$EgalTest) {
							if ($Etat_Option -notlike "$ValueOptionBootOrder`*") {
								Write-host "------ Option $NameOption valeur trouvé : $Etat_Option" 
								Write-host "------ --> Valeur attendu : $ValueOption"
								add_log $log "------ Option $NameOption valeur trouvé : $Etat_Option"
								add_log $log "------ --> Valeur attendu : $ValueOption"
								$Bool_Etat_Option = $false
							} Else {
								Write-host "------ Option $NameOption bien positionné valeur : $Etat_Option"
								add_log $log "------ Option $NameOption bien positionné valeur : $Etat_Option"
							}
						} else {
							if ($Etat_Option -ne $ValueOption) {
								Write-host "------ Option $NameOption valeur trouvé : $Etat_Option" 
								Write-host "------ --> Valeur attendu : $ValueOption"
								add_log $log "------ Option $NameOption valeur trouvé : $Etat_Option"
								add_log $log "------ --> Valeur attendu : $ValueOption"
								$Bool_Etat_Option = $false
							} Else {
								Write-host "------ Option $NameOption bien positionné valeur : $Etat_Option"
								add_log $log "------ Option $NameOption bien positionné valeur : $Etat_Option"
							}
						}
					} else {
						return "ERREUR : option(s) $NameOption non trouvé"
					}
				}
			}
		} Else {
			return "ERREUR : Pas d'option valide trouvé dans le XML"
		}
	}
	return $Bool_Etat_Option
}
###############################################################################
# Fonction générique pour le parametrage d'une option pour TPM
Function Set-OptionTPM ($Pwd,$Manufacturer,$ListOptions) {
    
    $Bool_Resultat = $true
	if (($ListOptions -ne $null) -and ($ListOptions -ne "")) {
        [array]$TabOptions = $ListOptions.split(';')
		if ($TabOptions.count -gt 0) {
			foreach ($Opt in $TabOptions) {
				$NameOption = ($Opt.split('#'))[0]
				$ValueOption = ($Opt.split('#'))[1]
				if ($ValueOption -like "*`+*") {
					Write-Host "---------- Options multiples dans la valeur de la chaine d'option détecté..."
					$ValueOptionTemp = $null
					$VTemp = $null
					$Val = $ValueOption.split(',')
					foreach ($v in $val) {
						Write-Host "-------- Test valeur $v"
						if ($v -like "*`+*") {
							$v.split('`+') | foreach {
								$OptionTest = (($_).replace(" Drive","")).trim()
								Write-Host "---------- Test Option : $OptionTest"
								$optionExist = Get-BiosOptionExist -option $OptionTest -Manufacturer $Manufacturer
								if ($optionExist) {
									Write-Host "---------- Option Trouvé : $OptionTest"
									$VTemp = $_
								} Else {
									Write-Host "---------- Option $OptionTest non touvé"
								}
							}
							$ValueOptionTemp = $ValueOptionTemp + $VTemp + ","
						} Else {
							$ValueOptionTemp = $ValueOptionTemp + $v + ","
						}
					}
					$ValueOption = $ValueOptionTemp.trim(',')
					Write-Host "-------- Valeur retenu : $ValueOption"
				}
				$optionExist = Get-BiosOptionExist -option $NameOption -Manufacturer $Manufacturer
				if ($optionExist) {
					Write-host "------ Parametrage de l'option $NameOption --> valeur : $ValueOption"
					add_log $log "------ Parametrage de l'option $NameOption --> valeur : $ValueOption"
					if ($pwd -ne $null) {
						$OptionTPM = set-BiosOption -option $NameOption -OptionValue $ValueOption -Manufacturer $Manufacturer -CurrentPassword $Pwd
					} Else {
						$OptionTPM = set-BiosOption -option $NameOption -OptionValue $ValueOption -Manufacturer $Manufacturer
					}
					if ($OptionTPM -ne "Success") {$Bool_Resultat = $false}
				} else {
					return "ERREUR : option(s) $NameOption non trouvé"
				}
			}
		} Else {
			return "INFO : Pas d'option valide trouvé dans le XML pour l'activation de la puce TPM"
		}
	}
	return $Bool_Resultat
}
###############################################################################
# Fonction indiquant si la machine a une version de puce TPM correcte (1.2)
Function TPMVersion($Computer)
{
	$ver = Get-WmiObject -class Win32_Tpm -namespace "root\CIMV2\Security\MicrosoftTpm" -computername $Computer | % { $_.SpecVersion }
    return $ver
} 
###############################################################################
# Fonction retournant l'état de la puce TPM
Function TPMState($Computer)
{
	$Result = "ERREUR : Aucun Etat trouvé"
	try 
	{
		$tpm_status = Get-WmiObject -ComputerName $Computer -class Win32_Tpm -namespace "root\CIMV2\Security\MicrosoftTpm" -ErrorAction Stop

		if ($tpm_status)
		{
			Foreach ($objItem in $tpm_status) 
	    	{
	    		If ($objItem.IsEnabled().IsEnabled) { $Result = "Enabled" }
	    		If ($objItem.IsActivated().IsActivated) { $Result = "Activated" }
	    		If ($objItem.IsOwned().IsOwned) { $Result = "Owned" }       
	    	}
			Write-Host "Resultat état puce TPM : $($Result)"
		}
		Else
		{
			$Result = "INFO : Ce poste n'as soit pas de puce TPM soit elle n'est pas en fonction dans le bios"
		}
		return $Result
	}
	Catch
	{
		return "ERREUR : $($_.Exception.Message)"
	}
}
###############################################################################
# Fonction indiquant si la machine est TPM Ready pour Windows
Function TPMReady($Computer)
{
	If ((((TPMState ".") -eq "Activated") -OR ((TPMState ".") -eq "Owned")) -AND ((TPMVersion ".") -match "1.2"))
		{ Return $True }
	Else
		{ Return $False }
}
###############################################################################
# Fonction indiquant si la machine est en version TPM Ready pour Windows
Function TPMVersionReady($Computer)
{
	If ((TPMVersion ".") -match "1.2")
		{ Return $True }
	Else
		{ Return $False }
}
###############################################################################
# Fonction donnant l'etat des options supplémentaires pour la puce TPM
Function Get-TPMOtherOptions_IsSet($Manufacturer,$ListOptionsSupp)
{
	Switch ($Manufacturer)
    {
		"LENOVO" {
			return "INFO : Pas d'option Sup à vérifier pour LENOVO"
			break
		}
		"Dell Inc." {
			return "INFO : Pas d'option Sup à verifier pour DELL"
			break
		}
		"Hewlett-Packard" {
			$Etat_OptionSupp = Get-OptionTPM_IsSet -Manufacturer $Manufacturer -ListOptions $ListOptionsSupp
			if ($Etat_OptionSupp -match "ERREUR :") {
				return $Etat_OptionSupp
			} Elseif ($Etat_OptionSupp -match "INFO :") {
				return $Etat_OptionSupp
			} Elseif ($Etat_OptionSupp -eq $true) {
				return $true
			} Else {
				return $false
			}
			Break
		}
		"Microsoft Corporation" {
			return "INFO : Pas d'option Sup à vérifier pour Microsoft"
			break
		}
		Default {
			return "INFO : Constructeur non pris en charge par ce script pour le vérification des options sup TPM"
		}
	}
}
###############################################################################
# Fonction Activant les options supplémentaires pour la puce TPM
Function Set-TPMOtherOptions($PASSWORD,$Manufacturer,$ListOptionsSupp)
{
	if ($Manufacturer -eq "Hewlett-Packard") {
		$OptionSuppTPM = Set-optionTPM -pwd $PASSWORD -Manufacturer $Manufacturer -ListOptions $ListOptionsSupp
		return $OptionSuppTPM
	} Else {
		return "INFO : Pas d'option Supp TPM à configurer pour $Manufacturer"
	}
}
###############################################################################
# Fonction donnant l'etat de validation de la puce TPM
function Get-TPMvalidation_IsSet ($Manufacturer,$ListOptionsValidation) {
	if (($Manufacturer -eq "Hewlett-Packard") -or ($Manufacturer -eq "Dell Inc.")) {
		#HP --> Embedded Security Device#Device available;Embedded Security Device Availability#Available;TPM Device#Available"
		#Dell --> Trusted Platform Module#1
		$Etat_EnableTPM = Get-OptionTPM_IsSet -Manufacturer $Manufacturer -ListOptions $ListOptionsValidation
		if ($Etat_EnableTPM -match "ERREUR :") {
			return $Etat_EnableTPM
		} Elseif ($Etat_EnableTPM -match "INFO :") {
			return $Etat_EnableTPM
		} Elseif ($Etat_EnableTPM -eq $true) {
			return $true
		} Else {
			return $false
		}
	} Elseif ($Manufacturer -eq "LENOVO") {
		return "INFO : La validation n'est pas nécéssaire pour les Lenovo"
	} Elseif ($Manufacturer -eq "Microsoft Corporation") {
		return "INFO : La validation n'est pas nécéssaire pour les postes Microsoft"
	} Else {
		return "INFO : Constructeur non pris en charge par ce script ou validation non nécéssaire"
	}
}
###############################################################################
# Fonction de validation TPM
function Set-TPMvalidation($Password,$Manufacturer,$ListOptionsValidation) {
	
	#HP --> Embedded Security Device#Device available;Embedded Security Device Availability#Available;TPM Device#Available
	#Dell --> Trusted Platform Module#1
    if (($Manufacturer -eq "Hewlett-Packard") -or ($Manufacturer -eq "Dell Inc.")) {
		$ValidTPM = Set-optionTPM -pwd $PASSWORD -Manufacturer $Manufacturer -ListOptions $ListOptionsValidation
		return $ValidTPM
	} Elseif ($Manufacturer -eq "LENOVO") {
		return "INFO : Ce Constructeur n'a pas besoin de validation de la puce TPM"
	} Else {
		return "INFO : Constructeur non pris en charge par ce script"
	}
}
###############################################################################
# Fonction donnant l'etat d'activation de la puce TPM
function Get-TPMactivation_IsSet ($Manufacturer,$ListOptionsActivation) {
	switch ($manufacturer) {
		"Hewlett-Packard" {
			#HP --> Activate Embedded Security On Next Boot#Enable;Activate TPM On Next Boot#Enable;Activate TPM On Next Boot#Enable
			#$Etat_ActivationTPM = TPMReady "."
			
			$Etat_ActivationTPM = Get-OptionTPM_IsSet -Manufacturer $Manufacturer -ListOptions $ListOptionsActivation
			if ($Etat_ActivationTPM -match "ERREUR :") {
				return $Etat_ActivationTPM
			} Elseif ($Etat_ActivationTPM -match "INFO :") {
				return $Etat_ActivationTPM
			} Elseif ($Etat_ActivationTPM -eq $true) {
				return $true
			} Else {
				return $false
			}
			break
		}
		"Dell Inc." {
			#Dell --> Trusted Platform Module Activation#2
			$Etat_ActivationTPM = Get-OptionTPM_IsSet -Manufacturer $Manufacturer -ListOptions $ListOptionsActivation
			if ($Etat_ActivationTPM -match "ERREUR :") {
				return $Etat_ActivationTPM
			} Elseif ($Etat_ActivationTPM -match "INFO :") {
				return $Etat_ActivationTPM
			} Elseif ($Etat_ActivationTPM -eq $true) {
				return $true
			} Else {
				return $false
			}
			break
		}
		"LENOVO" {
			#Lenovo --> SecurityChip#Activate
			# Gestion des erreurs
			$Etat_ActivationTPM = $true
			if (($ListOptionsActivation -ne $null) -and ($ListOptionsActivation -ne "")) {
				[array]$TabOptionsActivation = $ListOptionsActivation.split(';')
				if ($TabOptionsActivation.count -gt 0) {
					foreach ($OptionActivation in $TabOptionsActivation) {
						$error.clear()
						$OptionActivationName = ($OptionActivation.split('#'))[0]
						$OptionActivationValue = ($OptionActivation.split('#'))[1]
						# Vérification de l'état de la puce TPM
						$SecurityChip = Get-WmiObject -class Lenovo_BiosSetting -Namespace root\WMI -ComputerName "." -erroraction silentlycontinue | where-object {$_.CurrentSetting -like "*$($OptionActivationName)*"} | % { $_.CurrentSetting }
						if ($error.count -eq 0) {
							$SecurityChip_Value = $SecurityChip.Split(",")[1]
							Write-host "------ Vérification de l'option $OptionActivationName Valeur trouvé : $SecurityChip_Value --> Valeur attendu : $OptionActivationValue"
							add_log $log "------ Vérification de l'option $OptionActivationName Valeur trouvé : $SecurityChip_Value --> Valeur attendu : $OptionActivationValue"
							if ($SecurityChip_Value -ne $OptionActivationValue) {
								$Etat_ActivationTPM = $false
							} 
						} else {
							$error.clear()
							return "ERREUR : Le BIOS de ce LENOVO ne peut pas être vérifié via WMI" 
						}
					}
				} Else {
					return "INFO : Pas d'option valide trouvé dans le XML"
				}
			}
			return $Etat_ActivationTPM
			break
		}
		"Microsoft Corporation" {
			$Etat_ActivationTPM = TPMState "."
			if ($Etat_ActivationTPM -match "ERREUR :") {
				return $Etat_ActivationTPM
			} Elseif ($Etat_ActivationTPM -match "INFO :") {
				return $Etat_ActivationTPM
			} Elseif (($Etat_ActivationTPM -eq "Activated") -or ($Etat_ActivationTPM -eq "Owned")) {
				return $true
			} Else {
				return $false
			}
			break
		}
		Default {
			return "INFO : Constructeur non pris en charge par ce script"
		}
	}
}
###############################################################################
# Fonction d'activation de la puce TPM
function Set-TPMActivation($PASSWORD,$Manufacturer,$ListOptionsActivation)
{
	if (($Manufacturer -eq "Hewlett-Packard") -or ($Manufacturer -eq "Dell Inc.") -or ($Manufacturer -eq "LENOVO")) {
		#Hewlett-Packard --> Activate Embedded Security On Next Boot:Enable,Activate TPM On Next Boot:Enable
		#Dell --> Trusted Platform Module Activation:2
		# Lenovo --> SecurityChip:Active
		$ActiveTPM = Set-optionTPM -pwd $PASSWORD -Manufacturer $Manufacturer -ListOptions $ListOptionsActivation
		return $ActiveTPM
	} Else {
		return "INFO : Marque non géré par ce script"
	}
}
###############################################################################
# Fonction donnant l'etat de Configuration de l'ordre de démarrage du BIOS pour TPM et WOL
#Function Get-TPMBiosBootOrderLegacy_IsSet ($Manufacturer,$ListOptionsBootOrder,$ListOtherBootOrderOptions)
#{    
#	#HP -->
#	#Dell --> bootorder#hdd,embnic
#	#Lenovo --> BootOrder#HDD0:PCLAN;NetworkBootOrder#HDD0:PCLAN ou BootOrder#HDD0;NetworkBoot#HDD0
#	
#	if (($manufacturer -eq "Hewlett-Packard") -or ($manufacturer -eq "Dell Inc.") -or ($manufacturer -eq "LENOVO")) {
#		$Bool_Resultat_BootOrder = $true 
#		if (($ListOptionsBootOrder -ne $null) -and ($ListOptionsBootOrder -ne "")) {
#			[array]$TabOptionsBootOrder = $ListOptionsBootOrder.split(';')
#			if ($TabOptionsBootOrder.count -gt 0) {
#				foreach ($OptBootOrder in $TabOptionsBootOrder) {
#					$NameOptionBootOrder = ($OptBootOrder.split('#'))[0]
#					$ValueOptionBootOrder = ($OptBootOrder.split('#'))[1]
#					Write-host "------ Vérification de l'option $NameOptionBootOrder"
#					add_log $log "------ Vérification de l'option $NameOptionBootOrder"
#					if ($ValueOptionBootOrder -like "*`+*") {
#						Write-Host "-------- Options multiples dans la valeur de la chaine d'option détecté..."
#						$ValueOptionBootOrderTemp = $null
#						$VTemp = $null
#						$Val = $ValueOptionBootOrder.split(',')
#						foreach ($v in $val) {
#							Write-Host "-------- Test valeur $v"
#							if ($v -like "*`+*") {
#								$v.split('`+') | foreach {
#									$OptionTest = (($_).replace(" Drive","")).trim()
#									Write-Host "---------- Test Option : $OptionTest"
#									$optionExistBootOrder = Get-BiosOptionExist -option $OptionTest -Manufacturer $Manufacturer
#									if ($optionExistBootOrder) {
#										Write-Host "---------- Option Trouvé : $OptionTest"
#										$VTemp = $_
#										break
#									} Else {
#										Write-Host "---------- Option $OptionTest non touvé"
#									}
#								}
#								$ValueOptionBootOrderTemp = $ValueOptionBootOrderTemp + $vtemp + ","	
#							} Else {
#								$ValueOptionBootOrderTemp = $ValueOptionBootOrderTemp + $v + ","
#							}
#						}
#						$ValueOptionBootOrder = $ValueOptionBootOrderTemp.trim(',')
#						Write-Host "-------- Valeur retenu : $ValueOptionBootOrder"
#					}
#					if ($Manufacturer -ne "Dell inc.") {
#						$optionExistBootOrder = Get-BiosOptionExist -option $NameOptionBootOrder -Manufacturer $Manufacturer
#					} Else {
#						$optionExistBootOrder = $true
#					}
#					if ($optionExistBootOrder -eq $true) {
#						$Etat_OptionBootOrder = Get-BiosBootOrderLegacy -Manufacturer $Manufacturer -Option $NameOptionBootOrder
#						if ($manufacturer -eq "Hewlett-packard") {
#							$Etat_OptionBootOrder = $Etat_OptionBootOrder.replace(' , ',',').trim()
#							if ($Etat_OptionBootOrder -notlike "$ValueOptionBootOrder`*") {
#								Write-host "------ Option $NameOptionBootOrder valeur trouvé : $Etat_OptionBootOrder"
#								Write-host "------ --> Valeur attendu : $ValueOptionBootOrder"
#								add_log $log "------ Option $NameOptionBootOrder valeur trouvé : $Etat_OptionBootOrder"
#								add_log $log "------ --> Valeur attendu : $ValueOptionBootOrder"
#								$Bool_Resultat_BootOrder = $false
#							} Else {
#								Write-host "------ Option $NameOptionBootOrder $Manufacturer bien positionné valeur : $Etat_OptionBootOrder"
#								add_log $log "------ Option $NameOptionBootOrder $Manufacturer bien positionné valeur : $Etat_OptionBootOrder"
#							}
#						} Else {
#							if ($Etat_OptionBootOrder -ne $ValueOptionBootOrder) {
#								Write-host "------ Option $NameOptionBootOrder valeur trouvé : $Etat_OptionBootOrder"
#								Write-host "------ --> Valeur attendu : $ValueOptionBootOrder"
#								add_log $log "------ Option $NameOptionBootOrder valeur trouvé : $Etat_OptionBootOrder"
#								add_log $log "------ --> Valeur attendu : $ValueOptionBootOrder"
#								$Bool_Resultat_BootOrder = $false
#							} Else {
#								Write-host "------ Option $NameOptionBootOrder bien positionné valeur : $Etat_OptionBootOrder"
#								add_log $log "------ Option $NameOptionBootOrder bien positionné valeur : $Etat_OptionBootOrder"
#							}
#						}
#					} else {
#						return "ERREUR : option(s) $NameOptionBootOrder non trouvé"
#					}
#				}
#			} Else {
#				return "INFO : Pas d'option valide trouvé dans le XML pour la verification du Boot Order"
#			}
#		}
#		
#		#Verification des options supplémentaire de Boot order
#		$Etat_Option_OtherBootOrder = Get-OptionTPM_IsSet -Manufacturer $Manufacturer -ListOptions $ListOtherBootOrderOptions
#		if ($Etat_Option_OtherBootOrder -match "ERREUR :") {
#			return $Etat_Option_OtherBootOrder
#		} Elseif ($Etat_Option_OtherBootOrder -match "INFO :") {
#			return $Etat_Option_OtherBootOrder
#		} Elseif ($Etat_Option_OtherBootOrder -eq $true) {
#			$Bool_Resultat_OtherBootOrder = $true
#		} Else {
#			$Bool_Resultat_OtherBootOrder = $false
#		}
#		
#		If (($Bool_Resultat_BootOrder -eq $True) -and ($Bool_Resultat_OtherBootOrder -eq $true)) {
#			return $true
#		} Else {
#			return $false
#		}
#	} Else { # Autres constructeurs
#		return "INFO : Constructeur non pris en charge"
#	}
#}
###############################################################################
# Fonction de paramétrage de l'ordre de Boot Legacy sur les ordinateurs HP, Dell et Lenovo
#function Set-TPMBiosBootOrderLegacy {
#	<#
#		.SYNOPSIS
#	    	Set Bios Boot Order legacy.
#		.DESCRIPTION
#			This function can be used to set the Bios Boot Order Legacy.
#		.EXAMPLE
#			Set-TPMBiosBootOrderLegacy -Manufacturer "Dell Inc." -ListOptionsBootOrder "BootOrder#Internal HDD,Onboard NIC"
#		.EXAMPLE
#			Set-TPMBiosBootOrderLegacy -computerName "computername.domain.fr" -cred (get-credential) -Manufacturer "Lenovo" -ListOptionsBootOrder "BootOrder#PCILan:HDD0" -ListOtherBootOrderOptions "NetworkBootOrder#HDD0:PCLAN"
#		.EXAMPLE
#			Set-TPMBiosBootOrderLegacy -computerName "computername.domain.fr" -manufacturer "Lenovo" -ListOptionsBootOrder "BootOrder#HDD0" -ListOtherBootOrderOptions "NetworkBoot#HDD0" -Password "Password" -cred (get-credential) 
#		.LINK
#		
#		.CONNEX LINK
#			
#	#>
#	
#	[CmdletBinding()]
#	[OutputType([string])]
#	Param 	(
#			# ComputerName, Type string, System to Get Bios option.
#        	[Parameter(Position=0,
#                   ValueFromPipeline=$true)]
#        	[ValidateScript({ if (-not(Test-Connection -ComputerName $_ -Quiet -Count 2)) { throw "Echec lors de la connection à $ComputerName.  S'il vous plaît assurer que le système est disponible." } else { $true} })]
#        	[string[]]
#        	$ComputerName = $env:COMPUTERNAME
#			,
#			# Manufacturer, Type String, Le constructeur.
#        	[Parameter(Mandatory=$true,
#                   Position=1)]
#			$Manufacturer
#			,
#			# ListOptionsBootOrder, Type String, La liste de valeur que doit prendre l'option de Boot order
#        	[Parameter(Position=2)]
#			$ListOptionsBootOrder = $null
#			,
#			# ListOtherBootOrderOptions, Type String, La liste de valeur que doit prendre les autres options de boot
#        	[Parameter(Position=3)]
#			$ListOtherBootOrderOptions = $null
#			,
#		 	# Password, Type string, La valeur du mot de passe actuel du Setup Password.
#        	[Parameter(Position=4)]
#        	[string]
#        	$PASSWORD = $null
#			,
#		 	# Cred, Type Credential, les authentifications de la commande.
#	    	[Parameter(Position=5)]
#			$cred = $null
#			
#			)
#	#Gestion des credentials
#	if ($cred -eq $null)
#	{
#		$CredentialParams = @{}
#	}
#	Elseif (($cred -ne $null) -and (($Computername -eq $env:COMPUTERNAME) -or ($computername -eq "localhost") -or ($computername -eq ".")))
#	{
#		$CredentialParams = @{}
#	}
#	Else
#	{
#		$CredentialParams = @{credential = $cred}
#	}
#			
#	#$HDDrive="M.2 SSD Drive",$HD="M.2 SSD",$HD_Boot="M.2 SSD boot"
#	#$HDDrive="PCIe/M.2 SSD Drive",$HD="PCIe/M.2 SSD",$HD_Boot="PCIe/M.2 SSD Boot"
#	#$HDDrive="mSATA Drive",$HD="mSATA",$HD_Boot="mSATA Boot"
#	<#if (($HD -ne $null) -and ($HD_boot -ne $null)) {
#		$hash_Boot = @{"$HD"="Enable";"$HD_Boot"="Enable";"Boot Mode"="Legacy";"Fast Boot"="Disable";`
#		"SD Card boot"="Disable";"Floppy boot"="Disable";"USB device boot"="Disable";"Customized Boot"="Disable";`
#		"PXE Internal NIC boot"="Enable";"PXE Internal IPV4 NIC boot"="Disable";"PXE Internal IPV6 NIC boot"="Disable"}#>
#		
#	#HP ou Lenovo
#	if (($Manufacturer -eq "Hewlett-Packard") -or ($Manufacturer -eq "LENOVO")) {
#		if (($ListOptionsBootOrder -ne $null) -and ($ListOptionsBootOrder -ne "")) {
#			
#			$Set_BootOrder = Set-optionTPM -pwd $PASSWORD -Manufacturer $Manufacturer -ListOptions $ListOptionsBootOrder
#			if ($Set_BootOrder -match "ERREUR :") {
#				return $Set_BootOrder
#			}
#		} Else {
#			Write-Host "---- INFO : Pas d'option de Boot Order défini"
#			add_log $log "---- INFO : Pas d'option de Boot Order défini"
#		}
#		
#		if (($ListOtherBootOrderOptions -ne $null) -and ($ListOtherBootOrderOptions -ne "")) {
#			$Set_OtherOptionBootOrder = Set-optionTPM -pwd $PASSWORD -Manufacturer $Manufacturer -ListOptions $ListOtherBootOrderOptions
#			if ($Set_OtherOptionBootOrder -match "ERREUR :") {
#				return $Set_OtherOptionBootOrder
#			}
#		} Else {
#			Write-Host "---- INFO : Pas d'option Supplémentaire pour le Boot Order à configurer"
#			add_log $log "---- INFO : Pas d'option Supplémentaire pour le Boot Order à configurer"
#		}
#	}
#	#Dell
#	Elseif ($Manufacturer -eq "Dell Inc.") 
#	{
#try 
#{
#    [string]$Liste_Boot_Order_enable = $null
#    [string]$Liste_Boot_Order_disable = $null
#    [array]$GetOpt = @()
#    [array]$GetOpt = cmd.exe /c """$LibPath\CCTK\cctk.exe"" bootorder"
#    if ($GetOpt)
#    {
#        $i = 3
#        while (($getopt[$i]) -notmatch "----------")
#        {
#                        $getopt[$i] = (($getopt[$i]) -replace "\s{2,}",";").trim(';')
#                        $deviceStatus = (($getopt[$i]).split(';'))[0].trim(';')
#                        $deviceNumber = (($getopt[$i]).split(';'))[1].trim(';')
#                        $devicetype = (($getopt[$i]).split(';'))[2].trim(';')
#                        $shortform = (($getopt[$i]).split(';'))[3].trim(';')
#                        $devicedescription = (($getopt[$i]).split(';'))[4].trim(';')
#                        if (($deviceStatus -eq "Enabled") -and ($ListOptionsBootOrder -match "$($shortform)")) 
#                        {
#                            [string]$Liste_Boot_Order_enable += $shortform + ","
#                        } 
#                        Elseif (($deviceStatus -eq "disabled") -and ($ListOptionsBootOrder -match "$($shortform)")) 
#                        {
#                            [string]$Liste_Boot_Order_enable += $shortform + ","
#                        }
#                        Else
#                        {
#                            [string]$Liste_Boot_Order_disable += $shortform + ","
#                        }     
#                        $i++
#        }
#        if ($Liste_Boot_Order_enable)
#        {
#                        $Liste_Boot_Order_enable = $Liste_Boot_Order_enable.trim(',')
#                        write-host "Liste enabled = $($Liste_Boot_Order_enable)"
#                    }
#                    Else
#                    {
#                        return "ERREUR : Aucun element Enabled trouvé dans la liste"
#                    }
#            
#                    if ($Liste_Boot_Order_disable) 
#                    {
#                        $Liste_Boot_Order_disable = $Liste_Boot_Order_disable.trim(',')
#                        write-host "Liste disabled = $($Liste_Boot_Order_disable)"
#                    }
#                    
#				
#		
#		if (($ListOptionsBootOrder -ne $null) -and ($ListOptionsBootOrder -ne "")) 
#		{
#				$ListDeviceBoot = ($ListOptionsBootOrder.split('#'))[1].trim()
#                if ($Liste_Boot_Order_enable)
#                {
#                    if ($Liste_Boot_Order_disable)
#                    {
#                        if ($password)
#                        {
#                            $Resultat_SetBootOrder = cmd.exe /c """$LibPath\CCTK\cctk.exe"" bootorder --sequence=$($ListDeviceBoot) --disabledevice=$($Liste_Boot_Order_disable) --enabledevice=$($Liste_Boot_Order_enable) --valsetuppwd=$($Password)"
#                        }
#                        else
#                        {
#                            $Resultat_SetBootOrder = cmd.exe /c """$LibPath\CCTK\cctk.exe"" bootorder --sequence=$($ListDeviceBoot) --disabledevice=$($Liste_Boot_Order_disable) --enabledevice=$($Liste_Boot_Order_enable)"
#                        }
#                    }
#                    else
#                    {
#                        if ($password)
#                        {
#                            $Resultat_SetBootOrder = cmd.exe /c """$LibPath\CCTK\cctk.exe"" bootorder --sequence=$($ListDeviceBoot) --enabledevice=$($Liste_Boot_Order_enable) --valsetuppwd=$($Password)"
#                        }
#                        else
#                        {
#                            $Resultat_SetBootOrder = cmd.exe /c """$LibPath\CCTK\cctk.exe"" bootorder --sequence=$($ListDeviceBoot) --enabledevice=$($Liste_Boot_Order_enable)"
#                        }
#                        
#                    }
#                }
#                Else
#                {
#                    if ($Liste_Boot_Order_disable)
#                    {
#                        if ($password)
#                        {
#                            $Resultat_SetBootOrder = cmd.exe /c """$LibPath\CCTK\cctk.exe"" bootorder --sequence=$($ListOptionsBootOrder) --disabledevice=$($Liste_Boot_Order_disable) --valsetuppwd=$($Password)"
#                        }
#                        else
#                        {
#                            [array]$Resultat_SetBootOrder = cmd.exe /c """$LibPath\CCTK\cctk.exe"" bootorder --sequence=$($ListDeviceBoot) --disabledevice=$($Liste_Boot_Order_disable)"
#                        }
#                        
#                    }
#                    else
#                    {
#                        if ($password)
#                        {
#                            $Resultat_SetBootOrder = cmd.exe /c """$LibPath\CCTK\cctk.exe"" bootorder --sequence=$($ListDeviceBoot) --valsetuppwd=$($Password)"
#                        }
#                        else
#                        {
#                            $Resultat_SetBootOrder = cmd.exe /c """$LibPath\CCTK\cctk.exe"" bootorder --sequence=$($ListDeviceBoot)"
#                        }
#                        
#                    }
#                }
#		} 
#		Else 
#		{
#			return "INFO : Aucune option valide trouvé dans le XML"
#		}
#        }
#				Else
#				{
#					return "ERREUR : Pas de liste de boot récuperé"
#				}
#                if ($Resultat_SetBootOrder)
#                {
#                    
#                    return $true
#                }
#                Else
#                {
#                    return $false
#                }
#			} 
#			catch 
#			{
#                return "ERREUR : $($_.exception.Message)"
#			}
#	}
#	Else 
#	{
#		return "INFO : Marque non géré par ce script"
#	}
#}
###############################################################################
# Fonction de validation et d'activation de la puce TPM
Function Set-ActivationTPM($PASSWORD,$Manufacturer,$ListeOptionsValidation,$ListeOptionsActivation) {  
	$BdRTagRedemarrage = "HKLM:\SOFTWARE\IT\PARAMETRAGE"
	Write-Host "-- OP : Verification Etat de validation de la puce TPM"
	add_log $log "-- OP : Verification Etat de validation de la puce TPM"
	$Etat_Validation_TPM = Get-TPMvalidation_IsSet -manufacturer $manufacturer -ListOptionsValidation $ListeOptionsValidation #Vérification de l'état de la puce TPM (Enable ou disable)
	if ($Etat_Validation_TPM -match "ERREUR :") 
	{
        Write-Host "-- $Etat_Validation_TPM"
		add_log $log "-- $Etat_Validation_TPM"
    } 
	Elseif ($Etat_Validation_TPM -match "INFO :") 
	{
		Write-Host "-- $Etat_Validation_TPM"
		add_log $log "-- $Etat_Validation_TPM"
        Write-Host "-- OP : Vérification de l'etat d'activation de la puce TPM"
		add_log $log "-- OP : Vérification de l'etat d'activation de la puce TPM"
		$Etat_Activation_TPM = Get-TPMActivation_IsSet -Manufacturer $Manufacturer -ListOptionsActivation $ListeOptionsActivation
		if (($Etat_Activation_TPM -match "ERREUR :") -or ($Etat_Activation_TPM -match "INFO :")) 
		{
			Write-Host "-- $Etat_Activation_TPM"
			add_log $log "-- $Etat_Activation_TPM"
		} 
		Elseif ($Etat_Activation_TPM -eq $true) { # La puce TPM est déjà Activé
			Write-Host "-- RES : La puce TPM est déjà activé"
			add_log $log "-- RES : La puce TPM est déjà activé"
			return $true
		}  
		Elseif (!$Etat_Activation_TPM) 
		{ # La puce TPM n'est pas Activé --> Activation
			Write-Host "-- RES : La puce TPM n'est pas activé"
			add_log $log "-- RES : La puce TPM n'est pas activé"
			Write-Host "-- OP : Activation de la puce TPM"
			add_log $log "-- OP : Activation de la puce TPM"
			$Activation_TPM = Set-TPMActivation -password $PASSWORD -Manufacturer $Manufacturer -ListOptionsActivation $ListeOptionsActivation
			if ($Activation_TPM -match "ERREUR :") 
			{
				Write-Host "-- $Activation_TPM"
				add_log $log "-- $Activation_TPM"
			} 
			Else 
			{
				$Etat_Activation_TPM = Get-TPMActivation_IsSet -Manufacturer $Manufacturer -ListOptionsActivation $ListeOptionsActivation
				if (($Etat_Activation_TPM -match "ERREUR :") -or ($Etat_Activation_TPM -match "INFO :")) 
				{
					Write-Host "-- $Etat_Activation_TPM"
					add_log $log "-- $Etat_Activation_TPM"
				} 
				Elseif ($Etat_Activation_TPM) 
				{
					Write-Host "-- RES : La puce TPM est maintenant bien activé"
					add_log $log "-- RES : La puce TPM est maintenant bien activé"
					return $true
				}  
				Elseif (!$Etat_Activation_TPM) 
				{
					Write-Host "-- RES : La puce TPM n'est tjrs pas validé, un redémarage est peut etre nécéssaire"
					add_log $log "-- RES : La puce TPM n'est tjrs pas validé, un redémarage est peut etre nécéssaire"
					return $false
				} 
				Else 
				{
					return "ERREUR : Erreur Inconnue lors de la verification de l'etat d'activation de la puce TPM"
				}
			}
		} 
		Else 
		{
			return "ERREUR : Erreur Inconnue lors de la l'activation de la puce TPM"
		} 
	} 
	ElseIf ($Etat_Validation_TPM) 
	{ # La puce TPM est déjà validé
		Write-Host "-- RES : La puce TPM est déjà validé"
		add_log $log "-- RES : La puce TPM est déjà validé"
		Write-Host "-- OP : Vérification de l'etat d'activation de la puce TPM"
		add_log $log "-- OP : Vérification de l'etat d'activation de la puce TPM"
		$Etat_Activation_TPM = Get-TPMActivation_IsSet -Manufacturer $Manufacturer -ListOptionsActivation $ListeOptionsActivation
		if (($Etat_Activation_TPM -match "ERREUR :") -or ($Etat_Activation_TPM -match "INFO :")) 
		{
			Write-Host "-- $Etat_Activation_TPM"
			add_log $log "-- $Etat_Activation_TPM"
		} 
		Elseif ($Etat_Activation_TPM) 
		{ # La puce TPM est déjà Activé
			Write-Host "-- RES : La puce TPM est déjà activé"
			add_log $log "-- RES : La puce TPM est déjà activé"
			return $true
		}  
		Elseif (!$Etat_Activation_TPM) 
		{ # La puce TPM n'est pas Activé --> Activation
			Write-Host "-- RES : La puce TPM n'est pas activé"
			add_log $log "-- RES : La puce TPM n'est pas activé"
			Write-Host "-- OP : Activation de la puce TPM"
			add_log $log "-- OP : Activation de la puce TPM"
			$Activation_TPM = Set-TPMActivation -password $PASSWORD -Manufacturer $Manufacturer -ListOptionsActivation $ListeOptionsActivation
			if ($Activation_TPM -match "ERREUR :") 
			{
				Write-Host "-- $Activation_TPM"
				add_log $log "-- $Activation_TPM"
			} 
			Else 
			{
				$Etat_Activation_TPM = Get-TPMActivation_IsSet -Manufacturer $Manufacturer -ListOptionsActivation $ListeOptionsActivation
				if (($Etat_Activation_TPM -match "ERREUR :") -or ($Etat_Activation_TPM -match "INFO :")) 
				{
					Write-Host "-- $Etat_Activation_TPM"
					add_log $log "-- $Etat_Activation_TPM"
				} 
				Elseif ($Etat_Activation_TPM) 
				{
					Write-Host "-- RES : La puce TPM est maintenant bien activé"
					add_log $log "-- RES : La puce TPM est maintenant bien activé"
					return $true
				}  
				Elseif (!$Etat_Activation_TPM) 
				{
					Write-Host "-- RES : La puce TPM n'est tjrs pas validé, un redémarage est peut etre nécéssaire"
					add_log $log "-- RES : La puce TPM n'est tjrs pas validé, un redémarage est peut etre nécéssaire"
					return $false
				} 
				Else 
				{
					return "ERREUR : Erreur Inconnue lors de la verification de l'etat d'activation de la puce TPM"
				}
			}
		} 
		Else 
		{
			return "ERREUR : Erreur Inconnue lors de la l'activation de la puce TPM"
		}
	} 
	ElseIf (!$Etat_Validation_TPM) 
	{ # La puce TPM n'est pas validé
		Write-Host "-- RES : La puce TPM n'est pas Validé"
		add_log $log "-- RES : La puce TPM n'est pas Validé"
		Write-Host "-- OP : Validation de la puce TPM"
		add_log $log "-- OP : Validation de la puce TPM"
        $Validation_TPM = Set-TPMValidation -password $PASSWORD -Manufacturer $Manufacturer -ListOptionsValidation $ListeOptionsValidation
		if (($Validation_TPM -match "ERREUR :") -or ($Validation_TPM -match "INFO :")) 
		{
			Write-Host "-- $Validation_TPM"
			add_log $log "-- $Validation_TPM"
		} 
		Else 
		{
			#Tag Clé de registre pour Redemarrage
			if (Test-Path $BdRTagRedemarrage)
			{
				New-ItemProperty -Path $BdRTagRedemarrage -Name NEED_RESTART -PropertyType dword -Value "1" -force | out-null
			}
			#Activation
			$Etat_Validation_TPM = Get-TPMvalidation_IsSet -manufacturer $manufacturer -ListOptionsValidation $ListeOptionsValidation # Vérification de l'état de la puce TPM (Enable ou disable)
			if (($Etat_Validation_TPM -match "ERREUR :") -or ($Etat_Validation_TPM -match "INFO :")) 
			{
				Write-Host "-- $Etat_Validation_TPM"
				add_log $log "-- $Etat_Validation_TPM"
			} 
			ElseIf ($Etat_Validation_TPM) 
			{ # La puce TPM est déjà validé
				Write-Host "-- RES : La puce TPM est validé"
				add_log $log "-- RES : La puce TPM est validé"
				Write-Host "-- OP : Verification etat d'activation de la puce TPM"
				add_log $log "-- OP : Verification etat d'activation de la puce TPM"
				$Etat_Activation_TPM = Get-TPMActivation_IsSet -Manufacturer $Manufacturer -ListOptionsActivation $ListeOptionsActivation
				if (($Etat_Activation_TPM -match "ERREUR :") -or ($Etat_Activation_TPM -match "INFO :")) 
				{
					Write-Host "-- $Etat_Activation_TPM"
					add_log $log "-- $Etat_Activation_TPM"
				} 
				Elseif ($Etat_Activation_TPM) 
				{ # La puce TPM est déjà Activé
					Write-Host "-- RES : La puce TPM est activé"
					add_log $log "-- RES : La puce TPM est activé"
					return $true
				}  
				Elseif (!$Etat_Activation_TPM) 
				{ # La puce TPM n'est pas Activé --> Activation
					Write-Host "-- OP : Activation de la puce TPM"
					add_log $log "-- OP : Activation de la puce TPM"
					$Activation_TPM = Set-TPMActivation -password $PASSWORD -Manufacturer $Manufacturer
					if (($Activation_TPM -match "ERREUR :")  -or ($Activation_TPM -match "INFO :")) 
					{
						Write-Host "-- $Activation_TPM"
						add_log $log "-- $Activation_TPM"
					} 
					Else 
					{
						$Etat_Activation_TPM = Get-TPMActivation_IsSet -Manufacturer $Manufacturer -ListOptionsActivation $ListeOptionsActivation
						if (($Etat_Activation_TPM -match "ERREUR :") -or ($Etat_Activation_TPM -match "INFO :")) 
						{
							Write-Host "-- $Etat_Activation_TPM"
							add_log $log "-- $Etat_Activation_TPM"
						} 
						Elseif ($Etat_Activation_TPM) 
						{
							Write-Host "-- RES : La puce TPM est activé"
							add_log $log "-- RES : La puce TPM est activé"
							return $true
						}  
						Elseif (!$Etat_Activation_TPM) 
						{
							Write-Host "-- RES : La puce TPM n'est tjrs pas validé"
							add_log $log "-- RES : La puce TPM n'est tjrs pas validé"
							return $false
						} 
						Else 
						{
							return "ERREUR : Erreur Inconnue lors de la verification de l'etat d'activation de la puce TPM"
						}
					}
				} 
				Else 
				{
					return "ERREUR : Erreur Inconnue lors de la l'activation de la puce TPM"
				}
			}	
		}
	} 
	Else 
	{
		return "ERREUR : Erreur inconnue lors du processus d'activation TPM"
	}
}