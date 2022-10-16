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
    cbReloadDB: TCheckBox;
    cbShowAll : TCheckBox;
    cbShowTech: TCheckBox;
    cbIdAsHex : TCheckBox;
    cbBackup  : TCheckBox;
    edIconDir : TDirectoryEdit;  lblIconDir: TLabel;
    edDBFile  : TFileNameEdit;   lblDBFile : TLabel;
    gbShow: TGroupBox;

    procedure bbSaveClick(Sender: TObject);
    procedure SettingsChanged(Sender: TObject);
    procedure FormCreate(Sender: TObject);

  private
    FOnSettingsChanged:TOnSGSettingsChanged;

    procedure LoadSettings;

  public

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
  RGGlobal;

{ TfmSettings }

const
  SavePath = '"Documents\My Games\Runic Games\Torchlight 2\save\"';

const
  sSettings   = 'Settings';
  sDBFile     = 'dbfile';
  sIconDir    = 'icondir';
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

  config.UpdateFile;

  config.Free;
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

  config.Free;
end;

procedure TfmSettings.FormCreate(Sender: TObject);
begin
  fmSettings:=Self;

  INIFileName:=ChangeFileExt(ParamStr(0),'.ini');

  LoadSettings;
end;

end.
