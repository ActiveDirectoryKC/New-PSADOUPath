# New-PSADOUPath
Creates an OU structure hierarchically based on the provided Distinguished Name.

## DESCRIPTION 
Takes a distinguished name and determines the OUs in the path that would need to
be created to have that distinguished name. Verifies the OUs exists and then 
attempts to create the OUs. Does not support container objects. Default is to
use the logged on user's credentials. 

## PARAMETERS
### PARAMETER OUPath
[string] Takes a distinguished name. 

### PARAMETER Credential
[PSCredential] Credentials used to create the OU structure. Use (Get-Credential) to force a prompt.

### PARAMETER Server
[string] Domain controller to execute changes against.

## EXAMPLES
### EXAMPLE
New-PSADOUPath -OUPath "OU=TEST,OU=FirstParent,OU=Parent,DC=CONTOSO,DC=COM"

### EXAMPLE 
New-PSADOUPath -OUPath "OU=TEST,OU=FirstParent,OU=Parent,DC=CONTOSO,DC=COM" -Credential $PSCredential

### EXAMPLE 
New-PSADOUPath -OUPath "OU=TEST,OU=FirstParent,OU=Parent,DC=CONTOSO,DC=COM" -Credential $PSCredential -Server MyDomainController.CONTOSO.COM

## NOTES
Created On: 03/16/2021
Updated On: 08/25/2021
Version 1.0.1

.CHANGE LOG
  1.0.1 
      - Quiet parameter added to speed up script.
      - Removed Get-RootDSE for credential validation.
      
## COPYRIGHT
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
