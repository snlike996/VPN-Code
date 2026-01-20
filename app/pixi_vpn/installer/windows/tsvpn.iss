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

#ifndef VcRedistX64
  #define VcRedistX64 "redist\\vc_redist.x64.exe"
#endif

#define HaveVcRedistX64 FileExists(SourcePath + VcRedistX64)

[Setup]
AppName={#AppName}
AppVersion={#AppVersion}
DefaultDirName={pf}\{#AppName}
DefaultGroupName={#AppName}
OutputDir=..\output
OutputBaseFilename={#AppName}-Setup-{#AppVersion}-{#Platform}
Compression=lzma2
SolidCompression=yes
DisableProgramGroupPage=yes
ArchitecturesAllowed=x64 arm64
ArchitecturesInstallIn64BitMode=x64 arm64

[Tasks]
Name: "desktopicon"; Description: "Create a desktop icon"; Flags: unchecked

[Files]
Source: "{#BuildDir}\\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion
#if HaveVcRedistX64
Source: "{#VcRedistX64}"; DestDir: "{tmp}"; Flags: deleteafterinstall ignoreversion
#endif

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Run]
#if HaveVcRedistX64
Filename: "{tmp}\\vc_redist.x64.exe"; Parameters: "/install /quiet /norestart"; StatusMsg: "Installing Microsoft Visual C++ Runtime..."; Flags: waituntilterminated runhidden; Check: ShouldInstallVCRedist
#endif
Filename: "{app}\{#AppExeName}"; Description: "Launch {#AppName}"; Flags: nowait postinstall skipifsilent

[Code]
function IsVCRedistInstalled: Boolean;
var
  Installed: Cardinal;
begin
  Result := RegQueryDWordValue(HKLM64,
    'SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64',
    'Installed', Installed) and (Installed = 1);
end;

function ShouldInstallVCRedist: Boolean;
begin
  Result := not IsVCRedistInstalled;
end;
