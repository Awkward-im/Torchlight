unit formChar;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Spin,
  Buttons, tl2char;

type

  { TfmChar }

  TfmChar = class(TForm)
    bbUpdate: TBitBtn;

    cbEnabled  : TCheckBox;
    edName     : TEdit;
    lblSuffix  : TLabel;

    cbImage   : TComboBox;
    lblImage  : TLabel;
    edOriginal: TEdit;

    seScale: TFloatSpinEdit;  lblScale: TLabel;

    gbCoords: TGroupBox;
    lblX: TLabel;  edX: TEdit;
    lblY: TLabel;  edY: TEdit;
    lblZ: TLabel;  edZ: TEdit;

    cbSpell1: TComboBox;  edSpell1: TEdit;
    cbSpell2: TComboBox;  edSpell2: TEdit;
    cbSpell3: TComboBox;  edSpell3: TEdit;
    cbSpell4: TComboBox;  edSpell4: TEdit;

    edLevel      : TEdit;  lblLevel     : TLabel;
    edStrength   : TEdit;  lblStrength  : TLabel;
    edDexterity  : TEdit;  lblDexterity : TLabel;
    edFocus      : TEdit;  lblFocus     : TLabel;
    edVitality   : TEdit;  lblVitality  : TLabel;
    edGold       : TEdit;  lblGold      : TLabel;
    edSkin       : TEdit;  lblSkin      : TLabel;
    edExperience : TEdit;  lblExperience: TLabel;
    edFame       : TEdit;  lblFame      : TLabel;
    edFameExp    : TEdit;  lblFameExp   : TLabel;
    edHealth     : TEdit;  lblHealth    : TLabel;
    edHealthBonus: TEdit;  lblHeathBonus: TLabel;
    edMana       : TEdit;  lblMana      : TLabel;
    edManaBonus  : TEdit;  lblManaBonus : TLabel;
    edMorphTime  : TEdit;  lblMorphTime : TLabel;
    edTownTime   : TEdit;  lblTownTime  : TLabel;

    lbModList: TListBox;

    gbAction: TGroupBox;
    rbActionIdle   : TRadioButton;
    rbActionAttack : TRadioButton;
    rbActionDefence: TRadioButton;

    procedure bbUpdateClick(Sender: TObject);
  private
    FChar :TTL2Character;

    function GetMainFlag:boolean;
    function GetCharFlag:boolean;
    procedure ChangeVisibility;
  public
    procedure FillInfo(aChar:TTL2Character);

    property IsMain:boolean read GetMainFlag;
    property IsChar:boolean read GetCharFlag;
  end;

implementation

{$R *.lfm}

uses
  tl2types,
  tl2db;

function TfmChar.GetCharFlag:boolean;
begin
  result:=FChar.IsChar;//(FChar.Player<>''); //!!
end;

function TfmChar.GetMainFlag:boolean;
begin
  result:=(FChar.Sign=$FF);
end;

procedure TfmChar.ChangeVisibility;
var
  lChar:boolean;
begin
  lChar:=IsChar;

  cbEnabled  .Visible:=not lChar;
  lblTownTime.Visible:=not lChar;
  edTownTime .Visible:=not lChar;
  lblSkin    .Visible:=not lChar;
  edSkin     .Visible:=not lChar;
  gbAction   .Visible:=not lChar;
end;

procedure TfmChar.FillInfo(aChar:TTL2Character);
var
  lid:TL2ID;
  i:integer;
begin
  FChar:=aChar;
  ChangeVisibility;

  cbEnabled.Checked:=aChar.Enabled;

  edName.Text      :=aChar.Name;
  lblSuffix.Caption:=aChar.Suffix;

  if aChar.OriginId<>TL2IdEmpty then
    lid:=aChar.OriginId
  else
    lid:=aChar.ImageId;
  edOriginal.Caption:=GetTL2Class(lid); //!!!!!!!!

  edLevel      .Text:=IntToStr(aChar.Level);
  edStrength   .Text:=IntToStr(aChar.Strength);
  edDexterity  .Text:=IntToStr(aChar.Dexterity);
  edFocus      .Text:=IntToStr(aChar.Focus);
  edVitality   .Text:=IntToStr(aChar.Vitality);
  edGold       .Text:=IntToStr(aChar.Gold);
  edSkin       .Text:=IntToStr(aChar.Skin);
  edExperience .Text:=IntToStr(aChar.Experience);
  edFame       .Text:=IntToStr(aChar.FameLevel);
  edFameExp    .Text:=IntToStr(aChar.FameExp);
  edHealth     .Text:=IntToStr(Round(aChar.Health));
  edHealthBonus.Text:=IntToStr(aChar.HealthBonus);
  edMana       .Text:=IntToStr(Round(aChar.Mana));
  edManaBonus  .Text:=IntToStr(aChar.ManaBonus);
  seScale.Value:=aChar.Scale;
  rbActionIdle   .Checked:=aChar.Action=Idle;
  rbActionAttack .Checked:=aChar.Action=Attack;
  rbActionDefence.Checked:=aChar.Action=Defence;

  edX.Text:=FloatToStrF(aChar.Position.X,ffFixed,-8,2);
  edY.Text:=FloatToStrF(aChar.Position.Y,ffFixed,-8,2);
  edZ.Text:=FloatToStrF(aChar.Position.Z,ffFixed,-8,2);

  lbModList.Clear;
  for i:=0 to High(aChar.ModIds) do
    lbModList.AddItem(GetTL2Mod(aChar.ModIds[i]),nil);
end;

procedure TfmChar.bbUpdateClick(Sender: TObject);
var
  lid:TL2ID;
  i:integer;
begin
  FChar.Enabled:=cbEnabled.Checked;
  FChar.Name:=edName.Text;
{
  if FChar.OriginId<>TL2IdEmpty then
    lid:=FChar.OriginId
  else
    lid:=FChar.ImageId;
  edOriginal.Caption:=GetTL2Pet(lid);
 }
  FChar.Level      :=StrToInt(edLevel      .Text);
  FChar.Strength   :=StrToInt(edStrength   .Text);
  FChar.Dexterity  :=StrToInt(edDexterity  .Text);
  FChar.Focus      :=StrToInt(edFocus      .Text);
  FChar.Vitality   :=StrToInt(edVitality   .Text);
  FChar.Gold       :=StrToInt(edGold       .Text);
  FChar.Skin       :=StrToInt(edSkin       .Text);
  FChar.Experience :=StrToInt(edExperience .Text);
  FChar.FameLevel  :=StrToInt(edFame       .Text);
  FChar.FameExp    :=StrToInt(edFameExp    .Text);
  FChar.Health     :=StrToInt(edHealth     .Text);
  FChar.HealthBonus:=StrToInt(edHealthBonus.Text);
  FChar.Mana       :=StrToInt(edMana       .Text);
  FChar.ManaBonus  :=StrToInt(edManaBonus  .Text);
  FChar.Scale:=seScale.Value;

  if      rbActionIdle   .Checked then FChar.Action:=Idle
  else if rbActionAttack .Checked then FChar.Action:=Attack
  else if rbActionDefence.Checked then FChar.Action:=Defence;
{
  lbModList.Clear;
  for i:=0 to High(FChar.ModIds) do
    lbModList.AddItem(GetTL2Mod(FChar.ModIds[i]),nil);
}
end;

end.
