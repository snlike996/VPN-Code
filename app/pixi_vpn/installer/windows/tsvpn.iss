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

[Setup]
AppName={#AppName}
AppVersion={#AppVersion}
DefaultDirName={pf}\{#AppName}
DefaultGroupName={#AppName}
OutputDir=output
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

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExeName}"; Description: "Launch {#AppName}"; Flags: nowait postinstall skipifsilent
