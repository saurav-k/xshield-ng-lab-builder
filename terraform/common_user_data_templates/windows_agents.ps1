# The opening <powershell> tag shall be provided by the first template file!!!

if ( -Not (Test-Path C:\AgentsInstalled)) {

    # Download the agent script and update the parameters
    Invoke-WebRequest -Uri https://ct-xshield-lab-assets.s3.amazonaws.com/infra/agent.ps1 -OutFile C:\Windows\Temp\agent.ps1
    (Get-Content C:\Windows\Temp\agent.ps1).Replace("{SIEM_IP}", "${siem_ip}").Replace("{ASSETMGR_IP}", "${assetmgr_ip}") | Set-Content C:\Windows\Temp\agent.ps1

    # Schedule a task to run the agent script every 5 minutes
    $action = New-ScheduledTaskAction -Execute "Powershell.exe" -Argument "-File C:\Windows\Temp\agent.ps1"
    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration (New-TimeSpan -Days 1000)
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest    
    Register-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -TaskName "Agents" -Description "Tickle the agents every 5 minutes"

    # Download and install the Xshield agent
    Invoke-WebRequest -Uri ${xs_agent_windows_pkg_url} -OutFile C:\Windows\Temp\xshield-monitoring-agent.msi
    New-Item -ItemType Directory -Path 'C:\ProgramData\Colortokens' -ErrorAction SilentlyContinue | Out-Null
    msiexec.exe /i C:\Windows\Temp\xshield-monitoring-agent.msi /qb /l*v C:\ProgramData\Colortokens\ctagent_MSI.log | Out-Null
    cd 'C:\Program Files\Colortokens\xshield-monitoring-agent'
    .\ctagent.exe register --domain="${xs_domain}" --deploymentKey="${xs_deployment_key}" --agentType='server' --upgrade='true' --enable-vulnerability-scan='true'
    .\ctagent.exe start
    New-Item -ItemType "file" -Path C:\AgentsInstalled
}
</powershell>
<persist>true</persist>
