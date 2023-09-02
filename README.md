# Introduction

Here, an app will interact with tables with an MsSql database, and query it to show a web page with the table.

![](https://github.com/nokorinotsubasa/sqlapp-project/blob/3f473716a1d020cc1638ed70c9aaf7e434f28deb/images/Architecture.png)

>`Architecture`

The app is an ASP.Net running in C#

All the resources will be deployed with Terraform.

The app will be build with Jenkins, which will be used as CI for an Azure DevOps environment.

## Before we start

- To see how to integrate Jenkins and Azure for Continuous Integration, [click here](https://github.com/nokorinotsubasa/CI-jenkins-azure)

- To see how to use docker containers as Jenkins agents, [click here](https://github.com/nokorinotsubasa/jenkins-docker-agent)

- Remember to allow connections on the sql server Networking configuration, also, enable `Allow Azure services and resources to access this server`:

![](https://github.com/nokorinotsubasa/sqlapp-project/blob/0757e355b58ec77612a7a17a9b13901115b95f42/images/sqlservernetworkingconfiguration.png)

## Code configuration

- Create a `Key Vault` and generate a secret, reference it on the code:

![](https://github.com/nokorinotsubasa/sqlapp-project/blob/6a06e56d911b6e3387153833441605544b215cb9/images/keyvaultreference.png)

- Head into App Service and click on `Identity`;

- Enable `System Assigned Managed Identity`

![](https://github.com/nokorinotsubasa/sqlapp-project/blob/6a06e56d911b6e3387153833441605544b215cb9/images/enablesystemassigned.png)

- Go into the key vault and head into `Access Policies` and add an access policy;

- Select the `Service Principal and save`:

![](https://github.com/nokorinotsubasa/sqlapp-project/blob/6a06e56d911b6e3387153833441605544b215cb9/images/accesspolicyconfiguration.png)

- Add the redis connection string on `Program.cs` by referencing the keyvault:

![](https://github.com/nokorinotsubasa/sqlapp-project/blob/eb22f5169668e0a3a4477aaba824b80d0d4a1685/images/rediscodesecured.png)

>`Redis configuration on code`


## Jenkins Configuration

- First, let's run `terraform` to deploy all the resources we need; the Virtual machines will run script extensions upon creation, to speed up the process;

- The Jenkins agent Vm will `already be configured` to spin docker containers, thanks to the script extension implementation;

- Procede with jenkins configuration, create an admin user, download `Docker`, `github` and `azure cli` plugins;

![](https://github.com/nokorinotsubasa/sqlapp-project/blob/8bafa6628e01c232b53da50478748c2a7eaf5004/images/unlockJenkins.png)

>you can get the initial password with: `sudo docker logs jenkins`

- Set up `GitHub connection` on Jenkins for code checkout, to do this:

In the Vm, generate ssh keys:

>`ssh-keygen -t rsa`

The `public` key goes into the `github settings`; the `private key` into the `jenkins credentials settings`;

you need to add it into the `known_hosts_file`, to do this:

>`ssh-keyscan github.com >> ~/.ssh/known_hosts`

Don't forget to start the ssh agent:

>`eval ssh-agent`

![](https://github.com/nokorinotsubasa/sqlapp-project/blob/3f473716a1d020cc1638ed70c9aaf7e434f28deb/images/githubsshkeyconfiguration.png)

>`GitHub ssh key configuration`

![](https://github.com/nokorinotsubasa/sqlapp-project/blob/3f473716a1d020cc1638ed70c9aaf7e434f28deb/images/sshgithubcredentials.png)

>`Jenkins GitHub credential configuration`

- Set up docker `cloud provider` on Jenkins, for the container agents. Remember to correctly set the agent Vm IP;

![](https://github.com/nokorinotsubasa/sqlapp-project/blob/3f473716a1d020cc1638ed70c9aaf7e434f28deb/images/jenkinscloudconfiguration.png)

- Create a new Job on Jenkins of type pipeline, set the source code as: `Source code from scm` and set github ssh credentials and connection.

![](https://github.com/nokorinotsubasa/sqlapp-project/blob/3f473716a1d020cc1638ed70c9aaf7e434f28deb/images/jenkinspipelinejobcreation.png)

- Now, follow [this link](https://github.com/nokorinotsubasa/CI-jenkins-azure) to integrate Jenkins into Azure;

## Database configuration

- Access the databse and run the `script.sql` (it can be found on this repository)

![](https://github.com/nokorinotsubasa/sqlapp-project/blob/3f473716a1d020cc1638ed70c9aaf7e434f28deb/images/sqlquery.png)

>`script.sql query`

## Azure DevOps configuration

- Now on Azure DevOps, with Jenkins and GitHub service connection, create a new Pipeline, select `Pipeline template`;

- Search and select `Jenkins`;

- Correctly set the required fields, `REMEMBER THAT THE JOB NAME IS THE EXACTLY JOB NAME OF THE JENKINS JOB`;

![](https://github.com/nokorinotsubasa/sqlapp-project/blob/3f473716a1d020cc1638ed70c9aaf7e434f28deb/images/pipelineconfiguration.png)

>`Pipeline configuration`

- Create a `Release Pipeline` on azure, and select the Azure web app job, insert the app service type, name and framework;

- Configure the artifact source, in our case: `build`;

![](https://github.com/nokorinotsubasa/sqlapp-project/blob/3f473716a1d020cc1638ed70c9aaf7e434f28deb/images/releasepipelineartifact.png)

>`Release Pipeline Configuration`

- Activate the `Continuous Delivery` trigger;

![](https://github.com/nokorinotsubasa/sqlapp-project/blob/3f473716a1d020cc1638ed70c9aaf7e434f28deb/images/CDtrigger.png)

>`Release Pipeline trigger`

- Head back into `Pipelines` and set the `Continuous Integration` trigger (GitHub commit);

![](https://github.com/nokorinotsubasa/sqlapp-project/blob/3f473716a1d020cc1638ed70c9aaf7e434f28deb/images/pipelineCItrigger.png)

>`CI trigger`

- Now, upon running the Pipeline, it will queue the Jenkins job, building the app and generating the `artifact`, this will be downloaded into the build pipeline on Azure DevOps, to be later used;

![](https://github.com/nokorinotsubasa/sqlapp-project/blob/3f473716a1d020cc1638ed70c9aaf7e434f28deb/images/queuejenkinsjob.png)

>`Azure, Jenkins job logs`

- The Release Pipeline will start running, this will download the artifact from the build, and deploy the app into our `Azure App Service`.

![](https://github.com/nokorinotsubasa/sqlapp-project/blob/3d0c81ca1aa756061160f8c9be589a957b3945f1/images/releasePipelineLogs.png)

>`Release Pipeline logs`

## Final result

- Now, when accessing the web page, you will get a list of products; On every approved commit, a pipeline will run, building and deploying a new version of the app, thanks to CI/CD integration.

![](https://github.com/nokorinotsubasa/sqlapp-project/blob/3d0c81ca1aa756061160f8c9be589a957b3945f1/images/appwebpage.png)

>`app's web page`

## Persist Jenkins data

- To know how to persist Jenkins data, [click here](https://github.com/nokorinotsubasa/tar-jenkins-docker)