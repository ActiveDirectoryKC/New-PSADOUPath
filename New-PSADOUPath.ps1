using namespace System.Collections.Generic

<#
.SYNOPSIS
Creates an OU structure hierarchically based on the provided Distinguished Name.

.DESCRIPTION 
    Takes a distinguished name and determines the OUs in the path that would need to
    be created to have that distinguished name. Verifies the OUs exists and then 
    attempts to create the OUs. Does not support container objects. Default is to
    use the logged on user's credentials. 

.PARAMETER OUPath
    [string] Takes a distinguished name. 

.PARAMETER Credential
    [PSCredential] Credentials used to create the OU structure. Use (Get-Credential) to force a prompt.

.PARAMETER Server
    [string] Domain controller to execute changes against.

.EXAMPLE
    New-PSADOUPath -OUPath "OU=TEST,OU=FirstParent,OU=Parent,DC=CONTOSO,DC=COM"

.EXAMPLE 
    New-PSADOUPath -OUPath "OU=TEST,OU=FirstParent,OU=Parent,DC=CONTOSO,DC=COM" -Credential $PSCredential

.EXAMPLE 
    New-PSADOUPath -OUPath "OU=TEST,OU=FirstParent,OU=Parent,DC=CONTOSO,DC=COM" -Credential $PSCredential -Server MyDomainController.CONTOSO.COM

.NOTES
    Created On: 03/16/2021
    Updated On: 08/25/2021
    Version 1.0.1

    .CHANGE LOG
        1.0.1 
            - Quiet parameter added to speed up script.
            - Removed Get-RootDSE for credential validation.
.COPYRIGHT
Copyright (c) ActiveDirectoryKC.NET. All Rights Reserved

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

The website "ActiveDirectoryKC.NET" or it's administrators, moderators, 
affiliates, or associates are not affilitated with Microsoft and no 
support or sustainability guarantee is provided. 
#>
function New-PSADOUPath
{
    Param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$false,HelpMessage="Supply the distinguished name (DN) you wish to validate/create.")]
        [ValidatePattern('^(?:(?<cn>CN=(?<name>[^,]*)),)?(?:(?<path>(?:(?:CN|OU)=[^,]+,?)+),)?(?<domain>(?:DC=[^,]+,?)+)$')] # For Distinguished Names
        [string]$OUPath,

        [Parameter(Mandatory=$false,ValueFromPipeline=$false)]
        [pscredential]$Credential,

        [Parameter(Mandatory=$false,ValueFromPipeline=$false)]
        [string]$Server,

        [Parameter(Mandatory=$false,ValueFromPipeline=$false)]
        [switch]$Quiet
    )

    Begin
    {
        # -- Variables
        [List[string]]$NamingStructure = $null
        [List[string]]$Nodes = $null
        [string]$Root = ""
        [string]$CurrentOUPath = ""
        [List[string]]$ExportList = [List[string]]::new()
        [Queue[string]]$NodeQueue
    }

    Process
    {
        
        # -- Variable Assignment / Initial Processing
        $NamingStructure = [List[string]]::new($OUPath.split(","))
        $Nodes = [string[]]($NamingStructure.Where({ $PSItem -match 'OU|CN' }))
        $Root = ($NamingStructure.Where({ $PSItem -notmatch 'OU|CN' }) -join ",")
        $CurrentOUPath = $Root
        $TargetDomainName = $Root.replace("DC=","").replace(",",".")

        #region Credential Validation
        # If no $Credential is supplied, we need to prompt.
        if( !$Credential -or !$PSBoundParameters.ContainsKey("Credential") )
        {
            $Credential = Get-Credential -Message "Enter credentials for $TargetDomainName"
        }
        #endregion Credential Validation

        #region Server Validation
        # If no $Server was supplied or we cannot ping it, try to find one via DC Locator. 
        if( !$Server -or !$PSBoundParameters.ContainsKey("Server") -or !(Test-Connection -ComputerName $Server -Quiet) )
        {
            Write-Information "No server provided - Attempting to lookup a server from the domain '$TargetDomainName'."

            $Server = (Get-ADDomainController -Discover -DomainName $TargetDomainName).Hostname[0] # Hostname is silly, it comes in as an array. Choose first element.

            if( !$Server )
            {
                throw [System.InvalidOperationException]::new("Unable to resolve a domain controller in the domain '$TargetDomainName' - Exiting")
            }
        }
        #endregion Server Validation

        # Loop through the list of Nodes backwards. This will give us our order of precedence. 
        for( $i = $Nodes.Count-1; $i -ge 0; $i--)
        {
            $ExportList.Add( $Nodes[$i] )
        }

        # Create a Queue, we use the FIFO aspects of a Queue to speed operations.
        $NodeQueue = [Queue[string]]::new($ExportList)

        # For each Queue item, find it. If it is missing, create it. 
        foreach( $Node in $NodeQueue )
        {
            $OUName = $Node.replace("OU=","").replace("CN=","")
            
            if( Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$Node,$CurrentOUPath'" -Server $Server -Credential $Credential -ErrorAction Stop -Verbose:$VerbosePreference )
            {
                if( !$Quiet )
                {
                    Write-Information "OU '$Node,$CurrentOUPath' exists - Continuing"
                }
            }
            else
            {
                if( $Node -notmatch "CN" )
                {
                    Try
                    {
                        $null = New-ADOrganizationalUnit -Name $OUName -Path $CurrentOUPath -Server $Server -Credential $Credential -ErrorAction Stop -Verbose:$VerbosePreference -WhatIf:$WhatIfPreference -ProtectedFromAccidentalDeletion $false
                        if( !$Quiet )
                        {
                            Write-Output "Successfully created the OU '$OUName' at '$CurrentOUPath' on '$Server'"
                        }
                    }
                    Catch
                    {
                        Write-Error -Message "Unable to create the OU '$OUName' at '$CurrentOUPath' on '$Server'" -CategoryTargetType InvalidOperationException
                        throw $PSItem
                    }
                }
                else
                {
                    Write-Warning "Creation of container (CN) objects and other objects is not supported."
                }
            }

            # Set our current path, this way we always have the furthest out DN available. 
            $CurrentOUPath = "$Node,$CurrentOUPath"
            $OUName = $null
        }
    }

    End
    {
        $NodeQueue = $null
    }
}