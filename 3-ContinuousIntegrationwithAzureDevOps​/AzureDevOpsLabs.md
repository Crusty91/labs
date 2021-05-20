# Labs will be from Az-400 Training

- https://github.com/MicrosoftLearning/AZ400-DesigningandImplementingMicrosoftDevOpsSolutions/blob/master/Instructions/Labs/AZ400_M04_Version_Controlling_with_Git_in_Azure_Repos.md
- https://github.com/MicrosoftLearning/AZ400-DesigningandImplementingMicrosoftDevOpsSolutions/blob/master/Instructions/Labs/AZ400_M07_Integrating_Azure_Key_Vault_with_Azure_DevOps.md
- https://github.com/MicrosoftLearning/AZ400-DesigningandImplementingMicrosoftDevOpsSolutions/blob/master/Instructions/Labs/AZ400_M11_Configuring_Pipelines_as_Code_with_YAML.md
- https://github.com/MicrosoftLearning/AZ400-DesigningandImplementingMicrosoftDevOpsSolutions/blob/master/Instructions/Labs/AZ400_M12_Feature_Flag_Management_with_LaunchDarkly_and_Azure_DevOps.md
- https://github.com/MicrosoftLearning/AZ400-DesigningandImplementingMicrosoftDevOpsSolutions/blob/master/Instructions/Labs/AZ400_M01_Agile_Planning_and_Portfolio_Management_with_Azure_Boards.md


# Issues

If you encounter the error: "PartsUnlimited-aspnet45\PartsUnlimited.DepValidation\PartsUnlimited.DepValidation.modelproj(36,11): Error MSB4226: The imported project "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\MSBuild\Microsoft\VisualStudio\v16.0\ArchitectureTools\Microsoft.VisualStudio.TeamArchitect.ModelingProject.targets" was not found. Also, tried to find "ArchitectureTools\Microsoft.VisualStudio.TeamArchitect.ModelingProject.targets" in the fallback search path(s) for $(VSToolsPath) - "C:\Program Files (x86)\MSBuild\Microsoft\VisualStudio\v16.0" . These search paths are defined in "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\MSBuild\Current\bin\msbuild.exe.Config". Confirm that the path in the <Import> declaration is correct, and that the file exists on disk in one of the search paths."

The quickest way to fix it is to remove a project in Azure Repos:
- Open project "PartsUnlimited"
- Open file "PartsUnlimited-aspnet45/PartsUnlimited.sln"
- Select EDIT in the upper right corner
- remove the lines 16 and 17:
Project("{F088123C-0E9E-452A-89E6-6BA2F21D5CAC}") = "PartsUnlimited.DepValidation", "PartsUnlimited.DepValidation\PartsUnlimited.DepValidation.modelproj", "{17652060-8A22-4C4F-AB62-AF5A32C39553}"
EndProject
- Commit your changes



If you need an agent, you can deploy one in the lab vm by following the instructions :
https://github.com/MicrosoftLearning/AZ400-DesigningandImplementingMicrosoftDevOpsSolutions/blob/master/Instructions/Labs/AZ400_M05_Configuring_Agent_Pools_and_Understanding_Pipeline_Styles.md#exercise-2-manage-azure-devops-agent-pools
You can also using a docker running agent, the command is:
docker run -e VSTS_ACCOUNT=[YOUR ORGANIZATION NAME] -e VSTS_TOKEN=[YOUR PERSONNAL ACCESS TOKEN] -it mcr.microsoft.com/azure-pipelines/vsts-agent
