# AutoBuild Script using MSBuild.exe
$baseDrive = "L:\";
$exePath = "L:\Visual Studio 2019\MSBuild\Current\Bin\amd64";

$projectPath = "L:\NetCoreApiProject";
$csprojName = "NetCoreApiProject.csproj";

cd $baseDrive ;
cd $exePath;
./MSBuild.exe 