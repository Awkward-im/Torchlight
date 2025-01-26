unit formSettings;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Buttons, EditBtn, ComCtrls;


type
  TOnSGSettingsChanged = procedure of object;

type

  { TfmSettings }

  TfmSettings = class(TForm)
    bbSave: TBitBtn;
    bbRescan: TBitBtn;
    cbShowAll : TCheckBox;
    cbShowTech: TCheckBox;
    cbIdAsHex : TCheckBox;
    cbBackup  : TCheckBox;
    cbSaveScan: TCheckBox;
    edDBFileTL1: TFileNameEdit;
    edIconDirTL1: TDirectoryEdit;
    edSaveDir: TDirectoryEdit;
    edModsDir: TDirectoryEdit;
    edIconDirTL2 : TDirectoryEdit;
    gbModsScan: TGroupBox;
    lblTL1Icon: TLabel;
    lblTL2DB: TLabel;
    lblTL1DB: TLabel;
    lblSGFolder: TLabel;
    lblModsDir: TLabel;
    lblIconDir: TLabel;
    edDBFileTL2  : TFileNameEdit;
    lblDBFile : TLabel;
    gbShow: TGroupBox;
    lblTL2Icon: TLabel;
    memLog: TMemo;

    procedure bbRescanClick(Sender: TObject);
    procedure bbSaveClick(Sender: TObject);
    procedure edModsDirChange(Sender: TObject);
    procedure SettingsChanged(Sender: TObject);
    procedure FormCreate(Sender: TObject);

  private
    FDBState:integer;
    FOnSettingsChanged:TOnSGSettingsChanged;

    function AddToLog(var adata: string): integer;
    procedure LoadSettings;
    function GetIconDir:string;

  public

    property IconDir:string read GetIconDir;
    property DBState:integer read FDBState write FDBState;
    property OnSettingsChanged:TOnSGSettingsChanged
        read  FOnSettingsChanged
        write FOnSettingsChanged;
  end;

var
  fmSettings:TfmSettings;
  INIFileName:string;


function TextID(const aId:int64):string;

implementation

{$R *.lfm}

uses
  IniFiles,
  Windirs,
  rgdb,
  UnitScan,
  logging,
  RGGlobal;

{ TfmSettings }

const
  ModsTL1Path = '%USERPROFILE%/AppData/Roaming/runic games/torchlight/mods';
  ModsPath    = '%USERPROFILE%\Documents\My Games\Runic Games\Torchlight 2\mods';
  SavePath    = '%USERPROFILE%\Documents\My Games\Runic Games\Torchlight 2\Save';

const
  sSettings   = 'Settings';
  sDBFileTL2  = 'dbfile';
  sDBFileTL1  = 'dbfile_tl1';
  sIconDirTL2 = 'icondir';
  sIconDirTL1 = 'icondir_tl1';
  sSaveDir    = 'savedir';
  sModsDir    = 'modsdir';
  sSaveScan   = 'savescan';
  sShowTech   = 'showtech';
  sIdAsHex    = 'idashex';
  sShowAll    = 'showall';
  sBackup     = 'backup';

resourcestring
  rsDBNotFound =
    'Database file not found.'#13#10+
    'Check settings and rescan if needs';
  rsNeedToScan =
    'Better to scan your mod collection'#13#10+
    'if you didn''t it before or it was changed';


function TextID(const aId:int64):string;
begin
  if fmSettings.cbIdAsHex.Checked then
    result:='0x'+HexStr(aid,16)
  else
    Str(aid,result);
end;

function TfmSettings.GetIconDir:string;
begin
  if rgdb.GameVersion=verTL1 then
    result:=edIconDirTL1.Text
  else
    result:=edIconDirTL2.Text;
end;

procedure TfmSettings.bbSaveClick(Sender: TObject);
var
  config:TIniFile;
begin
  config:=TMemIniFile.Create(INIFileName,[ifoEscapeLineFeeds,ifoStripQuotes]);

  config.WriteString (sSettings,sDBFileTL2 ,edDBFileTL2 .Text);
  config.WriteString (sSettings,sDBFileTL1 ,edDBFileTL1 .Text);
  config.WriteString (sSettings,sIconDirTL2,edIconDirTL2.Text);
  config.WriteString (sSettings,sIconDirTL1,edIconDirTL1.Text);
  config.WriteString (sSettings,sSaveDir   ,edSaveDir .Text);
  config.WriteBool   (sSettings,sBackup    ,cbBackup  .Checked);

  config.WriteBool   (sSettings,sShowAll   ,cbShowAll .Checked);
  config.WriteBool   (sSettings,sShowTech  ,cbShowTech.Checked);
  config.WriteBool   (sSettings,sIdAsHex   ,cbIdAsHex .Checked);

  config.WriteString (sSettings,sModsDir   ,edModsDir .Text);
  config.WriteBool   (sSettings,sSaveScan  ,cbSaveScan.Checked);

  config.UpdateFile;

  config.Free;
end;

procedure TfmSettings.LoadSettings;
var
  config:TIniFile;
  lprof:string;
begin
  lprof:=GetWindowsSpecialDir(CSIDL_PROFILE);

  config:=TIniFile.Create(INIFileName,[ifoEscapeLineFeeds,ifoStripQuotes]);

  edDBFileTL2 .Text   :=config.ReadString(sSettings,sDBFileTL2 ,TL2DataBase);
  edDBFileTL1 .Text   :=config.ReadString(sSettings,sDBFileTL1 ,TL2DataBase);
  edIconDirTL2.Text   :=config.ReadString(sSettings,sIconDirTL2,'icons');
  edIconDirTL1.Text   :=config.ReadString(sSettings,sIconDirTL1,'iconstl1');
  edSaveDir   .Text   :=config.ReadString(sSettings,sSaveDir   ,SavePath);
  cbBackup    .Checked:=config.ReadBool  (sSettings,sBackup    ,true);

  cbShowAll   .Checked:=config.ReadBool  (sSettings,sShowAll ,false);
  cbShowTech  .Checked:=config.ReadBool  (sSettings,sShowTech,false);
  cbIdAsHex   .Checked:=config.ReadBool  (sSettings,sIdAsHex ,false);

  edModsDir   .Text   :=config.ReadString(sSettings,sModsDir ,ModsPath);
  cbSaveScan  .Checked:=config.ReadBool  (sSettings,sSaveScan,true);

  if (edSaveDir.Text=SavePath) or (edSaveDir.Text='') then
      edSaveDir.Text:=StringReplace(SavePath,'%USERPROFILE%',lprof,[]);
  if (edModsDir.Text=ModsPath) or (edModsDir.Text='') then
      edModsDir.Text:=StringReplace(ModsPath,'%USERPROFILE%',lprof,[]);

  config.Free;
end;

procedure TfmSettings.edModsDirChange(Sender: TObject);
begin
  bbRescan.Enabled:=edModsDir.Text<>'';
end;

function TfmSettings.AddToLog(var adata:string):integer;
begin
  memLog.Append(adata);
  Application.ProcessMessages;
  adata:='';
  result:=0;
end;

procedure TfmSettings.bbRescanClick(Sender: TObject);
var
  ldb:pointer;
  llog:TLogOnAdd;
begin
  bbRescan.Enabled:=false;
  memLog.Clear;
  llog:=RGLog.OnAdd;
  RGLog.OnAdd:=@AddToLog;
{
  if FDBState=0 then
  begin
    FreeBases;
    FDBState:=-1;
  end;
}
  RGOpenBase(ldb,edDBFileTL2.Text);
  ScanPath  (ldb,edModsDir.Text);
  if cbSaveScan.Checked then
    RGSaveBase(ldb,edDBFileTL2.Text);

  if FDBState=0 then
    RGDBUseBase(ldb)
  else
    RGCloseBase(ldb,'');

  RGLog.OnAdd:=llog;
  memLog.Append('Done!');
  bbRescan.Enabled:=true;
end;

procedure TfmSettings.SettingsChanged(Sender: TObject);
begin
 if Assigned(FOnSettingsChanged) then FOnSettingsChanged();
end;

procedure TfmSettings.FormCreate(Sender: TObject);
begin
  fmSettings:=Self;

  INIFileName:=ChangeFileExt(ParamStr(0),'.ini');

  LoadSettings;

  if not FileExists(edDBFileTL2.Text) then
  begin
    ShowMessage(rsDBNotFound);
    Self.Show;
    Self.Activate;
  end;

  if not FileExists(INIFileName) then
  begin
    ShowMessage(rsNeedToScan);
    Self.Show;
    Self.Activate;
  end;

  //  FDBState:=LoadBases(edDBFileTL2.Text);
  FDBState:=-1;
end;

end.
