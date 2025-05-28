# SQL App Project

## Table of Contents

- [Introduction](#introduction)
- [Architecture](#architecture)
- [Important Notes](#important-notes)
- [Prerequisites](#prerequisites)
- [Application Configuration](#application-configuration)
- [Jenkins Setup](#jenkins-setup)
  - [Deploy Resources](#1-deploy-resources)
  - [Jenkins Agent VM](#2-jenkins-agent-vm)
  - [Initial Jenkins Configuration](#3-initial-jenkins-configuration)
  - [GitHub Integration](#4-github-integration)
  - [Docker Cloud Provider](#5-docker-cloud-provider-optional-but-recommended-for-dynamic-agents)
  - [Create Jenkins Pipeline Job](#6-create-jenkins-pipeline-job)
- [Security Considerations](#security-considerations)
- [Database Setup](#database-setup)
- [Docker Agent Configuration](#docker-agent-configuration)
- [Azure DevOps Setup](#azure-devops-setup)
  - [Service Connections](#1-service-connections)
  - [Build Pipeline](#2-build-pipeline-yaml-or-classic)
  - [Release Pipeline](#3-release-pipeline)
  - [CI Trigger for Build Pipeline](#4-ci-trigger-for-build-pipeline)
- [CI/CD Workflow](#cicd-workflow)
- [Final Result](#final-result)
- [Persisting Jenkins Data](#persisting-jenkins-data)

## Introduction

This project demonstrates an ASP.NET Core application that interacts with an MS SQL database. The application queries the database and displays the data on a web page.

**This is completely focused on the backend. The frontend is just a sample, 
but it works.**

The project is designed to be deployed using Azure resources, 
with a CI/CD pipeline managed by Jenkins and Azure DevOps.

## Architecture

![](images/Architecture.png)

> Figure 1: System Architecture

The application is an ASP.NET C# web app. All Azure resources are provisioned using Terraform. Jenkins is used for Continuous Integration (CI) within an Azure DevOps environment.

## Important Notes

*   **Configuration:** Remember to update `terraform.tfvars` with your specific values for VM admin username, storage account key, etc. **Never commit sensitive data directly to your repository.** Use secure methods like Azure Key Vault or environment variables for managing secrets.
*   **Secrets Management:** VM passwords and the SQL server password are not output by Terraform directly. They can be found in the `terraform.tfstate` file. **Handle the `.tfstate` file with extreme care as it contains sensitive information.** Consider using [Terraform remote state](https://www.terraform.io/language/state/remote) with appropriate access controls.
*   **VM Setup:** Virtual machines utilize script extensions (`vmscriptextension` folder) to install Docker and configure the Jenkins agent. `script.sh` is for the Jenkins master VM, and `script2.sh` is for the agent VM.
*   **Jenkins Agent:** The Jenkins agent is configured to use Docker containers.
*   **Jenkins Job:** The Jenkins job builds the application and deploys it to an Azure App Service.
*   **Path Accuracy:** Ensure the `Jenkins Job Name` in the Azure DevOps pipeline and paths within the `Jenkinsfile` are correct to prevent build failures.

## Prerequisites

*   **Jenkins & Azure CI:** For integrating Jenkins and Azure for CI, refer to [CI Jenkins Azure Guide](https://github.com/nokorinotsubasa/CI-jenkins-azure).
*   **Jenkins Docker Agents:** To use Docker containers as Jenkins agents, see [Jenkins Docker Agent Guide](https://github.com/nokorinotsubasa/jenkins-docker-agent).
*   **SQL Server Configuration:**
    *   Allow connections in the SQL server's Networking configuration.
    *   Enable "Allow Azure services and resources to access this server."
    ![](images/sqlservernetworkingconfiguration.png)
    > Figure 2: SQL Server Networking Configuration

## Application Configuration

*   Update the `ConnectionStrings` section in the `appsettings.json` file with the connection string to your database. **Avoid hardcoding connection strings in source control.** Use environment variables or Azure App Configuration for production environments.

## Jenkins Setup

### 1. Deploy Resources

Run `terraform apply` to deploy the Azure resources. VM script extensions will run upon creation.

### 2. Jenkins Agent VM

The agent VM will be pre-configured for Docker containers via script extensions.

### 3. Initial Jenkins Configuration

*   Access Jenkins via `http://<VM_IP>:8080`.
*   Unlock Jenkins using the initial admin password. This can be found in the Jenkins container logs on the master VM:
    ```bash
    sudo docker logs jenkins
    ```
    ![](images/unlockJenkins.png)
    > Figure 3: Unlock Jenkins
*   Create an admin user.
*   Install necessary plugins: `Docker`, `GitHub`, and `Azure CLI` (or `Azure Credentials` and related plugins for Azure integration).

### 4. GitHub Integration

*   On the Jenkins master VM, generate an SSH key pair:
    ```bash
    ssh-keygen -t rsa
    ```
*   Add the **public key** to your GitHub repository's Deploy Keys (or your user's SSH keys).
*   Add the **private key** to Jenkins credentials (Kind: SSH Username with private key).
    ![](images/githubsshkeyconfiguration.png)
    > Figure 4: GitHub SSH Key Configuration
    ![](images/sshgithubcredentials.png)
    > Figure 5: Jenkins GitHub Credential Configuration
*   Add GitHub to the known hosts on the Jenkins master VM:
    ```bash
    ssh-keyscan github.com >> ~/.ssh/known_hosts
    ```
*   Ensure the SSH agent is running:
    ```bash
    eval $(ssh-agent -s)
    ssh-add ~/.ssh/id_rsa # Or the path to your private key
    ```

### 5. Docker Cloud Provider (Optional but Recommended for Dynamic Agents)

*   Configure Docker as a cloud provider in Jenkins (Manage Jenkins -> Clouds).
*   Set the Docker Host URI to connect to the agent VM's Docker daemon (e.g., `tcp://<AGENT_VM_IP>:4243` - ensure port 4243 is open and Docker is configured to listen on it, as in `script2.sh`).
    ![](images/jenkinscloudconfiguration.png)
    > Figure 6: Jenkins Cloud Configuration

### 6. Create Jenkins Pipeline Job

*   Create a new Pipeline job.
*   Select "Pipeline script from SCM."
*   Choose Git as SCM.
*   Provide the repository URL (SSH URL, e.g., `git@github.com:USERNAME/REPONAME.git`).
*   Select the appropriate GitHub SSH credentials.
    ![](images/jenkinspipelinejobcreation.png)
    > Figure 7: Jenkins Pipeline Job Creation

## Security Considerations

*   **Host Key Verification:** **Disabling is not recommended for security reasons.** Instead, ensure the host key for GitHub is correctly added to `known_hosts`. If issues persist, investigate them rather than disabling this security feature.
    ![](images/Hostkeyverificationstrategy.png)
    > Figure 8: Host Key Verification (If disabled - not recommended)
*   Follow the [CI Jenkins Azure Guide](https://github.com/nokorinotsubasa/CI-jenkins-azure) for secure Jenkins and Azure integration.

## Database Setup

1.  **Access Database:** Connect to your SQL database. You may need to add your client IP address to the Azure SQL Server firewall rules.
2.  **Run SQL Script:** Execute the `script.sql` (found in this repository) to create the necessary table and insert sample data.
    ![](images/sqlquery.png)
    > Figure 9: script.sql Query

## Docker Agent Configuration

*   For detailed guidance on configuring Docker containers as Jenkins agents, refer to [Jenkins Docker Agent Setup](https://github.com/alexsander-projects/jenkins-docker-agent).

## Azure DevOps Setup

### 1. Service Connections

Ensure you have Service Connections set up in Azure DevOps for Jenkins and GitHub.

### 2. Build Pipeline (YAML or Classic)

*   Create a new pipeline.
*   Use a template that integrates with Jenkins (e.g., the "Jenkins" template if available, or a YAML pipeline with a Jenkins job invocation task).
*   Configure the Jenkins job invocation: **The `Job name` must exactly match the Jenkins job name.**
    ![](images/pipelineconfiguration.png)
    > Figure 10: Azure DevOps Pipeline Configuration (Jenkins Job)

### 3. Release Pipeline

*   Create a new Release Pipeline.
*   Select a template for deploying to Azure App Service (e.g., "Azure App Service deployment").
*   Configure the artifact source to be the build pipeline created in the previous step.
    ![](images/releasepipelineartifact.png)
    > Figure 11: Release Pipeline Artifact Configuration
*   Enable the Continuous Delivery (CD) trigger.
    ![](images/CDtrigger.png)
    > Figure 12: Release Pipeline CD Trigger

### 4. CI Trigger for Build Pipeline

*   Go back to your Build Pipeline settings.
*   Enable the Continuous Integration (CI) trigger (e.g., trigger on commits to the main branch of your GitHub repository).
    ![](images/pipelineCItrigger.png)
    > Figure 13: Build Pipeline CI Trigger

## CI/CD Workflow

1.  A commit to the GitHub repository triggers the Azure DevOps Build Pipeline.
2.  The Build Pipeline queues the Jenkins job.
    ![](images/queuejenkinsjob.png)
    > Figure 14: Azure DevOps Queuing Jenkins Job
3.  Jenkins builds the application and publishes artifacts.
4.  The Azure DevOps Build Pipeline downloads the artifacts.
5.  The CD trigger on the Release Pipeline starts a new release.
6.  The Release Pipeline downloads the build artifacts and deploys the application to the Azure App Service.
    ![](images/releasePipelineLogs.png)
    > Figure 15: Release Pipeline Logs

## Final Result

Accessing the web application's URL will display a list of products. Every approved commit to the repository will automatically trigger the CI/CD pipeline, building and deploying the new version of the application.

![](images/appwebpage.png)
> Figure 16: Application Web Page

## Persisting Jenkins Data

*   To learn how to persist Jenkins data (e.g., using Docker volumes or other backup strategies), refer to [Persist Jenkins Docker Data](https://github.com/nokorinotsubasa/tar-jenkins-docker).

