# FortiAppSec and FortiWeb Integration with Microsoft Sentinel via AMA 

## Introduction

Some clients may require forwarding logs to additional centralized hubs, such as Microsoft Sentinel, to integrate with their SIEM solutions. This approach supports advanced analytics, diverse compliance requirements, and various operational needs.

This guide provides a comprehensive walkthrough for integrating FortiAppSec and FortiWeb VM with Microsoft Sentinel via Azure Monitor Agent (AMA).

## Data Flow

To ingest CEF logs from FortiAppSec into Microsoft Sentinel, a dedicated Linux machine is configured to serve as proxy server for log collection and forwarding to the Microsoft Sentinel workspace.

The Linux machine is structured with two key components:

* **Syslog Daemon (Log Collector):** using either rsyslog or syslog-ng, this daemon performs dual functions:

    - Actively listens for attack logs messages in CEF format sent by FortiAppSec over UDP 514, TCP 601 or SSL 6514. 
    - Forwards the recieved logs to Azure Monitor Agent (AMA) on localhost, using TCP port 28330.

* **Azure Monitor Agent (AMA):** The agent parses the logs and then sends them to your Microsoft Sentinel (Log Analytics) workspace via HTTPS 443.

![Fortiappsec-DataFlow](images/Fortiappsec-dataflow.png)

For more details please review this [link](https://learn.microsoft.com/en-us/azure/sentinel/cef-syslog-ama-overview?tabs=forwarder)

## Deployment and Setup

Prerequisites:
- Log Analytics Workspace [link](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/quick-create-workspace?tabs=azure-portal).
- Microsoft Sentinel onboarded with the Log Analytics Workspace [link](https://learn.microsoft.com/en-us/azuresentinelquickstart-onboard).
- Dedicated linux VM [link](https://learn.microsoft.com/en-us/azure/virtual-machines/linux/quick-create-portal?tabs=ubuntu).

To establish the integration between Microsoft Sentinel and FortiGate, follow these steps:

- [Install Fortinet FortiWeb Cloud WAF-as-a-Service connector](#install-fortinet-fortiweb-cloud-waf-as-a-service-connector)
- [Install Common Event Format Data Connector](#install-common-event-format-data-connector)
- [Create Data Collection Rule (DCR) (if you don't have one)](#create-data-collection-rule-dcr-if-you-dont-have-one)
- [Install CEF Collector on Linux VM](#install-cef-collector-on-linux-vm)
- [Generate server certificate and key](#generate-server-certificate-and-key)
- [Install rsyslog-gnutls on Linux VM](#install-rsyslog-gnutls-on-linux-vm) 
- [Configure rsyslog file with port 6514 and certificate](#) 
- [Allow FortiAppSec management IP](#allow-fortiappsec-management-ip) 
- [Configure FortiAppSec Device](#configure-fortiappsec-device)

### Install Fortinet FortiWeb Cloud WAF-as-a-Service connector

- Navigate to Microsoft Sentinel workspace ---> Content management ---> Content hub.
- Search for "Fortinet FortiWeb Cloud WAF-as-a-Service connector" and install it. 

![ Sentinel- fortiweb-connector](images/fortiweb-connector.png)

### Install Common Event Format Data Connector

- Navigate to Microsoft Sentinel workspace ---> Content management ---> Content hub.
- Search for 'Common Event Format (CEF) and install it. This will deploy for you Common Event Format (CEF) via AMA.

![ Sentinel- CEF-DataConnector](images/CEF-DataConnector.png)

- Open connector page for Common Event Format (CEF) via AMA.

![ Sentinel- CEF via AMA-page](images/CEF-via-AMA-page.png)

### Create Data collection rule DCR (if you don't have one)

- Use the same location as your log analytics workspace
- Add linux machine as a resource
- Collect facility log_local7 and set the min log level to be collected

![ Create DCR1](images/fwb-create-dcr1.png)

![ Create DCR2](images/create-dcr2.png)

![ Create DCR3](images/create-dcr3.png)

You can find below an ARM template example for DCR configuration:
<pre><code>

{
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "dataCollectionRules_WAF_a_a_S_name": {
            "defaultValue": "WAF-a-a-S",
            "type": "String"
        },
        "workspaces_ya_ama_externalid": {
            "defaultValue": "/subscriptions/f7f4728a-781f-470f-b029-bac8a9df75af/resourceGroups/ya-faz-sentinel-ama/providers/Microsoft.OperationalInsights/workspaces/ya-ama",
            "type": "String"
        }
    },
    "variables": {},
    "resources": [
        {
            "type": "Microsoft.Insights/dataCollectionRules",
            "apiVersion": "2023-03-11",
            "name": "[parameters('dataCollectionRules_WAF_a_a_S_name')]",
            "location": "westeurope",
            "tags": {
                "createdBy": "Sentinel"
            },
            "kind": "Linux",
            "properties": {
                "dataSources": {
                    "syslog": [
                        {
                            "streams": [
                                "Microsoft-CommonSecurityLog"
                            ],
                            "facilityNames": [
                                "local7"
                            ],
                            "logLevels": [
                                "Notice",
                                "Warning",
                                "Error",
                                "Critical",
                                "Alert",
                                "Emergency"
                            ],
                            "name": "sysLogsDataSource-1039681479"
                        },
                        {
                            "streams": [
                                "Microsoft-CommonSecurityLog"
                            ],
                            "facilityNames": [
                                "nopri"
                            ],
                            "logLevels": [
                                "Emergency"
                            ],
                            "name": "sysLogsDataSource-1697966155"
                        }
                    ]
                },
                "destinations": {
                    "logAnalytics": [
                        {
                            "workspaceResourceId": "[parameters('workspaces_ya_ama_externalid')]",
                            "name": "DataCollectionEvent"
                        }
                    ]
                },
                "dataFlows": [
                    {
                        "streams": [
                            "Microsoft-CommonSecurityLog"
                        ],
                        "destinations": [
                            "DataCollectionEvent"
                        ]
                    }
                ]
            }
        }
    ]
}

</code></pre>

### Install CEF Collector on Linux VM
Install the Common Event Format (CEF) collector on a Linux machine by executing the following Python script:
<pre><code>
sudo wget -O Forwarder_AMA_installer.py https://raw.githubusercontent.com/Azure/Azure-Sentinel/master/DataConnectors/Syslog/Forwarder_AMA_installer.py&&sudo python3 Forwarder_AMA_installer.py
</code></pre>

### Install rsyslog-gnutls on Linux VM

Execute the following commands to install rsyslog-gnutls package:

<pre><code>
sudo apt update
sudo apt install rsyslog-gnutls
</code></pre>

This will allow rsyslog to handle secure connections using TLS. 

### Generate server certificate and key

- Generate the CA:
<pre><code>
openssl genrsa -aes256 -out ca-key.pem 4096
openssl req -x509 -new -nodes -extensions v3_ca -key ca-key.pem -days 365 -out ca-root.pem -sha512
</code></pre>
This creates two files: the CA file 'ca.pem' and its private key 'privkey.pem' - a password for the private key is required.

- Create a serial file:
<pre><code>
echo 00 > serial.srl
</code></pre>
- Generate the server certificate and key:
<pre><code>
openssl genrsa -out server.key 4096
openssl req -key server.key -new -out server.req
openssl x509 -req -in server.req -CA ca-root.pem -CAkey ca-key.pem -CAserial serial.srl -out server.pem
</code></pre>

verify the permissions:
<pre><code>
yarafe@ya-ama-agent:~$ ls -l /etc/rsyslog.d/keys/
total 12
-rw-r--r-- 1 root root   2065 Jan 16 22:07 ca-root.pem
-rw-r----- 1 root syslog 3268 Jan 16 22:08 server.key
-rw-r--r-- 1 root root   1919 Jan 16 22:09 server.pem
</code></pre>

### Configure rsyslog file with port 6514 and certificate

<pre><code>
sudo nano /etc/rsyslog.conf
</code></pre>

You need to add the following to config file:
<pre><code>
global(
DefaultNetstreamDriver="gtls"
DefaultNetstreamDriverCAFile="/etc/rsyslog.d/keys/ca-root.pem"
DefaultNetstreamDriverCertFile="/etc/rsyslog.d/keys/server.pem"
DefaultNetstreamDriverKeyFile="/etc/rsyslog.d/keys/server.key"
)

module(load="imtcp" StreamDriver.Name="gtls" StreamDriver.Mode="1" StreamDriver.Authmode="anon")
input(type="imtcp" port="6514")
</code></pre>


Restart rsyslog
<pre><code>
sudo systemctl restart rsyslog
</code></pre>

### Allow FortiAppSec management IP

It is recommended to configure your log server with filters that permit traffic exclusively from FortiAppSec. Ensure that only the following source IP addresses are allowed:
- 3.226.2.163
- 3.123.68.65

### Configure FortiAppSec Device

To export the attack logs to a log server:

- Go to Log Settings.
- Enable Attack Log Export and click Save. 
- Click Add Log Server.
- Configure the following settings:
    - Name
    - Server Type: Syslog
    - IP/Domain and Port: Syslog IP address/6514
    - Protocol : SSL
    - Enable "Custom Certificate and Key" and add client certificate and private key
    - Set your export options: Log Format: CEF:0 (ArcSight), Log Severity , Log Facility: local7 

The facility log should match "Collect" in the Data Collection Rule configuration.
Test the conectivity to syslog. You should get a message "A test message has been sent successfully to your server, please check if it is received."
You can visit the [link](https://docs.fortinet.com/document/fortiappsec-cloud/latest/user-guide/681595/log-settings) for more details.

![fortiappsec-config](images/fortiappsec-config.png)

## Validation and Connectivity Check

- The following command can be used to check the log statistics sent from FortiGate:
<pre><code>
diagnose test application syslogd 4
</code></pre>
- Restart rsyslog
<pre><code>
sudo systemctl restart rsyslog
</code></pre>

- Validate that the syslog daemon is running on the TCP port and that the AMA is listening by reviewing the configuration file /etc/rsyslog.conf . After verification, use the following command to confirm:

<pre><code>
netstat -lnptv
</code></pre>
![ Port Validation- AMA](images/port-validation-ama.png)

- Run the following command in the background to capture messages sent from a logger or a connected device:
<pre><code>
tcpdump -i any port 514 -A -vv &
</code></pre>
After you complete the validation, we recommend that you stop the tcpdump: Type fg and then select Ctrl+C

- Verify the correct installation of the connector by running the troubleshooting script using one of the following commands:
<pre><code>
sudo wget -O Sentinel_AMA_troubleshoot.py https://raw.githubusercontent.com/Azure/Azure-Sentinel/master/DataConnectors/Syslog/Sentinel_AMA_troubleshoot.py&&sudo python3 Sentinel_AMA_troubleshoot.py --cef
</code></pre>

![ Troubleshooting- AMA ](images/troubleshooting-ama.png)

- Check data connector page and verify that the DCR is corectly assigned and that the log is well ingested in CommonSecurityLog Table

![ DataConnector - Validation](images/dataconnector-validation.png)

![ DataConnector - Validation](images/CommonSecurityLog.png)

You can review the [link](https://learn.microsoft.com/en-us/azure/sentinel/connect-cef-syslog-ama?tabs=portal) for more technical details about FortiGate integration With Microsoft Sentinel.

## Log Filtering

Log forwarding to Microsoft Sentinel can lead to significant costs, making it essential to implement an efficient filtering mechanism. 
In essence, you have the flexibility to toggle the traffic log on or off via the graphical user interface (GUI) on Fortigate devices, directing it to either Fortianalyzer or a syslog server, and specifying the severity level.
Additionally, you can undertake more advanced filtering through CLI, allowing for tailored filtering based on specific values. Please refer to the following [link](https://docs.fortinet.com/document/fortigate/7.6.0/cli-reference/273422104/config-log-syslogd-filter).

On The other hands, you can select the minimum log level for each facility from DCR (collect tab) . When you select a log level, Microsoft Sentinel collects logs for the selected level and other levels with higher severity. For example, if you select LOG_ERR, Microsoft Sentinel collects logs for the LOG_ERR, LOG_CRIT, LOG_ALERT, and LOG_EMERG levels.




