# Lab: Monitoring services that are deployed to Azure
# Student lab manual

## Lab scenario

You have created an API for your next big startup venture. Even though you want to get to market quickly, you have witnessed other ventures fail when they don’t plan for growth and have too few resources or too many users. To plan for this, you have decided to take advantage of the scale-out features of Microsoft Azure App Service, the telemetry features of Application Insights, and the performance-testing features of Azure DevOps.

## Objectives

After you complete this lab, you will be able to:

-   Create an Application Insights resource.

-   Integrate Application Insights telemetry tracking into an ASP.NET web app and a resource built using the Web Apps feature of Azure App Service.

## Lab setup

-   Estimated time: **45 minutes**

## Instructions

### Before you start

#### Sign in to the lab virtual machine

Ensure that you're signed in to your Windows 10 virtual machine by using the following credentials:
    
-   Username: **Admin**

-   Password: **Pa55w.rd**

#### Review the installed applications

Find the taskbar on your Windows 10 desktop. The taskbar contains the icons for the applications that you'll use in this lab:
    
-   Microsoft Edge

-   File Explorer

-   Visual Studio Code

-   Windows PowerShell

### Exercise 1: Create and configure Azure resources

#### Task 1: Open the Azure portal

1.  On the taskbar, select the **Microsoft Edge** icon.

1.  Sign in to the Azure portal (<https://portal.azure.com>).

1.  At the sign-in page, enter the email address for your Microsoft account, and then select **Next**.

1.  Enter the password for your Microsoft account, and then select **Sign in**.

    > **Note**: If this is your first time signing in to the Azure portal, a dialog box will display offering a tour of the portal. Select **Get Started** to skip the tour and begin using the portal.

#### Task 2: Create an Application Insights resource

1.  Create a new Application Insights account with the following details:
    
    -   New resource group: **MonitoredAssets**

    -   Name: **instrm*[yourname]***

    -   Region: **(US) East US**
    
    -   Resource Mode: **Classic**

    > **Note**: Wait for Azure to finish creating the storage account before you move forward with the lab. You'll receive a notification when the account is created.

1.  Access the **Properties** section of the **Application Insights** blade.

1.  Get the value of the **Instrumentation Key** text box. This key is used by client applications to connect to Application Insights.

#### Task 3: Create a web app by using Azure App Services resource

1.  Create a new **web app** with the following details:

    -   Existing resource group: **MonitoredAssets**
    
    -   Web App name: ***smpapi\***[yourname]***

    -   Publish: **Code**

    -	Runtime stack: **.NET Core 3.1 (LTS)**

    -	Operating System: **Windows**

    -	Region: **East US**

    -	New App Service plan: **MonitoredPlan**
    
    -	SKU and size: **Standard (S1)**

    -	Application Insights: **Enabled**

    -	Existing Application Insights resource: **instrm*[yourname]***
  
    > **Note**: Wait for Azure to finish creating the web app before you move forward with the lab. You'll receive a notification when the app is created.

1.  Access the web app with a prefix of **smpapi\*** that you created earlier in this lab.

1.  In the **Settings** section, go to the **Configuration** section.

1.  Find and access the **Application Settings** tab in the **Configuration** section.

1.  Get the value corresponding to the **APPINSIGHTS\_INSTRUMENTATIONKEY** application settings key. This value was set automatically when you built your web app.

1.  Access the **Properties** section of the **App Service** blade.

1.  Record the value of the **URL** text box. You'll use this value later in the lab to make requests against the API.

#### Task 4: Configure web app autoscale options

1.  Go to the **Scale out** section of the **App Services** blade.

1.  In the **Scale out** section, enable **Custom autoscale** with the following details:
    
    -   Name: **ComputeScaler**
    
    -   In the **Scale mode** section, select **Scale based on a metric**.
    
    -   Minimum instances: **2**
    
    -   Maximum instances: **8**
    
    -   Default instances: **3**
    
    -   Scale rules: **Single scale-out rule with default values**

1.  Save your changes to the **autoscale** configuration.

#### Review

In this exercise, you created the resources that you'll use for the remainder of the lab.

### Exercise 2: Monitor a local web application by using Application Insights

#### Task 1: Build a .NET Web API project

1.  Open Visual Studio Code.

1.  In Visual Studio Code, open the **Allfiles (F):\\Allfiles\\Labs\\11\\Starter\\Api** folder.

1.  Use the Explorer pane in Visual Studio Code to open a new terminal that has the context set to the current working directory.

1.  At the command prompt, create a new .NET Web API application named **SimpleApi** in the current directory:

    ```
    dotnet new webapi --output . --name SimpleApi
    ```

1.  Import version 2.14.0 of **Microsoft.ApplicationInsights** from NuGet to the current project:

    ```
    dotnet add package Microsoft.ApplicationInsights --version 2.14.0
    ```

    > **Note**: The **dotnet add package** command will add the **Microsoft.ApplicationInsights** package from NuGet. For more information, go to [Microsoft.ApplicationInsights](https://www.nuget.org/packages/Microsoft.ApplicationInsights/2.14.0).

1.  Import version 2.14.0 of **Microsoft.ApplicationInsights.AspNetCore** from NuGet to the current project:

    ```
    dotnet add package Microsoft.ApplicationInsights.AspNetCore --version 2.14.0
    ```

    > **Note**: The **dotnet add package** command will add the **Microsoft.ApplicationInsights.AspNetCore** package from NuGet. For more information, go to [Microsoft.ApplicationInsights.AspNetCore](https://www.nuget.org/packages/Microsoft.ApplicationInsights.AspNetCore/2.14.0).

1.  Import version 2.14.0 of **Microsoft.ApplicationInsights.PerfCounterCollector** from NuGet to the current project:

    ```
    dotnet add package Microsoft.ApplicationInsights.PerfCounterCollector  --version 2.14.0
    ```

    > **Note**: The **dotnet add package** command will add the **Microsoft.ApplicationInsights.PerfCounterCollector** package from NuGet. For more information, go to [Microsoft.ApplicationInsights.PerfCounterCollector](https://www.nuget.org/packages/Microsoft.ApplicationInsights.PerfCounterCollector/2.14.0).

1.  Build the .NET web app:

    ```
    dotnet build
    ```

#### Task 2: Update application code to disable HTTPS and use Application Insights

1.  Use the Explorer in Visual Studio Code to open the **Startup.cs** file in the editor.

1.  Find and delete the following line of code at line 39:

    ```
    app.UseHttpsRedirection();
    ```

    > **Note**: This line of code forces the web app to use HTTPS. For this lab, this is unnecessary.

1.  In the **Startup** class, add a new static string constant named **INSTRUMENTATION_KEY** with its value set to the instrumentation key that you copied from the Application Insights resource you created earlier in this lab:

    ```
    private static string INSTRUMENTATION_KEY = "{your_instrumentation_key}";
    ```

    > **Note**: For example, if your instrumentation key is ``d2bb0eed-1342-4394-9b0c-8a56d21aaa43``, your line of code would be ``private static string INSTRUMENTATION_KEY = "d2bb0eed-1342-4394-9b0c-8a56d21aaa43";``

1.  Add a new line of code in the **ConfigureServices** method to configure Application Insights using the provided instrumentation key:

    ```
    services.AddApplicationInsightsTelemetry(INSTRUMENTATION_KEY);
    ```

1.  Save the **Startup.cs** file.

1.  If it's not already open, use the Explorer in Visual Studio Code to open a new terminal with the context set to the current working directory.

1.  Build the .NET web app:

    ```
    dotnet build
    ```

#### Task 3: Test an API application locally

1.  If it's not already open, use the Explorer in Visual Studio Code to open a new terminal with the context set to the current working directory.

1.  Run the .NET web app.

    ```
    dotnet run
    ```

1.  Open a new **Microsoft Edge** browser window.

1.  In the open browser window, go to the **/weatherforecast** relative path of your test application that's hosted at **localhost** on port **5000**.
    
    > **Note**: The full URL is <http://localhost:5000/weatherforecast>.

1.  Close the browser window that you recently opened.

1.  Close the currently running Visual Studio Code application.

#### Task 4: Get metrics in Application Insights

1.  Return to your currently open browser window that's displaying the Azure portal.

1.  Access the **instrm*[yourname]*** Application Insights account that you created earlier in this lab.

1.  From the **Application Insights** blade, find the metrics displayed in the tiles in the center of the blade. Specifically, find the number of server requests that have occurred and the average server response time.

    > **Note**: It can take up to five minutes to observe requests in the Application Insights metrics charts.

## Create availability test

Availability tests in Application Insights allow you to automatically test your application from various locations around the world.   In this tutorial, you will perform a url test to ensure that your web application is available.  You could also create a complete walkthrough to test its detailed operation. 

1. Select **Application Insights** and then select your subscription.  

2. Select **Availability** under the **Investigate** menu and then click **Create test**.

    ![Add availability test](media/tutorial-alert/add-test-001.png)

3. Type in a name for the test and leave the other defaults.  This selection will trigger requests for the application url every 5 minutes from five different geographic locations.

4. Select **Alerts** to open the **Alerts** dropdown where you can define details for how to respond if the test fails. Choose **Near-realtime** and set the status to **Enabled.**

    Type in an email address to send when the alert criteria is met.  You could optionally type in the address of a webhook to call when the alert criteria is met.

    ![Create test](media/tutorial-alert/create-test-001.png)

5. Return to the test panel, select the ellipses and edit alert to enter the configuration for your near-realtime alert.

    ![Edit alert](media/tutorial-alert/edit-alert-001.png)

6. Set failed locations to greater than or equal to 3. Create an [action group](../alerts/action-groups.md) to configure who gets notified when your alert threshold is breached.

    ![Save alert UI](media/tutorial-alert/save-alert-001.png)

7. Once you have configured your alert, click on the test name to view details from each location. Tests can be viewed in both line graph and scatter plot format to visualize the success/failures for a given time range.

    ![Test details](media/tutorial-alert/test-details-001.png)

8. You can drill down into the details of any test by clicking on its dot in the scatter chart. This will launch the end-to-end transaction details view. The example below shows the details for a failed request.

    ![Test result](media/tutorial-alert/test-result-001.png)

#### Review

In this exercise, you created an API by using ASP.NET and configured it to stream application metrics to Application Insights. You then used the Application Insights dashboard to get performance details about your API.

### Exercise 3: Clean up your subscription 

#### Task 1: Open Azure Cloud Shell

1.  In the Azure portal, select the **Cloud Shell** icon to open a new shell instance.

1.  If **Cloud Shell** isn't already configured, configure the shell for **Bash** by using the default settings.

#### Task 2: Delete resource groups

1.  Enter the following command, and then select Enter to delete the **MonitoredAssets** resource group:

    ```
    az group delete --name MonitoredAssets --no-wait --yes
    ```
    
1.  Close the Cloud Shell pane in the portal.

#### Task 3: Close the active applications

1.  Close the currently running Microsoft Edge application.

1.  Close the currently running Visual Studio Code application.

#### Review

In this exercise, you cleaned up your subscription by removing the resource groups used in this lab.
