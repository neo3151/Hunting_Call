[Setup]
AppName=OUTCALL
AppVersion=1.6.0
DefaultDirName={autopf}\OUTCALL
DefaultGroupName=OUTCALL
UninstallDisplayIcon={app}\OUTCALL.exe
Compression=lzma2
SolidCompression=yes
OutputDir=C:\Users\neo31\Hunting_Call\build\windows\installer
OutputBaseFilename=OUTCALL_Installer_1.6.0
PrivilegesRequired=lowest

[Files]
Source: "C:\Users\neo31\Hunting_Call\build\windows\x64\runner\Release\OUTCALL.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\Users\neo31\Hunting_Call\build\windows\x64\runner\Release\*.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\Users\neo31\Hunting_Call\build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\OUTCALL"; Filename: "{app}\OUTCALL.exe"
Name: "{autodesktop}\OUTCALL"; Filename: "{app}\OUTCALL.exe"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop icon"; GroupDescription: "Additional icons:"; Flags: unchecked
