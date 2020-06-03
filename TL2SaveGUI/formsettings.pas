unit formSettings;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Spin, StdCtrls,
  Buttons, EditBtn;

const
  INIFileName   = 'tl2sg.ini';

type

  { TfmSettings }

  TfmSettings = class(TForm)
    bbSave: TBitBtn;
    cbShowTech: TCheckBox;
    cbIdAsHex: TCheckBox;
    edIconDir: TDirectoryEdit;
    edDBFile: TFileNameEdit;
    lblDBFile: TLabel;
    lblIconDir: TLabel;
    procedure bbSaveClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    procedure LoadSettings;

  public

  end;

var
  fmSettings:TfmSettings;

implementation

{$R *.lfm}

uses
  IniFiles;

{ TfmSettings }

const
  sSettings = 'Settings';
  sShowTech = 'showtech';
  sIdAsHex  = 'idashex';
  sDBFile   = 'dbfile';
  sIconDir  = 'icondir';

procedure TfmSettings.bbSaveClick(Sender: TObject);
var
  config:TIniFile;
begin
  config:=TIniFile.Create(INIFileName,[ifoEscapeLineFeeds,ifoStripQuotes]);
  config.WriteBool  (sSettings,sShowTech,cbShowTech.Checked);
  config.WriteBool  (sSettings,sIdAsHex ,cbIdAsHex .Checked);
  config.WriteString(sSettings,sDBFile  ,edDBFile  .Text);
  config.WriteString(sSettings,sIcondir ,edIconDir .Text);

  config.UpdateFile;
  config.Free;
end;

procedure TfmSettings.LoadSettings;
var
  config:TIniFile;
begin
  config:=TIniFile.Create(INIFileName,[ifoEscapeLineFeeds,ifoStripQuotes]);

  cbShowTech.Checked:=config.ReadBool  (sSettings,sShowTech,false);
  cbIdAsHex .Checked:=config.ReadBool  (sSettings,sIdAsHex ,false);
  edDBFile  .Text   :=config.ReadString(sSettings,sDBFile  ,'');
  edIconDir .Text   :=config.ReadString(sSettings,sIconDir ,'icons');

  config.Free;
end;

procedure TfmSettings.FormCreate(Sender: TObject);
begin
  fmSettings:=Self;

  LoadSettings;
end;

end.

