<#
.SYNOPSIS
Lists / searches hotfixes applied to the local Windows machine or array of machines

.DESCRIPTION
 Lists /  searches hotfixes applied to the local Windows machine or array of machines

.PARAMETER assets
String array containing a list of assets to be checked. 
If no assets are supplied then localhost is checked by default

.PARAMETER kb
If a kb number is supplied then the assets are checked to see if the kb has been applied to each of them
  

.NOTES
  Version:        1.0
  Author:         Jon Kidd
  Creation Date:  
  Purpose/Change: 

  Future possible enhancements:
  Logging out to a file
  Using WMI to check for other updates
  Optional credentials with which to run the script
  Theres probably a better way of kb checking in the second part of the script...

  
.EXAMPLE
getWindowsPatches-1.0.ps1 -assets:VM1,VM2,VM3 -kb:KB4456655
  
#>

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [String]$kb,
    [Parameter(Mandatory=$false)]
    [string[]]$assets = "localhost"
)


#----------------------------------------------------------[Declarations]----------------------------------------------------------
[string]$hotfixes

#-----------------------------------------------------------[Functions]------------------------------------------------------------


#-----------------------------------------------------------[Execution]------------------------------------------------------------
[array]$resultSet = @(    
    $hotfixes = Get-HotFix -ComputerName $assets | Select-Object -Property HotFixID, InstalledOn 
    $hotfixes | ForEach-Object{
        [PSCustomObject]@{
            Asset       = $asset
            Hotfix      = $_.HotFixID
            InstalledOn = $_.InstalledOn
        }
    }
)


$resultSet

if ($kb){
    ForEach($asset in $assets){
        $kbFound = $false
        $resultSet | ForEach-Object{
            if (($_.HotFix -like $kb) -and ($asset -like $_.Asset)){
                $kbFound = $true
                Break
            }
        }
        if (!($kbFound)){
            Write-Output "$kb not found on $asset"
        }
    }   
}


