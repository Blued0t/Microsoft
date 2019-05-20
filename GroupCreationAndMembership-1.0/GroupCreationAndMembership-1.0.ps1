<#
.SYNOPSIS
 Imports a csv file for group manipulation

.DESCRIPTION
Simple script that imports a csv file for the creation and membership of groups.
 The top row of the csv is the list of parent groups (these will get created if they dont alreayd exist)
 Each column then has the member groups (that get created if they dont exist), these are added to the parent group at the op of each column.
 The description of the group should be enclosed in brackets.

.PARAMETER ConfigFile
 Name of the csv file to import.

.NOTES
  Version:        1.0
  Author:         Jon Kidd
  Creation Date:  
  Purpose/Change: 
  Initial functionality
  Could do with some more checking and formatting of group names but its just to give an overall idea of importing a csv and creating AD groups

.EXAMPLE
  GroupCreationAndMembership-1.0.ps1 -ConfigFile .\GroupCreationAndMembership.csv
#>

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

[CmdletBinding()]
param(
   [Parameter(Mandatory=$true)]
   [String] $ConfigFile
   )


#----------------------------------------------------------[Declarations]----------------------------------------------------------
$distName = Get-ADDomain | Select-Object -ExpandProperty DistinguishedName
$parentOu = "ou=Roles, ou=Accounts, " + $distName
$memberOu = "ou=Access, ou=Accounts, " + $distName

#-----------------------------------------------------------[Functions]------------------------------------------------------------
Function addParentGroup
{
    Param
    (
      [Parameter(Mandatory=$true)]
      [string]$adParentGroup
    )
    
      try{
          Get-ADGroup -Identity $adParentGroup
      }catch{
        try{
          $DCs = @(Get-ADDomainController -Filter * | Select-Object -ExpandProperty Name)        
              try{
                  New-ADGroup -Name $adParentGroup -Path $parentOu -GroupScope Global -Server $DCs[0]
                  $groupPath = Get-ADGroup -Identity $adParentGroup -Server $DCs[0] | Select-Object -ExpandProperty DistinguishedName
                  For ($iTotalDCs = 1; $iTotalDCs -lt $DCs.Count; $iTotalDCs++){
                      try{
                          Sync-ADObject -Object $groupPath -Source $DCs[0] -Destination $DCs[$iTotalDCs] 
                      }catch{
                        Write-verbose "Error syncing $adParent Group to $($DCs[$iTotalDCs]) `n"
                      }
                    }
              }catch{
                  Write-verbose "Error creating AD Group $adParent Group $_.Exception.Message `n"
              }     
        }catch{
            Write-Verbose "Error creating AD Group $groupToCreate $_.Exception.Message `n"
        }      
      }
}


Function addMemberGroup
{
    Param
    (
      [Parameter(Mandatory=$true)]
      [string]$adMemberGroupInfo
    )
    
      Write-Verbose $adMemberGroupInfo

      $getGroupInfo = $adMemberGroupInfo.Split(" ")
      $admemberGroup = $getGroupInfo[0]
      $admemberGroupDesc = $adMemberGroupInfo.Substring($adMemberGroupInfo.IndexOf('(') +1 ,$adMemberGroupInfo.IndexOf(')')-$adMemberGroupInfo.IndexOf('(') -1 )
      
      try{
          $currentAdmemberGroup = Get-ADGroup -Identity $admemberGroup -Properties *
          if ($currentAdmemberGroup.Description -ne $admemberGroupDesc)
          {
            Set-ADGroup $admemberGroup -Description $admemberGroupDesc 
          }
      }catch{
        try{
          $DCs = @(Get-ADDomainController -Filter * | Select-Object -ExpandProperty Name)        
              try{
                  New-ADGroup -Name $admemberGroup -Path $memberOu -GroupScope Global -Server $DCs[0] -Description $admemberGroupDesc
                  $groupPath = Get-ADGroup -Identity $admemberGroup -Server $DCs[0] | Select-Object -ExpandProperty DistinguishedName
                  For ($iTotalDCs = 1; $iTotalDCs -lt $DCs.Count; $iTotalDCs++){
                      try{
                          Sync-ADObject -Object $groupPath -Source $DCs[0] -Destination $DCs[$iTotalDCs] 
                      }catch{
                        Write-verbose "Error syncing $admemberGroup to $($DCs[$iTotalDCs]) `n"
                      }
                    }
              }catch{
                  Write-verbose "Error creating AD Group $admemberGroup $_.Exception.Message `n"
              }     
        }catch{
            Write-Verbose "Error creating AD Group $groupToCreate $_.Exception.Message `n"
        }      
      }

}


Function addGroupToGroup{
  param
  (
      $groupToUse,
      $groupInfoToAdd
  )

  $getGroupInfo = $groupInfoToAdd.Split(" ")
  $groupToAdd = $getGroupInfo[0]

  try{
      $DCs = @(Get-ADDomainController -Filter * | Select-Object -ExpandProperty Name)    
          try{
              Add-ADGroupMember -Identity $groupToUse -Members $groupToAdd -Server $DCs[0]
          }catch{
              Write-Verbose "Error Adding $groupToAdd to $groupToUse $_.Exception.Message"
          }

          $groupPath = Get-ADGroup -Identity $groupToUse | Select-Object -ExpandProperty DistinguishedName                        
          For ($iTotalDCs = 1; $iTotalDCs -lt $DCs.Count; $iTotalDCs++){
              try{
                  Sync-ADObject -Object $groupPath -source $DCs[0] -Destination $DCs[$iTotalDCs] 
              }catch{
                Write-Verbose "Error syncing $groupToUse to $($DCs[$iTotalDCs]) "
              }
          }
         
  }catch{
    Write-Verbose "General Error"
  }
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------

try{
  $csv = Import-Csv $ConfigFile 
  $csv | ForEach-Object {
    foreach ($prop in $_.PSObject.Properties)
    {
      $parentGroup = $prop.Name
      $memberGroup = $prop.Value
      Write-Verbose $parentGroup
      addparentGroup -adParent Group $parentGroup    
      Write-Verbose $memberGroup 
      if ($memberGroup){
        addmemberGroup -adMemberGroupInfo $memberGroup
        addGroupToGroup -groupToUse $parentGroup -groupInfoToAdd $memberGroup
      }
    }
  }
}catch{
  Write-Verbose "General error executing the script"
}
