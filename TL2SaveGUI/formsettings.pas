unit formSettings;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Spin, StdCtrls,
  Buttons;

type

  { TfmSettings }

  TfmSettings = class(TForm)
    bbSave: TBitBtn;
    cbShowTech: TCheckBox;
    seHPperLvl    : TFloatSpinEdit; lblHPperLvl    : TLabel;
    seMPperLvl    : TFloatSpinEdit; lblMPperLvl    : TLabel;
    seStatPerLvl  : TSpinEdit     ; lblStatPerLvl  : TLabel;
    seSkillPerLvl : TSpinEdit     ; lblSkillPerLvl : TLabel;
    seSkillPerFame: TSpinEdit     ; lblSkillPerFame: TLabel;
    procedure bbSaveClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    procedure LoadSettings;

  public

  end;


implementation

{$R *.lfm}

uses
  IniFiles;

{ TfmSettings }

const
  INIFileName   = 'tl2sg.ini';
  sSettings     = 'Settings';
  sShowTech     = 'showtech';
  sHPperLvl     = 'HPperLevel';
  sMPperLvl     = 'MPperLevel';
  sStatPerLvl   = 'StatPerLevel';
  sSkillPerLvl  = 'SkillPerLevel';
  sSkillPerFame = 'SkillPerFame';

const
  DefHPperLvl     = 3.6;
  DefMPperLvl     = 0.5;
  DefStatPerLvl   = 5;
  DefSkillPerLvl  = 1;
  DefSkillPerFame = 1;

procedure TfmSettings.bbSaveClick(Sender: TObject);
var
  config:TIniFile;
begin
  config:=TIniFile.Create(INIFileName,[ifoEscapeLineFeeds,ifoStripQuotes]);
  config.WriteBool(sSettings,sShowTech,cbShowTech.Checked);

  config.WriteFloat  (sSettings,sHPperLvl    ,seHPperLvl    .Value);
  config.WriteFloat  (sSettings,sMPperLvl    ,seMPperLvl    .Value);
  config.WriteInteger(sSettings,sStatPerLvl  ,seStatPerLvl  .Value);
  config.WriteInteger(sSettings,sSkillPerLvl ,seSkillPerLvl .Value);
  config.WriteInteger(sSettings,sSkillPerFame,seSkillPerFame.Value);

  config.UpdateFile;
  config.Free;
end;

procedure TfmSettings.LoadSettings;
var
  config:TIniFile;
begin
  config:=TIniFile.Create(INIFileName,[ifoEscapeLineFeeds,ifoStripQuotes]);

  cbShowTech.Checked:=config.ReadBool(sSettings,sShowTech,false);

  seHPperLvl    .Value:=config.ReadFloat  (sSettings,sHPperLvl    ,DefHPperLvl    );
  seMPperLvl    .Value:=config.ReadFloat  (sSettings,sMPperLvl    ,DefMPperLvl    );
  seStatPerLvl  .Value:=config.ReadInteger(sSettings,sStatPerLvl  ,DefStatPerLvl  );
  seSkillPerLvl .Value:=config.ReadInteger(sSettings,sSkillPerLvl ,DefSkillPerLvl );
  seSkillPerFame.Value:=config.ReadInteger(sSettings,sSkillPerFame,DefSkillPerFame);

  config.Free;
end;

procedure TfmSettings.FormCreate(Sender: TObject);
begin
  LoadSettings;
end;

end.

