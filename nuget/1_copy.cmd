REM build solution in RELEASe mode first
copy ..\src\PackageInstaller\bin\Release\PackageInstaller.exe _DEV\Deployment\TDS.PackageInstaller\
copy ..\src\HedgehogDevelopment.TDS.PackageInstallerService\bin\Release\HedgehogDevelopment.TDS.PackageInstallerService.dll _DEV\Deployment\TDS.PackageInstaller\
copy ..\src\PackageInstaller\bin\Release\NDesk.Options.dll _DEV\Deployment\TDS.PackageInstaller\
