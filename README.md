# Fortianalyzer Integration with Microsoft Sentinel 

## Introduction

Microsoft Sentinel is a scalable, cloud-native solution offering Security Information and Event Management (SIEM) and Security Orchestration, Automation, and Response (SOAR).
It provides intelligent security analytics and threat intelligence across the enterprise, offering a unified platform for attack detection, threat visibility, proactive hunting, and response.
For further details, please refer to the following [link](https://learn.microsoft.com/en-us/azure/sentinel/overview).

FortiAnalyzer seamlessly integrates with Azure Sentinel, offering enhanced support through log streaming to multiple destinations using the Fluentd Azure Log Analytics output plugin. 
Fluentd, an open-source data collector, serves as a comprehensive solution that unifies the process of collecting and consuming data. For additional details, please check the following [link](https://www.fluentd.org/architecture).

This integration enables the forwarding of logs to public cloud services. The plugin efficiently aggregates semi-structured data in real-time, facilitating the buffered data's transmission to Azure Log Analytics via HTTPS requests.

## Data Flow

To ingest CEF logs from FortiGate into Azure Sentinel, a dedicated Linux machine is configured to serve as proxy server for log collection and forwarding to the Microsoft Sentinel workspace.

The Linux machine is structured with two key components:

Syslog Daemon (Log Collector):

Utilizing either rsyslog or syslog-ng, this daemon performs dual functions:

-Actively listens for Syslog messages originating from Fortigate on TCP port 514.
-forwards only identified CEF messages to the Log Analytics Agent on localhost, utilizing TCP port 25226.

Log Analytics Agent (OMS Agent):

This agent, also referred to as the OMS Agent, engages in two critical tasks:

-Listens for incoming CEF messages from the integrated Linux Syslog daemon, operating on TCP port 25226.
-Securely transmits these CEF messages over TLS to the Microsoft Sentinel workspace.

Following this configuration on the Linux machine, the FortiGate device is then set up to dispatch Syslog messages in CEF format to the designated proxy machine using the provided command:


<pre><code>
config log syslogd setting
    set status enable
    set port 514
    set server "x.x.x.x" # IP of the Syslog agent's address
    set format cef
end
</code></pre>

![FGT-Sentinel Integration-DataFlow](images/FGT-DataFlow.png)


FortiGate utilizes TCP port 514 for communication with FortiAnalyzer and log transmission. FortiAnalyzer employs Fluentd as a data collector, responsible for aggregating, filtering, and securely transmitting data via HTTPS to an Azure Log Analytics workspace. 
The integration of Fluentd with FortiAnalyzer eliminates the necessity for a separate proxy server to install a data collector between FortiAnalyzer and the Azure Log Analytics workspace.



![FAZ-Sentinel Integration-DataFlow](images/FAZ-DataFlow.png)



## Deployment: Azure Portal

Azure Portal Wizard:
[![Azure Portal Wizard](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fyarafe%2FTest%2Fmain%2FmainTemplate.json/createUIDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2Fyarafe%2FTest%2Fmain%2FcreateUiDefinition.json)

Custom Deployment:
[![Deploy To Azure](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2F40net-cloud%2Ffortinet-azure-solutions%2Fmain%2FFortiSandbox%2FBasic-Deployment%2FmainTemplate.json)
[![Visualize](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/visualizebutton.svg?sanitize=true)](http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2F40net-cloud%2Ffortinet-azure-solutions$2Fmain%2FFortiSandbox%2FBasic-Deployment%2FmainTemplate.json)

The default login Credentials for Fortisandbox VM are as follow:

The default login credentials are as follow:
Username admin
Password: VM-ID

You can get VM-ID using azure cli command:  az vm list -–output tsv -g [Your resource group]

Upon successful login, you have the option to modify your password.


## Support

Fortinet-provided scripts in this and other GitHub projects do not fall under the regular Fortinet technical support scope and are not supported by FortiCare Support Services.
For direct issues, please refer to the [Issues](https://github.com/40net-cloud/fortinet-azure-solutions/issues) tab of this GitHub project.

## License

[License](LICENSE) © Fortinet Technologies. All rights reserved.
