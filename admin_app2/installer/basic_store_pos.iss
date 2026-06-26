; ============================================================
; Basic Store POS — Inno Setup skripti
; Flutter Windows release build'ini bitta setup.exe ga qadoqlaydi.
;
; Oldindan:
;   1) cd admin_app2 && flutter build windows --release
;   2) (kerak bo'lsa) vc_redist.x64.exe ni installer\redist\ ga yuklab qo'ying
;      https://aka.ms/vs/17/release/vc_redist.x64.exe
; Qadoqlash:
;   "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer\basic_store_pos.iss
; Natija: installer\dist\BasicStorePOS-Setup.exe
; ============================================================

#define MyAppName "Basic Store POS"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Basic Store"
#define MyAppExeName "admin_app.exe"
#define BuildDir "..\build\windows\x64\runner\Release"

[Setup]
AppId={{B5A3E1C2-9F4D-4C7B-8E6A-1234567890AB}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\Basic Store POS
DefaultGroupName=Basic Store POS
DisableProgramGroupPage=yes
OutputDir=dist
OutputBaseFilename=BasicStorePOS-Setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
SetupIconFile=..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
PrivilegesRequired=admin

[Languages]
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: checkedonce

[Files]
; Flutter ilova fayllari (exe + DLL'lar + data/ papkasi)
Source: "{#BuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; Visual C++ runtime (mavjud bo'lsa qo'shiladi)
Source: "redist\vc_redist.x64.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall skipifsourcedoesntexist

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
; VC++ runtime kerak bo'lsa jim o'rnatamiz
Filename: "{tmp}\vc_redist.x64.exe"; Parameters: "/quiet /norestart"; StatusMsg: "Visual C++ runtime o'rnatilmoqda..."; Check: VCRedistNeeded; Flags: skipifdoesntexist
; O'rnatish tugagach ilovani ishga tushirish
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#MyAppName}}"; Flags: nowait postinstall skipifsilent

[Code]
function VCRedistNeeded(): Boolean;
begin
  // x64 VC++ 2015-2022 runtime o'rnatilmagan bo'lsa true
  Result := not RegKeyExists(HKLM, 'SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64');
end;
