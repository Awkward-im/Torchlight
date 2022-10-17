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
    cbReloadDB: TCheckBox;
    cbShowAll : TCheckBox;
    cbShowTech: TCheckBox;
    cbIdAsHex : TCheckBox;
    cbBackup  : TCheckBox;
    cbSaveScan: TCheckBox;
    edModsDir: TDirectoryEdit;
    edIconDir : TDirectoryEdit;
    gbModsScan: TGroupBox;
    lblModsDir: TLabel;
  lblIconDir: TLabel;
    edDBFile  : TFileNameEdit;   lblDBFile : TLabel;
    gbShow: TGroupBox;
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

  public

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
  tl2db,
  UnitScan,
  logging,
  RGGlobal;

{ TfmSettings }

const
  SavePath = '"Documents\My Games\Runic Games\Torchlight 2\save\"';

const
  sSettings   = 'Settings';
  sDBFile     = 'dbfile';
  sIconDir    = 'icondir';
  sModsDir    = 'modsdir';
  sSaveScan   = 'savescan';
  sShowTech   = 'showtech';
  sIdAsHex    = 'idashex';
  sShowAll    = 'showall';
  sBackup     = 'backup';
  sReloadDB   = 'reloaddb';

function TextID(const aId:int64):string;
begin
  if fmSettings.cbIdAsHex.Checked then
    result:='0x'+HexStr(aid,16)
  else
    Str(aid,result);
end;

procedure TfmSettings.bbSaveClick(Sender: TObject);
var
  config:TIniFile;
begin
  config:=TIniFile.Create(INIFileName,[ifoEscapeLineFeeds,ifoStripQuotes]);

  config.WriteString (sSettings,sDBFile    ,edDBFile  .Text);
  config.WriteString (sSettings,sIconDir   ,edIconDir .Text);
  config.WriteBool   (sSettings,sBackup    ,cbBackup  .Checked);
  config.WriteBool   (sSettings,sReloadDB  ,cbReloadDB.Checked);

  config.WriteBool   (sSettings,sShowAll   ,cbShowAll .Checked);
  config.WriteBool   (sSettings,sShowTech  ,cbShowTech.Checked);
  config.WriteBool   (sSettings,sIdAsHex   ,cbIdAsHex .Checked);

  config.WriteString (sSettings,sModsDir   ,edModsDir .Text);
  config.WriteBool   (sSettings,sSaveScan  ,cbSaveScan.Checked);

  config.UpdateFile;

  config.Free;
end;

procedure TfmSettings.edModsDirChange(Sender: TObject);
begin
  bbRescan.Enabled:=edModsDir.Text<>'';
end;

function TfmSettings.AddToLog(var adata:string):integer;
begin
  memLog.Append(adata);
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
  RGOpenBase(ldb,edDBFile.Text);
  ScanPath(ldb,edModsDir.Text);
  if cbSaveScan.Checked then
    RGSaveBase(ldb,edDBFile.Text);

  if FDBState=0 then
    UseBase(ldb)
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

procedure TfmSettings.LoadSettings;
var
  config:TIniFile;
begin
  config:=TIniFile.Create(INIFileName,[ifoEscapeLineFeeds,ifoStripQuotes]);

  edDBFile    .Text   :=config.ReadString(sSettings,sDBFile  ,TL2DataBase);
  edIconDir   .Text   :=config.ReadString(sSettings,sIconDir ,'icons');
  cbBackup    .Checked:=config.ReadBool  (sSettings,sBackup  ,true);
  cbReloadDB  .Checked:=config.ReadBool  (sSettings,sReloadDB,false);

  cbShowAll   .Checked:=config.ReadBool  (sSettings,sShowAll ,false);
  cbShowTech  .Checked:=config.ReadBool  (sSettings,sShowTech,false);
  cbIdAsHex   .Checked:=config.ReadBool  (sSettings,sIdAsHex ,false);

  edModsDir   .Text   :=config.ReadString(sSettings,sModsDir ,'');
  cbSaveScan  .Checked:=config.ReadBool  (sSettings,sSaveScan,true);

  config.Free;
end;

procedure TfmSettings.FormCreate(Sender: TObject);
begin
  fmSettings:=Self;

  INIFileName:=ChangeFileExt(ParamStr(0),'.ini');

  LoadSettings;

  if not FileExists(edDBFile.Text) then
  begin
    ShowMessage(
        'Database file not found.'#13#10+
        'Check settings and rescan if needs');
    Self.Show;
    Self.Activate;
  end;

//  FDBState:=LoadBases(edDBFile.Text);
  FDBState:=-1;
end;

end.
