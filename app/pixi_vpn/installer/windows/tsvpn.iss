#define AppName "TSVPN"
#define AppExeName "pixi_vpn.exe"

#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif

#ifndef Platform
  #define Platform "x64"
#endif

#ifndef BuildDir
  #define BuildDir "build\\windows\\x64\\runner\\Release"
#endif

#ifndef AppIconFile
  #define AppIconFile "..\\windows\\runner\\resources\\app_icon.ico"
#endif

#ifndef WizardSmallImageFile
  #define WizardSmallImageFile "wizard_small.bmp"
#endif

#ifndef WizardImageFile
  #define WizardImageFile "wizard.bmp"
#endif

#ifndef VcRedistX64
  #define VcRedistX64 "redist\\vc_redist.x64.exe"
#endif

#ifndef VcRedistArm64
  #define VcRedistArm64 "redist\\vc_redist.arm64.exe"
#endif

#define HaveVcRedistX64 FileExists(SourcePath + VcRedistX64)
#define HaveVcRedistArm64 FileExists(SourcePath + VcRedistArm64)

[Setup]
AppName={#AppName}
AppVersion={#AppVersion}
DefaultDirName={pf}\{#AppName}
DefaultGroupName={#AppName}
OutputDir=..\output
OutputBaseFilename={#AppName}-Setup-{#AppVersion}-{#Platform}
SetupIconFile={#AppIconFile}
UninstallDisplayIcon={app}\app_icon.ico
WizardSmallImageFile={#WizardSmallImageFile}
WizardImageFile={#WizardImageFile}
Compression=lzma2
SolidCompression=yes
DisableProgramGroupPage=yes
ArchitecturesAllowed=x64 arm64
ArchitecturesInstallIn64BitMode=x64 arm64

[Tasks]
Name: "desktopicon"; Description: "Create a desktop icon"; Flags: unchecked

[Files]
Source: "{#BuildDir}\\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion
Source: "{#AppIconFile}"; DestDir: "{app}"; DestName: "app_icon.ico"; Flags: ignoreversion
#if HaveVcRedistX64
Source: "{#VcRedistX64}"; DestDir: "{tmp}"; Flags: deleteafterinstall ignoreversion
#endif
#if HaveVcRedistArm64
Source: "{#VcRedistArm64}"; DestDir: "{tmp}"; Flags: deleteafterinstall ignoreversion
#endif

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\{#AppExeName}"; IconFilename: "{app}\app_icon.ico"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon; IconFilename: "{app}\app_icon.ico"

[Run]
#if HaveVcRedistX64
Filename: "{tmp}\\vc_redist.x64.exe"; Parameters: "/install /quiet /norestart"; StatusMsg: "Installing Microsoft Visual C++ Runtime (x64)..."; Flags: waituntilterminated runhidden; Check: ShouldInstallVCRedistX64
#endif
#if HaveVcRedistArm64
Filename: "{tmp}\\vc_redist.arm64.exe"; Parameters: "/install /quiet /norestart"; StatusMsg: "Installing Microsoft Visual C++ Runtime (ARM64)..."; Flags: waituntilterminated runhidden; Check: ShouldInstallVCRedistArm64
#endif
Filename: "{app}\{#AppExeName}"; Description: "Launch {#AppName}"; Flags: nowait postinstall skipifsilent

[Code]
function IsArm64: Boolean;
var
  Arch: String;
begin
  Arch := Uppercase(GetEnv('PROCESSOR_ARCHITEW6432'));
  if Arch = '' then
    Arch := Uppercase(GetEnv('PROCESSOR_ARCHITECTURE'));
  Result := Arch = 'ARM64';
end;

function IsVCRedistInstalledX64: Boolean;
var
  Installed: Cardinal;
begin
  Result := RegQueryDWordValue(HKLM64,
    'SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64',
    'Installed', Installed) and (Installed = 1);
end;

function IsVCRedistInstalledArm64: Boolean;
var
  Installed: Cardinal;
begin
  Result := RegQueryDWordValue(HKLM64,
    'SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\ARM64',
    'Installed', Installed) and (Installed = 1);
end;

function ShouldInstallVCRedistX64: Boolean;
begin
  Result := (not IsArm64) and (not IsVCRedistInstalledX64);
end;

function ShouldInstallVCRedistArm64: Boolean;
begin
  Result := IsArm64 and (not IsVCRedistInstalledArm64);
end;
