unit formSettings;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Buttons, EditBtn, ComCtrls;

const
  LM_TL2_COMMAND  = $400 + 1;
  TL2_INIT    = 0;
  TL2_SETTING = 1;

const
  INIFileName   = 'tl2sg.ini';

type

  { TfmSettings }

  TfmSettings = class(TForm)
    bbSave: TBitBtn;
    cbReloadDB: TCheckBox;
    rbAdditional: TRadioButton;
    rbBaseOnly: TRadioButton;
    rbShowAll: TRadioButton;
    cbShowTech: TCheckBox;
    cbIdAsHex: TCheckBox;
    cbBasic: TCheckBox;
    cbClass: TCheckBox;
    cbBackup: TCheckBox;
    rbDetailed: TRadioButton;
    edIconDir: TDirectoryEdit;
    edDBFile: TFileNameEdit;
    gbShow: TGroupBox;
    gbEdit: TGroupBox;
    lblDBFile: TLabel;
    lblIconDir: TLabel;
    procedure bbSaveClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure rbShowModeClick(Sender: TObject);
  private
    procedure LoadSettings;

  public

  end;

var
  fmSettings:TfmSettings;


const
  smJustBase = 0;
  smMore     = 1;
  smEvenMore = 2;
  smFull     = 3;

function GetShowMode:integer;


implementation

{$R *.lfm}

uses
  IniFiles;

{ TfmSettings }

const
  SavePath = '"Documents\My Games\Runic Games\Torchlight 2\save\"';

const
  sSettings   = 'Settings';
  sDBFile     = 'dbfile';
  sIconDir    = 'icondir';
  sShowTech   = 'showtech';
  sIdAsHex    = 'idashex';
  sShowWhat   = 'showmode';
  sClass      = 'editclass';
  sBasic      = 'editbasic';
  sBackup     = 'backup';
  sReloadDB   = 'reloaddb';

var
  ShowMode:integer;

function GetShowMode:integer; inline;
begin
  result:=ShowMode;
end;

procedure TfmSettings.bbSaveClick(Sender: TObject);
var
  config:TIniFile;
begin
  config:=TIniFile.Create(INIFileName,[ifoEscapeLineFeeds,ifoStripQuotes]);

  config.WriteString (sSettings,sDBFile    ,edDBFile    .Text);
  config.WriteString (sSettings,sIcondir   ,edIconDir   .Text);
  config.WriteBool   (sSettings,sBackup    ,cbBackup    .Checked);
  config.WriteBool   (sSettings,sReloadDB  ,cbReloadDB  .Checked);

  config.WriteInteger(sSettings,sShowWhat  ,ShowMode);
  config.WriteBool   (sSettings,sShowTech  ,cbShowTech  .Checked);
  config.WriteBool   (sSettings,sIdAsHex   ,cbIdAsHex   .Checked);

  config.WriteBool   (sSettings,sBasic     ,cbBasic     .Checked);
  config.WriteBool   (sSettings,sClass     ,cbClass     .Checked);
  config.UpdateFile;

  config.Free;
end;

procedure TfmSettings.LoadSettings;
var
  config:TIniFile;
begin
  config:=TIniFile.Create(INIFileName,[ifoEscapeLineFeeds,ifoStripQuotes]);

  edDBFile    .Text   :=config.ReadString (sSettings,sDBFile    ,'');
  edIconDir   .Text   :=config.ReadString (sSettings,sIconDir   ,'icons');
  cbBackup    .Checked:=config.ReadBool   (sSettings,sBackup    ,true);
  cbReloadDB  .Checked:=config.ReadBool   (sSettings,sReloadDB  ,false);

  ShowMode            :=config.ReadInteger(sSettings,sShowWhat  ,smJustBase);
  cbShowTech  .Checked:=config.ReadBool   (sSettings,sShowTech  ,false);
  cbIdAsHex   .Checked:=config.ReadBool   (sSettings,sIdAsHex   ,false);

  cbBasic     .Checked:=config.ReadBool   (sSettings,sBasic     ,true);
  cbClass     .Checked:=config.ReadBool   (sSettings,sClass     ,false);

  config.Free;

  rbBaseOnly  .Checked:=ShowMode=smJustBase;
  rbAdditional.Checked:=ShowMode=smMore;
  rbDetailed  .Checked:=ShowMode=smEvenMore;
  rbShowAll   .Checked:=ShowMode=smFull;
end;

procedure TfmSettings.FormCreate(Sender: TObject);
begin
  fmSettings:=Self;

  LoadSettings;
end;

procedure TfmSettings.rbShowModeClick(Sender: TObject);
begin
  if rbBaseOnly  .Checked then ShowMode:=smJustBase;
  if rbAdditional.Checked then ShowMode:=smMore;
  if rbDetailed  .Checked then ShowMode:=smEvenMore;
  if rbShowAll   .Checked then ShowMode:=smFull;
end;

end.

