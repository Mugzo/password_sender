# Password Sender Project

This repository showcases an application I built while studying for the AZ-104 certification.

Password Sender lets you share passwords securely and comes with a handy built-in password generator.

https://pwd.slapointe.com

## About the Project

Password Sender is a simplified version of [Password Pusher](https://pwpush.com/), the frontend design and application functionnalities were heavily inspired from Password Pusher.

The code has been written by myself, it's not a mere replication or copy-paste of Password Pusher's code.

## Learning Journey

Throughout the development of this project, I gained valuable knowledge in several areas:

* **Azure Resources:** I deepened my understanding of Azure services by configuring them to support the functionality of Password Sender. This included setting up **App Service**, **Function App**, **Keyvault**, **Cosmos DB**, **Monitoring** and **more**.  
* **Python Programming:** Despite the low amount of Python code, this was a good opportunity to grasp the fundamentals of programming such as user input handling, password generation, unique identifiers and data security measures.
* **Bicep Template for Infrastructure as Code:** Developing Bicep templates to provision Azure resources was a significant learning experience and presented numerous challenges in automating the deployment of the application.


This project provided a hands-on learning opportunity that not only solidified my understanding of concepts relevant to the AZ-104 certification but also expanded my practical skills in cloud computing and software development.

## Infrastructure Diagram

![Infrastructure Diagram](https://github.com/sam-lapointe/password_sender/blob/main/password_sender_diagram.png)

## Deployment Instructions

1. Clone this repository (https://github.com/sam-lapointe/password_sender.git)

2. Deploy with Azure CLI or Azure Powershell
    - With Azure Powershell:
        ```
        \\ Connect to your account
        Connect-AzAccount
        \\ Select your subscription
        Set-AzContext -Subscription <Name or ID of subscription>
        \\ Deploy the template
        New-AzSubscriptionDeployment -Location <location> -TemplateFile <path-to-repo\bicep\main.bicep>
        ```
    - With Azure CLI
        ```
        \\ Connect to your account
        az login
        \\ Select your subscription
        az account set --subscription <Name or ID of subscription>
        \\ Deploy the template
        az deployment sub create --location <location> --template-file <path-to-repo/bicep/main.bicep>
        ```

3. After the deployment is finished, navigate to the Web App where you'll discover the Default domain.

## Note

The application was originally developed with Azure SQL Databases. However, due to the constraints of the Free tier, I opted to switch to Azure Cosmos DB for MongoDB instead.