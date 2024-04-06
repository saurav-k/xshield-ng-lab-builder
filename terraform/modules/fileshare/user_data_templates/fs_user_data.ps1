<powershell>

$pass = ConvertTo-SecureString -String "${password}" -AsPlainText -Force
Set-LocalUser -Name "Administrator" -Password $pass -PasswordNeverExpires $true
New-LocalUser -Name smbuser -FullName "SMB User" -PasswordNeverExpires -Password $pass

Add-WindowsFeature -Name File-Services
mkdir 'C:\DropBox'
New-SmbShare -Name 'DropBox' -path 'C:\DropBox' -FullAccess 'smbuser'

# For Ansible
Set-NetFirewallRule -Name "WINRM-HTTP-In-TCP-PUBLIC" -RemoteAddress Any

Invoke-WebRequest -Uri https://ct-xshield-lab-assets.s3.amazonaws.com/infra/agent.ps1 -OutFile C:\Windows\Temp\agent.ps1
(Get-Content C:\Windows\Temp\agent.ps1).Replace("{SIEM_IP}", "${siem_ip}").Replace("{ASSETMGR_IP}", "${assetmgr_ip}") | Set-Content C:\Windows\Temp\agent.ps1
Register-ScheduledJob -Name Agents -FilePath C:\Windows\Temp\agent.ps1 -RunEvery (New-Timespan -Minutes 5)

Rename-Computer -NewName "${hostname}"
Restart-Computer

</powershell>