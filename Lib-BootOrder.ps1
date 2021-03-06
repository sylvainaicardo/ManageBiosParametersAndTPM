###############################################################################
# Fonction générique pour le parametrage d'une option Boot
Function Set-OptionBoot ($Pwd,$Manufacturer,$ListOptions) {
    
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
								$OptionTest = ((($_).replace(" Hard","")).replace(" Drive","")).trim()
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
# Fonction donnant l'etat de Configuration de l'ordre de démarrage du BIOS Legacy
Function Get-BiosBootOrderLegacy_IsSet ($Manufacturer,$ListOptionsBootOrder,$ListOtherBootOrderOptions)
{    
	#HP -->
	#Dell --> bootorder#hdd,embnic
	#Lenovo --> BootOrder#HDD0:PCLAN;NetworkBootOrder#HDD0:PCLAN ou BootOrder#HDD0;NetworkBoot#HDD0
	
	if (($manufacturer -eq "Hewlett-Packard") -or ($manufacturer -eq "Dell Inc.") -or ($manufacturer -eq "LENOVO")) {
		$Bool_Resultat_BootOrder = $true 
		if (($ListOptionsBootOrder -ne $null) -and ($ListOptionsBootOrder -ne "")) {
			[array]$TabOptionsBootOrder = $ListOptionsBootOrder.split(';')
			if ($TabOptionsBootOrder.count -gt 0) {
				foreach ($OptBootOrder in $TabOptionsBootOrder) {
					$NameOptionBootOrder = ($OptBootOrder.split('#'))[0]
					$ValueOptionBootOrder = ($OptBootOrder.split('#'))[1]
					Write-host "------ Vérification de l'option $NameOptionBootOrder"
					add_log $log "------ Vérification de l'option $NameOptionBootOrder"
					if ($ValueOptionBootOrder -like "*`+*") {
						Write-Host "-------- Options multiples dans la valeur de la chaine d'option détecté..."
						$ValueOptionBootOrderTemp = $null
						$VTemp = $null
						$Val = $ValueOptionBootOrder.split(',')
						foreach ($v in $val) {
							Write-Host "-------- Test valeur $v"
							if ($v -like "*`+*") {
								$v.split('`+') | foreach {
									$OptionTest = ((($_).replace(" Hard","")).replace(" Drive","")).trim()
									Write-Host "---------- Test Option : $OptionTest"
									$optionExistBootOrder = Get-BiosOptionExist -option $OptionTest -Manufacturer $Manufacturer
									if ($optionExistBootOrder) {
										Write-Host "---------- Option Trouvé : $OptionTest"
										$VTemp = $_
										break
									} Else {
										Write-Host "---------- Option $OptionTest non touvé"
									}
								}
								$ValueOptionBootOrderTemp = $ValueOptionBootOrderTemp + $vtemp + ","	
							} Else {
								$ValueOptionBootOrderTemp = $ValueOptionBootOrderTemp + $v + ","
							}
						}
						$ValueOptionBootOrder = $ValueOptionBootOrderTemp.trim(',')
						Write-Host "-------- Valeur retenu : $ValueOptionBootOrder"
					}
					if ($Manufacturer -ne "Dell inc.") {
						$optionExistBootOrder = Get-BiosOptionExist -option $NameOptionBootOrder -Manufacturer $Manufacturer
					} Else {
						$optionExistBootOrder = $true
					}
					if ($optionExistBootOrder -eq $true) {
						$Etat_OptionBootOrder = Get-BiosBootOrderLegacy -Manufacturer $Manufacturer -Option $NameOptionBootOrder
						if ($manufacturer -eq "Hewlett-packard") {
							$Etat_OptionBootOrder = (($Etat_OptionBootOrder.replace(' ,',',')).replace(', ',',')).trim()
							if ($Etat_OptionBootOrder -notlike "$ValueOptionBootOrder`*") {
								Write-host "------ Option $NameOptionBootOrder valeur trouvé : $Etat_OptionBootOrder"
								Write-host "------ --> Valeur attendu : $ValueOptionBootOrder"
								add_log $log "------ Option $NameOptionBootOrder valeur trouvé : $Etat_OptionBootOrder"
								add_log $log "------ --> Valeur attendu : $ValueOptionBootOrder"
								$Bool_Resultat_BootOrder = $false
							} Else {
								Write-host "------ Option $NameOptionBootOrder $Manufacturer bien positionné valeur : $Etat_OptionBootOrder"
								add_log $log "------ Option $NameOptionBootOrder $Manufacturer bien positionné valeur : $Etat_OptionBootOrder"
							}
						} Else {
							if ($Etat_OptionBootOrder -ne $ValueOptionBootOrder) {
								Write-host "------ Option $NameOptionBootOrder valeur trouvé : $Etat_OptionBootOrder"
								Write-host "------ --> Valeur attendu : $ValueOptionBootOrder"
								add_log $log "------ Option $NameOptionBootOrder valeur trouvé : $Etat_OptionBootOrder"
								add_log $log "------ --> Valeur attendu : $ValueOptionBootOrder"
								$Bool_Resultat_BootOrder = $false
							} Else {
								Write-host "------ Option $NameOptionBootOrder bien positionné valeur : $Etat_OptionBootOrder"
								add_log $log "------ Option $NameOptionBootOrder bien positionné valeur : $Etat_OptionBootOrder"
							}
						}
					} else {
						return "ERREUR : option(s) $NameOptionBootOrder non trouvé"
					}
				}
			} Else {
				return "INFO : Pas d'option valide trouvé dans le XML pour la verification du Boot Order"
			}
		}
		
		#Verification des options supplémentaire de Boot order
		$Etat_Option_OtherBootOrder = Get-OptionTPM_IsSet -Manufacturer $Manufacturer -ListOptions $ListOtherBootOrderOptions
		if ($Etat_Option_OtherBootOrder -match "ERREUR :") {
			return $Etat_Option_OtherBootOrder
		} Elseif ($Etat_Option_OtherBootOrder -match "INFO :") {
			return $Etat_Option_OtherBootOrder
		} Elseif ($Etat_Option_OtherBootOrder -eq $true) {
			$Bool_Resultat_OtherBootOrder = $true
		} Else {
			$Bool_Resultat_OtherBootOrder = $false
		}
		
		If (($Bool_Resultat_BootOrder -eq $True) -and ($Bool_Resultat_OtherBootOrder -eq $true)) {
			return $true
		} Else {
			return $false
		}
	} Else { # Autres constructeurs
		return "INFO : Constructeur non pris en charge"
	}
}
###############################################################################
# Fonction donnant l'etat de Configuration de l'ordre de démarrage du BIOS Legacy
Function Get-BiosBootOrderUEFI_IsSet ($Manufacturer,$ListOptionsBootOrder,$ListOtherBootOrderOptions)
{    
	#HP -->
	#Dell --> bootorder#hdd,embnic
	#Lenovo --> BootOrder#HDD0:PCLAN;NetworkBootOrder#HDD0:PCLAN ou BootOrder#HDD0;NetworkBoot#HDD0
	
	if (($manufacturer -eq "Hewlett-Packard") -or ($manufacturer -eq "Dell Inc.") -or ($manufacturer -eq "LENOVO")) {
		$Bool_Resultat_BootOrder = $true 
		if (($ListOptionsBootOrder -ne $null) -and ($ListOptionsBootOrder -ne "")) {
			[array]$TabOptionsBootOrder = $ListOptionsBootOrder.split(';')
			if ($TabOptionsBootOrder.count -gt 0) {
				foreach ($OptBootOrder in $TabOptionsBootOrder) {
					$NameOptionBootOrder = ($OptBootOrder.split('#'))[0]
					$ValueOptionBootOrder = ($OptBootOrder.split('#'))[1]
					Write-host "------ Vérification de l'option $NameOptionBootOrder"
					add_log $log "------ Vérification de l'option $NameOptionBootOrder"
					if ($ValueOptionBootOrder -like "*`+*") {
						Write-Host "-------- Options multiples dans la valeur de la chaine d'option détecté..."
						$ValueOptionBootOrderTemp = $null
						$VTemp = $null
						$Val = $ValueOptionBootOrder.split(',')
						foreach ($v in $val) {
							Write-Host "-------- Test valeur $v"
							if ($v -like "*`+*") {
								$v.split('`+') | foreach {
									$OptionTest = ((($_).replace(" Hard","")).replace(" Drive","")).trim()
									Write-Host "---------- Test Option : $OptionTest"
									$optionExistBootOrder = Get-BiosOptionExist -option $OptionTest -Manufacturer $Manufacturer
									if ($optionExistBootOrder) {
										Write-Host "---------- Option Trouvé : $OptionTest"
										$VTemp = $_
										#break
									} Else {
										Write-Host "---------- Option $OptionTest non touvé"
									}
								}
								$ValueOptionBootOrderTemp = $ValueOptionBootOrderTemp + $vtemp + ","	
							} Else {
								$ValueOptionBootOrderTemp = $ValueOptionBootOrderTemp + $v + ","
							}
						}
						$ValueOptionBootOrder = $ValueOptionBootOrderTemp.trim(',')
						Write-Host "-------- Valeur retenu : $ValueOptionBootOrder"
					}
					if ($Manufacturer -ne "Dell inc.") {
						$optionExistBootOrder = Get-BiosOptionExist -option $NameOptionBootOrder -Manufacturer $Manufacturer
					} Else {
						$optionExistBootOrder = $true
					}
					if ($optionExistBootOrder -eq $true) {
						$Etat_OptionBootOrder = Get-BiosBootOrderUEFI -Manufacturer $Manufacturer -Option $NameOptionBootOrder
						if ($manufacturer -eq "Hewlett-packard") {
							$Etat_OptionBootOrder = (($Etat_OptionBootOrder.replace(' ,',',')).replace(', ',',')).trim()
							if ($Etat_OptionBootOrder -notlike "$ValueOptionBootOrder`*") {
								Write-host "------ Option $NameOptionBootOrder valeur trouvé : $Etat_OptionBootOrder"
								Write-host "------ --> Valeur attendu : $ValueOptionBootOrder"
								add_log $log "------ Option $NameOptionBootOrder valeur trouvé : $Etat_OptionBootOrder"
								add_log $log "------ --> Valeur attendu : $ValueOptionBootOrder"
								$Bool_Resultat_BootOrder = $false
							} Else {
								Write-host "------ Option $NameOptionBootOrder $Manufacturer bien positionné valeur : $Etat_OptionBootOrder"
								add_log $log "------ Option $NameOptionBootOrder $Manufacturer bien positionné valeur : $Etat_OptionBootOrder"
							}
						} Else {
							if ($Etat_OptionBootOrder -ne $ValueOptionBootOrder) {
								Write-host "------ Option $NameOptionBootOrder valeur trouvé : $Etat_OptionBootOrder"
								Write-host "------ --> Valeur attendu : $ValueOptionBootOrder"
								add_log $log "------ Option $NameOptionBootOrder valeur trouvé : $Etat_OptionBootOrder"
								add_log $log "------ --> Valeur attendu : $ValueOptionBootOrder"
								$Bool_Resultat_BootOrder = $false
							} Else {
								Write-host "------ Option $NameOptionBootOrder bien positionné valeur : $Etat_OptionBootOrder"
								add_log $log "------ Option $NameOptionBootOrder bien positionné valeur : $Etat_OptionBootOrder"
							}
						}
					} else {
						return "ERREUR : option(s) $NameOptionBootOrder non trouvé"
					}
				}
			} Else {
				return "INFO : Pas d'option valide trouvé dans le XML pour la verification du Boot Order"
			}
		}
		
		#Verification des options supplémentaire de Boot order
		$Etat_Option_OtherBootOrder = Get-OptionTPM_IsSet -Manufacturer $Manufacturer -ListOptions $ListOtherBootOrderOptions
		if ($Etat_Option_OtherBootOrder -match "ERREUR :") {
			return $Etat_Option_OtherBootOrder
		} Elseif ($Etat_Option_OtherBootOrder -match "INFO :") {
			return $Etat_Option_OtherBootOrder
		} Elseif ($Etat_Option_OtherBootOrder -eq $true) {
			$Bool_Resultat_OtherBootOrder = $true
		} Else {
			$Bool_Resultat_OtherBootOrder = $false
		}
		
		If (($Bool_Resultat_BootOrder -eq $True) -and ($Bool_Resultat_OtherBootOrder -eq $true)) {
			return $true
		} Else {
			return $false
		}
	} Else { # Autres constructeurs
		return "INFO : Constructeur non pris en charge"
	}
}
###############################################################################
# Fonction de paramétrage de l'ordre de Boot Legacy
function Set-BiosBootOrderLegacy {
	<#
		.SYNOPSIS
	    	Set Bios Boot Order legacy.
		.DESCRIPTION
			This function can be used to set the Bios Boot Order Legacy.
		.EXAMPLE
			Set-TPMBiosBootOrderLegacy -Manufacturer "Dell Inc." -ListOptionsBootOrder "BootOrder#Internal HDD,Onboard NIC"
		.EXAMPLE
			Set-TPMBiosBootOrderLegacy -computerName "computername.domain.fr" -cred (get-credential) -Manufacturer "Lenovo" -ListOptionsBootOrder "BootOrder#PCILan:HDD0" -ListOtherBootOrderOptions "NetworkBootOrder#HDD0:PCLAN"
		.EXAMPLE
			Set-TPMBiosBootOrderLegacy -computerName "computername.domain.fr" -manufacturer "Lenovo" -ListOptionsBootOrder "BootOrder#HDD0" -ListOtherBootOrderOptions "NetworkBoot#HDD0" -Password "Password" -cred (get-credential) 
		.LINK
		
		.CONNEX LINK
			
	#>
	
	[CmdletBinding()]
	[OutputType([string])]
	Param 	(
			# ComputerName, Type string, System to Get Bios option.
        	[Parameter(Position=0,
                   ValueFromPipeline=$true)]
        	[ValidateScript({ if (-not(Test-Connection -ComputerName $_ -Quiet -Count 2)) { throw "Echec lors de la connection à $ComputerName.  S'il vous plaît assurer que le système est disponible." } else { $true} })]
        	[string[]]
        	$ComputerName = $env:COMPUTERNAME
			,
			# Manufacturer, Type String, Le constructeur.
        	[Parameter(Mandatory=$true,
                   Position=1)]
			$Manufacturer
			,
			# ListOptionsBootOrder, Type String, La liste de valeur que doit prendre l'option de Boot order
        	[Parameter(Position=2)]
			$ListOptionsBootOrder = $null
			,
			# ListOtherBootOrderOptions, Type String, La liste de valeur que doit prendre les autres options de boot
        	[Parameter(Position=3)]
			$ListOtherBootOrderOptions = $null
			,
		 	# Password, Type string, La valeur du mot de passe actuel du Setup Password.
        	[Parameter(Position=4)]
        	[string]
        	$PASSWORD = $null
			,
		 	# Cred, Type Credential, les authentifications de la commande.
	    	[Parameter(Position=5)]
			$cred = $null
			
			)
	#Gestion des credentials
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
			
	#$HDDrive="M.2 SSD Drive",$HD="M.2 SSD",$HD_Boot="M.2 SSD boot"
	#$HDDrive="PCIe/M.2 SSD Drive",$HD="PCIe/M.2 SSD",$HD_Boot="PCIe/M.2 SSD Boot"
	#$HDDrive="mSATA Drive",$HD="mSATA",$HD_Boot="mSATA Boot"
	<#if (($HD -ne $null) -and ($HD_boot -ne $null)) {
		$hash_Boot = @{"$HD"="Enable";"$HD_Boot"="Enable";"Boot Mode"="Legacy";"Fast Boot"="Disable";`
		"SD Card boot"="Disable";"Floppy boot"="Disable";"USB device boot"="Disable";"Customized Boot"="Disable";`
		"PXE Internal NIC boot"="Enable";"PXE Internal IPV4 NIC boot"="Disable";"PXE Internal IPV6 NIC boot"="Disable"}#>
		
	#HP ou Lenovo
	if (($Manufacturer -eq "Hewlett-Packard") -or ($Manufacturer -eq "LENOVO")) {
		if (($ListOptionsBootOrder -ne $null) -and ($ListOptionsBootOrder -ne "")) {
			
			$Set_BootOrder = Set-OptionBoot -pwd $PASSWORD -Manufacturer $Manufacturer -ListOptions $ListOptionsBootOrder
			if ($Set_BootOrder -match "ERREUR :") {
				return $Set_BootOrder
			}
		} Else {
			Write-Host "---- INFO : Pas d'option de Boot Order défini"
			add_log $log "---- INFO : Pas d'option de Boot Order défini"
		}
		
		if (($ListOtherBootOrderOptions -ne $null) -and ($ListOtherBootOrderOptions -ne "")) {
			$Set_OtherOptionBootOrder = Set-OptionBoot -pwd $PASSWORD -Manufacturer $Manufacturer -ListOptions $ListOtherBootOrderOptions
			if ($Set_OtherOptionBootOrder -match "ERREUR :") {
				return $Set_OtherOptionBootOrder
			}
		} Else {
			Write-Host "---- INFO : Pas d'option Supplémentaire pour le Boot Order à configurer"
			add_log $log "---- INFO : Pas d'option Supplémentaire pour le Boot Order à configurer"
		}
	}
	#Dell
	Elseif ($Manufacturer -eq "Dell Inc.") 
	{
		try 
		{
		    [string]$Liste_Boot_Order_enable = $null
		    [string]$Liste_Boot_Order_disable = $null
		    [array]$GetOpt = @()
		    [array]$GetOpt = cmd.exe /c """$LibPath\CCTK\cctk.exe"" bootorder"
		    if ($GetOpt)
		    {
		        $i = 3
		        while (($getopt[$i]) -notmatch "----------")
		        {
                    $getopt[$i] = (($getopt[$i]) -replace "\s{2,}",";").trim(';')
                    $deviceStatus = (($getopt[$i]).split(';'))[0].trim(';')
                    $deviceNumber = (($getopt[$i]).split(';'))[1].trim(';')
                    $devicetype = (($getopt[$i]).split(';'))[2].trim(';')
                    $shortform = (($getopt[$i]).split(';'))[3].trim(';')
                    $devicedescription = (($getopt[$i]).split(';'))[4].trim(';')
                    if (($deviceStatus -eq "Enabled") -and ($ListOptionsBootOrder -match "$($shortform)")) 
                    {
                        [string]$Liste_Boot_Order_enable += $shortform + ","
                    } 
                    Elseif (($deviceStatus -eq "disabled") -and ($ListOptionsBootOrder -match "$($shortform)")) 
                    {
                        [string]$Liste_Boot_Order_enable += $shortform + ","
                    }
                    Else
                    {
                        [string]$Liste_Boot_Order_disable += $shortform + ","
                    }     
                    $i++
        		}
		        if ($Liste_Boot_Order_enable)
		        {
					$Liste_Boot_Order_enable = $Liste_Boot_Order_enable.trim(',')
					write-host "Liste enabled = $($Liste_Boot_Order_enable)"
                }
                Else
                {
                    return "ERREUR : Aucun element Enabled trouvé dans la liste"
                }
            
                if ($Liste_Boot_Order_disable) 
                {
                    $Liste_Boot_Order_disable = $Liste_Boot_Order_disable.trim(',')
                    write-host "Liste disabled = $($Liste_Boot_Order_disable)"
                }
  
				if (($ListOptionsBootOrder -ne $null) -and ($ListOptionsBootOrder -ne "")) 
				{
					$ListDeviceBoot = ($ListOptionsBootOrder.split('#'))[1].trim()
	                if ($Liste_Boot_Order_enable)
	                {
	                    if ($Liste_Boot_Order_disable)
	                    {
	                        if ($password)
	                        {
	                            $Resultat_SetBootOrder = cmd.exe /c """$LibPath\CCTK\cctk.exe"" bootorder --sequence=$($ListDeviceBoot) --disabledevice=$($Liste_Boot_Order_disable) --enabledevice=$($Liste_Boot_Order_enable) --valsetuppwd=$($Password)"
	                        }
	                        else
	                        {
	                            $Resultat_SetBootOrder = cmd.exe /c """$LibPath\CCTK\cctk.exe"" bootorder --sequence=$($ListDeviceBoot) --disabledevice=$($Liste_Boot_Order_disable) --enabledevice=$($Liste_Boot_Order_enable)"
	                        }
	                    }
	                    else
	                    {
	                        if ($password)
	                        {
	                            $Resultat_SetBootOrder = cmd.exe /c """$LibPath\CCTK\cctk.exe"" bootorder --sequence=$($ListDeviceBoot) --enabledevice=$($Liste_Boot_Order_enable) --valsetuppwd=$($Password)"
	                        }
	                        else
	                        {
	                            $Resultat_SetBootOrder = cmd.exe /c """$LibPath\CCTK\cctk.exe"" bootorder --sequence=$($ListDeviceBoot) --enabledevice=$($Liste_Boot_Order_enable)"
	                        }
                    	}
	                }
	                Else
	                {
	                    if ($Liste_Boot_Order_disable)
	                    {
	                        if ($password)
	                        {
	                            $Resultat_SetBootOrder = cmd.exe /c """$LibPath\CCTK\cctk.exe"" bootorder --sequence=$($ListOptionsBootOrder) --disabledevice=$($Liste_Boot_Order_disable) --valsetuppwd=$($Password)"
	                        }
	                        else
	                        {
	                            [array]$Resultat_SetBootOrder = cmd.exe /c """$LibPath\CCTK\cctk.exe"" bootorder --sequence=$($ListDeviceBoot) --disabledevice=$($Liste_Boot_Order_disable)"
	                        }
	                        
	                    }
	                    else
	                    {
	                        if ($password)
	                        {
	                            $Resultat_SetBootOrder = cmd.exe /c """$LibPath\CCTK\cctk.exe"" bootorder --sequence=$($ListDeviceBoot) --valsetuppwd=$($Password)"
	                        }
	                        else
	                        {
	                            $Resultat_SetBootOrder = cmd.exe /c """$LibPath\CCTK\cctk.exe"" bootorder --sequence=$($ListDeviceBoot)"
	                        }
	                        
	                    }
	                }
				} 
				Else 
				{
					return "INFO : Aucune option valide trouvé dans le XML"
				}
			}
			Else
			{
				return "ERREUR : Pas de liste de boot récuperé"
			}
            if ($Resultat_SetBootOrder)
            {
                
                return $true
            }
            Else
            {
                return $false
            }
		} 
		catch 
		{
            return "ERREUR : $($_.exception.Message)"
		}
	}
	Else 
	{
		return "INFO : Marque non géré par ce script"
	}
}
###############################################################################
# Fonction de paramétrage de l'ordre de Boot UEFI
function Set-BiosBootOrderUEFI {
	<#
		.SYNOPSIS
	    	Set Bios Boot Order legacy.
		.DESCRIPTION
			This function can be used to set the Bios Boot Order Legacy.
		.EXAMPLE
			Set-TPMBiosBootOrderUEFI -Manufacturer "Dell Inc." -ListOptionsBootOrder "BootOrder#Internal HDD,Onboard NIC"
		.EXAMPLE
			Set-TPMBiosBootOrderUEFI -computerName "computername.domain.fr" -cred (get-credential) -Manufacturer "Lenovo" -ListOptionsBootOrder "BootOrder#PCILan:HDD0" -ListOtherBootOrderOptions "NetworkBootOrder#HDD0:PCLAN"
		.EXAMPLE
			Set-TPMBiosBootOrderUEFI -computerName "computername.domain.fr" -manufacturer "Lenovo" -ListOptionsBootOrder "BootOrder#HDD0" -ListOtherBootOrderOptions "NetworkBoot#HDD0" -Password "Password" -cred (get-credential) 
		.LINK
		
		.CONNEX LINK
			
	#>
	
	[CmdletBinding()]
	[OutputType([string])]
	Param 	(
			# ComputerName, Type string, System to Get Bios option.
        	[Parameter(Position=0,
                   ValueFromPipeline=$true)]
        	[ValidateScript({ if (-not(Test-Connection -ComputerName $_ -Quiet -Count 2)) { throw "Echec lors de la connection à $ComputerName.  S'il vous plaît assurer que le système est disponible." } else { $true} })]
        	[string[]]
        	$ComputerName = $env:COMPUTERNAME
			,
			# Manufacturer, Type String, Le constructeur.
        	[Parameter(Mandatory=$true,
                   Position=1)]
			$Manufacturer
			,
			# ListOptionsBootOrder, Type String, La liste de valeur que doit prendre l'option de Boot order
        	[Parameter(Position=2)]
			$ListOptionsBootOrder = $null
			,
			# ListOtherBootOrderOptions, Type String, La liste de valeur que doit prendre les autres options de boot
        	[Parameter(Position=3)]
			$ListOtherBootOrderOptions = $null
			,
		 	# Password, Type string, La valeur du mot de passe actuel du Setup Password.
        	[Parameter(Position=4)]
        	[string]
        	$PASSWORD = $null
			,
		 	# Cred, Type Credential, les authentifications de la commande.
	    	[Parameter(Position=5)]
			$cred = $null
			
			)
	#Gestion des credentials
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
			
	#$HDDrive="M.2 SSD Drive",$HD="M.2 SSD",$HD_Boot="M.2 SSD boot"
	#$HDDrive="PCIe/M.2 SSD Drive",$HD="PCIe/M.2 SSD",$HD_Boot="PCIe/M.2 SSD Boot"
	#$HDDrive="mSATA Drive",$HD="mSATA",$HD_Boot="mSATA Boot"
	<#if (($HD -ne $null) -and ($HD_boot -ne $null)) {
		$hash_Boot = @{"$HD"="Enable";"$HD_Boot"="Enable";"Boot Mode"="Legacy";"Fast Boot"="Disable";`
		"SD Card boot"="Disable";"Floppy boot"="Disable";"USB device boot"="Disable";"Customized Boot"="Disable";`
		"PXE Internal NIC boot"="Enable";"PXE Internal IPV4 NIC boot"="Disable";"PXE Internal IPV6 NIC boot"="Disable"}#>
		
	#HP ou Lenovo
	if (($Manufacturer -eq "Hewlett-Packard") -or ($Manufacturer -eq "LENOVO")) 
	{
		if (($ListOptionsBootOrder -ne $null) -and ($ListOptionsBootOrder -ne "")) {
			
			$Set_BootOrder = Set-OptionBoot -pwd $PASSWORD -Manufacturer $Manufacturer -ListOptions $ListOptionsBootOrder
			Write-Host "Resultat operation set : $Set_BootOrder"
			if ($Set_BootOrder -match "ERREUR :") {
				return $Set_BootOrder
			}
		} Else {
			Write-Host "---- INFO : Pas d'option de Boot Order défini"
			add_log $log "---- INFO : Pas d'option de Boot Order défini"
		}
		
		if (($ListOtherBootOrderOptions -ne $null) -and ($ListOtherBootOrderOptions -ne "")) {
			$Set_OtherOptionBootOrder = Set-OptionBoot -pwd $PASSWORD -Manufacturer $Manufacturer -ListOptions $ListOtherBootOrderOptions
			if ($Set_OtherOptionBootOrder -match "ERREUR :") {
				return $Set_OtherOptionBootOrder
			}
		} Else {
			Write-Host "---- INFO : Pas d'option Supplémentaire pour le Boot Order à configurer"
			add_log $log "---- INFO : Pas d'option Supplémentaire pour le Boot Order à configurer"
		}
	}
	#Dell
	Elseif ($Manufacturer -eq "Dell Inc.") 
	{
		try 
		{
		    [string]$Liste_Boot_Order_enable = $null
		    [string]$Liste_Boot_Order_disable = $null
		    [array]$GetOpt = @()
		    [array]$GetOpt = cmd.exe /c """$LibPath\CCTK\cctk.exe"" bootorder"
		    if ($GetOpt)
		    {
		        $i = 3
		        while (($getopt[$i]) -notmatch "----------")
		        {
		                        $getopt[$i] = (($getopt[$i]) -replace "\s{2,}",";").trim(';')
		                        $deviceStatus = (($getopt[$i]).split(';'))[0].trim(';')
		                        $deviceNumber = (($getopt[$i]).split(';'))[1].trim(';')
		                        $devicetype = (($getopt[$i]).split(';'))[2].trim(';')
		                        $shortform = (($getopt[$i]).split(';'))[3].trim(';')
		                        $devicedescription = (($getopt[$i]).split(';'))[4].trim(';')
		                        if (($deviceStatus -eq "Enabled") -and ($ListOptionsBootOrder -match "$($shortform)")) 
		                        {
		                            [string]$Liste_Boot_Order_enable += $shortform + ","
		                        } 
		                        Elseif (($deviceStatus -eq "disabled") -and ($ListOptionsBootOrder -match "$($shortform)")) 
		                        {
		                            [string]$Liste_Boot_Order_enable += $shortform + ","
		                        }
		                        Else
		                        {
		                            [string]$Liste_Boot_Order_disable += $shortform + ","
		                        }     
		                        $i++
		        }
		        
				if ($Liste_Boot_Order_enable)
		        {
		            $Liste_Boot_Order_enable = $Liste_Boot_Order_enable.trim(',')
		            write-host "Liste enabled = $($Liste_Boot_Order_enable)"
		        }
		        Else
		        {
		            return "ERREUR : Aucun element Enabled trouvé dans la liste"
		        }

		        if ($Liste_Boot_Order_disable) 
		        {
		            $Liste_Boot_Order_disable = $Liste_Boot_Order_disable.trim(',')
		            write-host "Liste disabled = $($Liste_Boot_Order_disable)"
		        }		
				
				if (($ListOptionsBootOrder -ne $null) -and ($ListOptionsBootOrder -ne "")) 
				{
					$ListDeviceBoot = ($ListOptionsBootOrder.split('#'))[1].trim()
		            if ($Liste_Boot_Order_enable)
		            {
		                if ($Liste_Boot_Order_disable)
		                {
		                    if ($password)
		                    {
		                        $Resultat_SetBootOrder = cmd.exe /c """$LibPath\CCTK\cctk.exe"" bootorder --sequence=$($ListDeviceBoot) --disabledevice=$($Liste_Boot_Order_disable) --enabledevice=$($Liste_Boot_Order_enable) --valsetuppwd=$($Password)"
		                    }
		                    else
		                    {
		                        $Resultat_SetBootOrder = cmd.exe /c """$LibPath\CCTK\cctk.exe"" bootorder --sequence=$($ListDeviceBoot) --disabledevice=$($Liste_Boot_Order_disable) --enabledevice=$($Liste_Boot_Order_enable)"
		                    }
		                }
		                else
		                {
		                    if ($password)
		                    {
		                        $Resultat_SetBootOrder = cmd.exe /c """$LibPath\CCTK\cctk.exe"" bootorder --sequence=$($ListDeviceBoot) --enabledevice=$($Liste_Boot_Order_enable) --valsetuppwd=$($Password)"
		                    }
		                    else
		                    {
		                        $Resultat_SetBootOrder = cmd.exe /c """$LibPath\CCTK\cctk.exe"" bootorder --sequence=$($ListDeviceBoot) --enabledevice=$($Liste_Boot_Order_enable)"
		                    }
		                    
		                }
		            }
		            Else
		            {
		                if ($Liste_Boot_Order_disable)
		                {
		                    if ($password)
		                    {
		                        $Resultat_SetBootOrder = cmd.exe /c """$LibPath\CCTK\cctk.exe"" bootorder --sequence=$($ListOptionsBootOrder) --disabledevice=$($Liste_Boot_Order_disable) --valsetuppwd=$($Password)"
		                    }
		                    else
		                    {
		                        [array]$Resultat_SetBootOrder = cmd.exe /c """$LibPath\CCTK\cctk.exe"" bootorder --sequence=$($ListDeviceBoot) --disabledevice=$($Liste_Boot_Order_disable)"
		                    }
		                    
		                }
		                else
		                {
		                    if ($password)
		                    {
		                        $Resultat_SetBootOrder = cmd.exe /c """$LibPath\CCTK\cctk.exe"" bootorder --sequence=$($ListDeviceBoot) --valsetuppwd=$($Password)"
		                    }
		                    else
		                    {
		                        $Resultat_SetBootOrder = cmd.exe /c """$LibPath\CCTK\cctk.exe"" bootorder --sequence=$($ListDeviceBoot)"
		                    }
		                    
		                }
		            }
				} 
				Else 
				{
					return "INFO : Aucune option valide trouvé dans le XML"
				}
			}
			Else
			{
				return "ERREUR : Pas de liste de boot récuperé"
			}
		    
			if ($Resultat_SetBootOrder)
		    {
		        
		        return $true
		    }
		    Else
		    {
		        return $false
		    }
		} 
		catch 
		{
		    return "ERREUR : $($_.exception.Message)"
		}
	}
	Else 
	{
		return "INFO : Marque non géré par ce script"
	}
}