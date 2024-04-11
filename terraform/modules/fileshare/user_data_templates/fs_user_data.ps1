<powershell>
if ( -Not (Test-Path C:\FirstBootCompleted)) {

    $pass = ConvertTo-SecureString -String "${password}" -AsPlainText -Force
    Set-LocalUser -Name "Administrator" -Password $pass -PasswordNeverExpires $true
    New-LocalUser -Name smbuser -FullName "SMB User" -PasswordNeverExpires -Password $pass

    Add-WindowsFeature -Name File-Services
    mkdir 'C:\DropBox'
    New-SmbShare -Name 'DropBox' -path 'C:\DropBox' -FullAccess 'smbuser'

    # For Ansible
    Set-NetFirewallRule -Name "WINRM-HTTP-In-TCP-PUBLIC" -RemoteAddress Any

    Rename-Computer -NewName "${hostname}"

    New-Item -ItemType "file" -Path C:\FirstBootCompleted
    Restart-Computer
}

# The closing <powershell> tag and persistence should be provided by the final template file!!!
