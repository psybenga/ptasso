# Created by Peter Sybenga 21/7/2018 
#Requirements:
# Microsoft Online Services Sign-In Assistant.
# 64-bit Azure Active Directory module for Windows PowerShell.


#Set up some logging. You might consider writing or finding a standard logging module.
    $Date        = Get-Date
    $LogPath     = "C:\temp"
    $LogGeneral  = Join-Path $LogPath 'Gen.log'
    $LogEnvStart = Join-Path $LogPath 'EnvStart.xml'
    $LogErrors   = Join-Path $LogPath 'Errors.log'

#Log initial details
    $Admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")
    $Whoami = whoami # Simple, could use $env as well
    "Running script $($MyInvocation.MyCommand.Path) at $Date"
    "Admin: $Admin" | Out-File $LogGeneral -Append
    "User: $Whoami" | Out-File $LogGeneral -Append
    "Bound parameters: $($PSBoundParameters | Out-String)" | Out-File $LogGeneral -Append

    #Only track two layers.  If you need deeper properties, expand this or track them independently
    Get-Variable | Export-Clixml -Depth 2 -Path $LogEnvStart

    Try {
        #The -ErrorAction Stop brings us to the catch block, if we get an error...

# First time this script should be run manually though the task scheduler, this will ensure the process runs correctly and sets up the passwsord encryption files that 
# will be used for future reference. 
# 
# The below 2 commented lines should be uncommneted: Where {Password} is defined should be replaced including the brackets with the real passwords. Once the script is run the lines 
# can be re-commnented and the plain text passwords deleted from the script. Once completed resave the file !   

# ConvertTo-SecureString {Password} -AsPlainText -Force | ConvertFrom-SecureString | Out-File C:\Scripts\Cloud_Encrypted_Password.txt
# ConvertTo-SecureString {Password} -AsPlainText -Force | ConvertFrom-SecureString | Out-File C:\Scripts\Onprem_Encrypted_Password.txt

# Change the Cloud User to be the Office365 account for your tenant with global adminsSS
$CloudUser = 'admin@acmeincgroup.onmicrosoft.com'
$CloudEncrypted = Get-Content "C:\Scripts\Cloud_Encrypted_Password.txt" | ConvertTo-SecureString 
$CloudCred = New-Object System.Management.Automation.PsCredential($CloudUser, $CloudEncrypted) 
$OnpremEncrypted = Get-Content "C:\Scripts\Onprem_Encrypted_Password.txt" | ConvertTo-SecureString 
# On-Premise Account - must not be a domain admin ! Only a user account with write and reset password permissions for the AZUREADSSOACC computer Object. 
$OnpremUser1 = 'ACMEGROUP\PTA_SSO'
$OnpremCred1 = New-Object System.Management.Automation.PsCredential($OnpremUser1, $OnpremEncrypted)
Import-Module 'C:\Program Files\Microsoft Azure Active Directory Connect\AzureADSSO.psd1'
New-AzureADSSOAuthenticationContext -CloudCredentials $CloudCred
Update-AzureADSSOForest -OnPremCredentials $OnpremCred1

# 2nd domain ---
# The following can be removed or deleted if you do not have multiple domains with SSO enabled
# On-Premise Account - must not be a domain admin ! Only a user account with write and reset password permissions for the AZUREADSSOACC computer Object. 
$OnpremUser2 = 'ACMEHQ\PTA_SSO'
$OnpremCred2 = New-Object System.Management.Automation.PsCredential($OnpremUser2, $OnpremEncrypted)
Import-Module 'C:\Program Files\Microsoft Azure Active Directory Connect\AzureADSSO.psd1'
New-AzureADSSOAuthenticationContext -CloudCredentials $CloudCred
Update-AzureADSSOForest -OnPremCredentials $OnpremCred2

# 3rd domain ---
# The following can be removed or deleted if you do not have multiple domains with SSO enabled
# On-Premise Account - must not be a domain admin ! Only a user account with write and reset password permissions for the AZUREADSSOACC computer Object. 
$OnpremUser3 = 'ACMENQ\PTA_SSO' 
$OnpremCred3 = New-Object System.Management.Automation.PsCredential($OnpremUser3, $OnpremEncrypted) 
Import-Module 'C:\Program Files\Microsoft Azure Active Directory Connect\AzureADSSO.psd1'  
New-AzureADSSOAuthenticationContext -CloudCredentials $CloudCred 
Update-AzureADSSOForest -OnPremCredentials $OnpremCred3  
   
# Do not delete the following syntax this this closes the try statement and includes the catch clause used for the errorlog should a failure occur and one be created 

    }
    Catch {
        "I can log a friendly description of the error here, or log the error:" | Out-File $LogErrors -Append
        $_ | Out-File $LogErrors -Append
  
    }
