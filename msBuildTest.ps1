<#	
	.NOTES
	===========================================================================
	 Created with: 	VSCode
	 Created on:   	2020/8/13
	 Created by:   	Manson Yang
	 Organization: 	Manson Yang
	===========================================================================
	.DESCRIPTION
		Auto Deploy Script using Git & MSBuild
#>
param([string]$IfUseNuGetReStore,[string]$projectPath, [string]$csprojName)
# Temply assign values
$IfUseNuGetReStore = "Y"
$projectPath = "L:\NetCoreApiProject";
$csprojName = "NetCoreApiProject.csproj";
$IfUpdateNuGetTool = "N"
$SolutionPath = "L:\NetCoreApiProject\NetCoreApiProject.sln"
# Define Global parameters
$LogForegroundColorStart = "Green";
$LogForegroundColorEnd = "Cyan";
$LogForegroundColorWarning = "DarkYellow";
$MSBuildExe = "";
$NuGetExe="L:\AutoDeploy\nuget.exe"

Write-Host "`nPublish parameters initializing..." -Foreground $LogForegroundColorStart
$baseDrive = "L:\";

Set-Location $baseDrive ;
# Set-Location $exePath;

# Find the MSBuild.exe file order by version
Function Set-Msbuild-Tools
{
	# Visual Studio 2017 and above, Build Tools
	if (Test-Path "${env:ProgramFiles(x86)}\Microsoft Visual Studio\*\BuildTools\MSBuild\*\Bin\MSBuild.exe")
	{
		if (Test-Path "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\BuildTools\MSBuild\Current\Bin\MSBuild.exe")
		{
			$script:MSBuildExe = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\BuildTools\MSBuild\Current\Bin\MSBuild.exe"
			$script:MsBuildToolsVersion = "Current"
		}
		elseif (Test-Path "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2017\BuildTools\MSBuild\15.0\Bin\MSBuild.exe")
		{
			$script:MSBuildExe = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2017\BuildTools\MSBuild\15.0\Bin\MSBuild.exe"
			$script:MsBuildToolsVersion = "15.0"
		}
	}
	# Visual Studio 2019 Build Tools
	elseif (Test-Path "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\*\MSBuild\Current\Bin\MSBuild.exe")
	{
		if (Test-Path "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Community\MSBuild\Current\Bin\MSBuild.exe")
		{
			$script:MSBuildExe = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Community\MSBuild\Current\Bin\MSBuild.exe"
		}
		elseif (Test-Path "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Professional\MSBuild\Current\Bin\MSBuild.exe")
		{
			$script:MSBuildExe = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Professional\MSBuild\Current\Bin\MSBuild.exe"
		}
		else
		{
			$script:MSBuildExe = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Enterprise\MSBuild\Current\Bin\MSBuild.exe"
		}
		$script:MsBuildToolsVersion = "Current"
	}
	# Visual Studio 2017 Build Tools
	elseif (Test-Path "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2017\*\MSBuild\15.0\Bin\MSBuild.exe")
	{
		if (Test-Path "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2017\Community\MSBuild\15.0\Bin\MSBuild.exe")
		{
			$script:MSBuildExe = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2017\Community\MSBuild\15.0\Bin\MSBuild.exe"
		}
		elseif (Test-Path "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2017\Professional\MSBuild\15.0\Bin\MSBuild.exe")
		{
			$script:MSBuildExe = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2017\Professional\MSBuild\15.0\Bin\MSBuild.exe"
		}
		else
		{
			$script:MSBuildExe = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2017\Enterprise\MSBuild\15.0\Bin\MSBuild.exe"
		}
		$script:MsBuildToolsVersion = "15.0"
	}
	# Visual Studio 2015 and below Build Tools
	elseif (Test-Path "${env:ProgramFiles(x86)}\MSBuild\*\Bin\MSBuild.exe")
	{
		if (Test-Path "${env:ProgramFiles(x86)}\MSBuild\14.0\Bin\MSBuild.exe")
		{
			$script:MSBuildExe = "${env:ProgramFiles(x86)}\MSBuild\14.0\Bin\MSBuild.exe"
			$script:MsBuildToolsVersion = "14.0"
		}
		elseif (Test-Path "${env:ProgramFiles(x86)}\MSBuild\12.0\Bin\MSBuild.exe")
		{
			$script:MSBuildExe = "${env:ProgramFiles(x86)}\MSBuild\12.0\Bin\MSBuild.exe"
			$script:MsBuildToolsVersion = "12.0"
		}
		elseif (Test-Path "${env:ProgramFiles(x86)}\MSBuild\10.0\Bin\MSBuild.exe")
		{
			$script:MSBuildExe = "${env:ProgramFiles(x86)}\MSBuild\10.0\Bin\MSBuild.exe"
			$script:MsBuildToolsVersion = "10.0"
		}
	}
	
	# If cannot find then try search in .NET Framework
	if ($script:MSBuildExe -eq "")
	{
		if (Test-Path "${env:SystemRoot}\Microsoft.NET\Framework\v4.0.30319\MSBuild.exe")
		{
			$script:MSBuildExe = "${env:SystemRoot}\Microsoft.NET\Framework\v4.0.30319\MSBuild.exe"
			$script:MsBuildToolsVersion = "4.0"
		}
		elseif (Test-Path "${env:SystemRoot}\Microsoft.NET\Framework\v3.5\MSBuild.exe")
		{
			$script:MSBuildExe = "${env:SystemRoot}\Microsoft.NET\Framework\v3.5\MSBuild.exe"
			$script:MsBuildToolsVersion = "3.5"
		}
		else
		{
			$script:MSBuildExe = "${env:SystemRoot}\Microsoft.NET\Framework\v2.0.50727\MSBuild.exe"
			$script:MsBuildToolsVersion = "2.0"
		}
	}
}
Set-Msbuild-Tools
Write-Host "`nCurrent Microsoft Build Tools Path: $MSBuildExe" -Foreground $LogForegroundColorStart
Write-Host "Current Microsoft Build Tools Version: $MsBuildToolsVersion" -Foreground $LogForegroundColorEnd

# NuGet restore
Function ReStore-Package
{
	if ($IfUseNuGetReStore -eq "Y")
	{
		if ($IfUpdateNuGetTool -eq "Y")
		{
			Write-Host "`nNuGet tools Start updating..." -Foreground $LogForegroundColorStart
			&$NuGetExe update -Self
			Write-Host "NuGet tools update completed." -Foreground $LogForegroundColorEnd
		}
		else
		{
			Write-Host "Not update NuGet tools." -Foreground $LogForegroundColorEnd
		}
		
		Write-Host "`nNuGet Start ReStoreing..." -Foreground $LogForegroundColorStart
		&$NuGetExe restore $SolutionPath
		Write-Host "NuGet ReStore completed." -Foreground $LogForegroundColorEnd
	}
	else
	{
		Write-Host "`nNot use NuGet tools." -Foreground $LogForegroundColorStart
	}
}
ReStore-Package