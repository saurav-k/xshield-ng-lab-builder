#
#  Functions to retrieve agent URLs.
#  ColorTokens Inc.
#  Last modified: 09-APR-2024, Venky Raju

import json
import traceback

from ngapi import exec_api

# Load configuration from file
with open('config.json') as config_file:
    config = json.load(config_file)

domain = config["domain"]

agent_version_api = 'api/agents/versions'
deployment_key_api = 'api/deployment-keys'

#
# agent_type := CT_AGENT | CT_GATEWAY | CT_CONTAINER_AGENT | CT_USER_AGENT
# host_platform := darwin | debian | rpm | windows | iso | ova
# host_arch := arm64 | x86_64 | ppc
#
def get_agent_installer(agent_type, host_platform, host_arch):

    resp = exec_api(agent_version_api, 'GET')
    if resp.ok:
        versions = resp.json().get('versions')
        for v in versions:
            if all([v.get('agentType') == agent_type, v.get('targetPlatform') == host_platform, 
                   v.get('architecture') == host_arch, v.get('recommended')]):
                dnld_link = v.get('downloadLink')
                return dnld_link.split('?')[0]

    raise Exception("Unable to determine URL.  Check parameter values.")


def get_deployment_key():
    try:
        resp = exec_api(deployment_key_api, 'GET')
        if resp.ok:
            items = resp.json().get('items')
            return items[0].get('key')
    except Exception as e:
        print("Unable to fetch deployment key.  Check configuration")
        print(traceback.format_exc())
    

