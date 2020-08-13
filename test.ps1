<#	
	.NOTES
	===========================================================================
	 Created with: 	Visual Studio 2019
	 Created on:   	2019/8/26 11:31
	 Created by:   	Allen
	 Organization: 	Allen
	 Filename:     	build_full.ps1
	===========================================================================
	.DESCRIPTION
		ERP devops scripts.
#>

# 声明全局变量
# 定义方法开始时输出的前景色
$LogForegroundColorStart = "Green"
# 定义方法结束时输出的前景色
$LogForegroundColorEnd = "Cyan"
# 定义方法输出警告时的前景色
$LogForegroundColorWarning = "DarkYellow"

Write-Host "`nPublish parameters initializing..." -Foreground $LogForegroundColorStart

# Set user level's parameters
# 定义当前脚本文件的绝对全路径
$CurrentScriptFilePath = $MyInvocation.MyCommand.Definition
# 定义当前脚本文件的所在的文件夹路径
$ScriptWorkPath = Split-Path -Parent $CurrentScriptFilePath
# 定义当前脚本文件的所在的解决方案文件夹路径
$SolutionPath = Split-Path -Parent $ScriptWorkPath
# 定义当前编译工作的文件夹路径
$BuildPath = "$SolutionPath\Builds"
# 定义要编译的解决方案名称
$SolutionName = "ERP"
# 定义要编译的解决方案文件名称
$SolutionFile = "$SolutionPath\$SolutionName.sln"
# 定义要发布的Web项目名称列表
$WebProjectNames = "API1", "API2", "API3"
# 定义要发布的Windows项目名称列表
$WinProjectNames = , "Job" # 只有一个元素的字符串数组，前面加 , 定义 表示
# 定义要打包的项目名称列表
$PackageNames = "API1", "API2", "API3", "Job"

# NuGet parameters
# 定义NuGet文件夹路径
$NuGetPath = "$SolutionPath\.nuget"
# 定义NuGet.exe文件路径
$NuGetExe = "$NuGetPath\NuGet.exe"
# 定义是否执行NuGet包还原: Y|N
$IfUseNuGetReStore = "Y" # value is Y or N
# 定义是否更新NuGet.exe主程序: Y|N
$IfUpdateNuGetTool = "N" # value is Y or N

# Set system level's parameters
# 定义编译时要使用的解决方案配置: Debug|Release
$Configuration = "Debug"
# 定义编译时要输出的日志等级: quiet|minimal|normal|detailed|diagnostic
$LogLevel = "normal"
# 定义要构建的.NET Framework版本
# Note: That the MSBuild tool version and VisualStudio version and the TargetFramework version have dependencies
$TargetFrameworkVersion = "4.5"
# 定义MsBuild.exe(Microsoft Build Tools)文件路径
$MSBuildExe = ""
# 定义MsBuild.exe(Microsoft Build Tools)版本
$MsBuildToolsVersion = ""

# 从高往低版本逐个找，优先使用最高版本的Microsoft Build Tools
Function Set-Msbuild-Tools
{
	# Visual Studio 2017 以上版本独立安装的 Build Tools
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
	# Visual Studio 2019 内置的 Build Tools
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
	# Visual Studio 2017 内置的 Build Tools
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
	# Visual Studio 2015 以下版本独立安装的 Build Tools
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
	
	# 如果上面的都找不到，则尝试使用系统内置的.NET Framework版本
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
exit -1;
# 定义脚本执行时间/ZIP打包时间
$ExecuteDate = Get-Date
# 定义脚本执行时的最近一条Git Log Commit Id前7位
$GitLogLatestCommitId = (git rev-list Head -n 1 --abbrev-commit)
# 定义脚本日志输出文件路径
$LogFile = "$BuildPath\build_$($ExecuteDate.ToString("yyyyMMddHHmmss")).log"

Write-Host "`nPublish parameters initialize completed." -Foreground $LogForegroundColorEnd

# 开始脚本日志记录
# 注意：脚本执行过程不能中断，否则会导致log file被线程占用，下次执行时会无法删除导致报错
Start-Transcript -Path $LogFile

# 清理缓存文件，垃圾文件
Function Clean-Caches
{
	# 清理log文件
	Write-Host "`nLog files cleaning..." -Foreground $LogForegroundColorStart
	Get-ChildItem -Path "$BuildPath\" -Exclude $LogFile -Include "*.log", "*.zip" -Recurse -Force | Where-Object { $_.FullName -ne $LogFile } | Remove-Item -Force
	Write-Host "Log files clean completed." -Foreground $LogForegroundColorEnd
	
	# 清理项目编译后缓存文件夹
	Write-Host "`nProject build cache files cleaning..." -Foreground $LogForegroundColorStart
	foreach ($packageName in $PackageNames)
	{
		$cacheFolder = "$BuildPath\$packageName"
		Remove-Item -Path $cacheFolder -Recurse -Force -ErrorAction "SilentlyContinue"
	}
	# 清理解决方案
	&$MSBuildExe $SolutionFile /t:Clean
	Write-Host "Project build cache files clean completed." -Foreground $LogForegroundColorEnd
}
Clean-Caches

# 还原NuGet包
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
		&$NuGetExe restore $SolutionFile
		Write-Host "NuGet ReStore completed." -Foreground $LogForegroundColorEnd
	}
	else
	{
		Write-Host "`nNot use NuGet tools." -Foreground $LogForegroundColorStart
	}
}
ReStore-Package

# 构建解决方案
Function Build-Solution
{
	Write-Host "`nStart solution building..." -Foreground $LogForegroundColorStart
	&$MSBuildExe $SolutionFile "/t:Build" "/toolsversion:$MsBuildToolsVersion" "/verbosity:$LogLevel" "/logger:FileLogger,Microsoft.Build;logfile="""$BuildPath\$($SolutionName)_Build_$($Configuration)_$($ExecuteDate.ToString("yyyyMMddHHmmss")).log"""" "/p:Configuration=$Configuration"
	Write-Host "Build solution completed." -Foreground $LogForegroundColorEnd
}
Build-Solution

# 发布项目集
Function Publish-Projects
{
	# Win项目发布到本地文件夹
	foreach ($projectName in $WinProjectNames)
	{
		Write-Host "`nStart $projectName project publishing..." -Foreground $LogForegroundColorStart
		&$MSBuildExe "$($SolutionPath)\$($projectName)\$($projectName).csproj" "/t:Rebuild" "/toolsversion:$MsBuildToolsVersion" "/verbosity:$LogLevel" "/logger:FileLogger,Microsoft.Build;logfile="""$BuildPath\$($projectName)_Publish_$($Configuration)_$($ExecuteDate.ToString("yyyyMMddHHmmss")).log"""" "/p:Configuration=$Configuration" "/p:OutputPath=$($BuildPath)\$($projectName)"
		Write-Host "Publish $projectName project completed." -Foreground $LogForegroundColorEnd
	}
	
	# Web项目发布到本地文件夹
	foreach ($projectName in $WebProjectNames)
	{
		Write-Host "`nStart $projectName project publishing..." -Foreground $LogForegroundColorStart
		&$MSBuildExe "$($SolutionPath)\$($projectName)\$($projectName).csproj" "/t:WebPublish" "/verbosity:$LogLevel" "/logger:FileLogger,Microsoft.Build;logfile="""$BuildPath\$($projectName)_Publish_$($Configuration)_$($ExecuteDate.ToString("yyyyMMddHHmmss")).log"""" "/p:Configuration=$Configuration" "/p:WebPublishMethod=FileSystem" "/p:DeleteExistingFiles=True" "/p:publishUrl=$($BuildPath)\$($projectName)"
		Write-Host "Publish $projectName project completed." -Foreground $LogForegroundColorEnd
	}
}
Publish-Projects

# ZIP打包
Function Zip-Package
{
	foreach ($packageName in $PackageNames)
	{
		Write-Host "`nStart $packageName project packing..." -Foreground $LogForegroundColorStart
		
		$targetFolder = "$BuildPath\$packageName\"
		# exclusion rules. Can use wild cards (*)
		$exclude = "*.config", "*.bak", "*.log", "*.zip" #, "*.pdb", "*.xml", "bin\*.config"
		# get files to compress using exclusion filer
		$files = Get-ChildItem -Path $targetFolder -Exclude $exclude
		
		# compress
		$destination = "$BuildPath\$($packageName)_$($GitLogLatestCommitId)_$($ExecuteDate.ToString("yyyyMMddHHmmss")).zip"
		Compress-Archive -Path $files -DestinationPath $destination -CompressionLevel Optimal
		
		Write-Host "Pack $packageName project completed." -Foreground $LogForegroundColorEnd
	}
}
Zip-Package

# 结束脚本日志记录
Stop-Transcript