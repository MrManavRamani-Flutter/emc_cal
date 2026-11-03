; Script generated for Inno Setup 6.0+
; OM MAVTAR GROUP - Embroidery Production Calculator Windows Installer Script

#define MyAppName "OM MAVTAR GROUP - Embroidery Calculator"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "OM MAVTAR GROUP"
#define MyAppExeName "emb_cal.exe"
#define MyAppAssocName MyAppName + " File"
#define MyAppAssocExt ".embcal"
#define MyAppAssocKey StringChange(MyAppAssocName, " ", "") + MyAppAssocExt

[Setup]
; Unique application GUID
AppId={{9F57BA42-D64B-4819-B581-80C261EC73A1}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\OM MAVTAR GROUP\Embroidery Calculator
DefaultGroupName=OM MAVTAR GROUP
AllowNoIcons=yes
OutputDir=..\..\dist
OutputBaseFilename=OM_MAVTAR_Calculator_v1.0_Setup
SetupIconFile=..\runner\resources\app_icon.ico
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64
DisableWelcomePage=no
DisableDirPage=no
PrivilegesRequired=lowest
UninstallDisplayIcon={app}\{#MyAppExeName}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
; Copy all build release files, DLLs, assets, and folders
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\Run_OM_MAVTAR_Calculator.bat"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\{#MyAppExeName}"
Name: "{group}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon; IconFilename: "{app}\{#MyAppExeName}"

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
