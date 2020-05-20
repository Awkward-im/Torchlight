unit formChar;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Spin,
  tl2save, tl2char;

type

  { TfmPet }

  { TfmChar }

  TfmChar = class(TForm)
    cbEnabled : TCheckBox;
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
  private
    SChar :TTL2Character;

    function GetMainFlag:boolean;

  public
    procedure FillInfo(aChar:TTL2Character);

    property IsMain:boolean read GetMainFlag;
  end;

implementation

{$R *.lfm}

uses
  tl2types,
  tl2db;

function TfmChar.GetMainFlag:boolean;
begin
  result:=SChar.Sign=$FF;
end;

procedure TfmChar.FillInfo(aChar:TTL2Character);
var
  lid:TL2ID;
  i:integer;
begin
  SChar:=aChar;

  cbEnabled.Checked:=aChar.Enabled;

  edName.Text:=aChar.Name;
  if aChar.OriginId<>TL2IdEmpty then
    lid:=aChar.OriginId
  else
    lid:=aChar.ImageId;
  edOriginal.Caption:=GetTL2Class(lid);

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

(*
procedure TfmPet.bbUpdateClick(Sender: TObject);
var
  lPet:TTL2Character;
  lid:TL2ID;
  i:integer;
begin
  lPet:=aSGame.PetInfo[PetIndex];

  lPet.Enabled:=cbEnabled.Checked;
  lPet.Name:=edName.Text;
{
  if lPet.OriginId<>TL2IdEmpty then
    lid:=lPet.OriginId
  else
    lid:=lPet.ImageId;
  edOriginal.Caption:=GetTL2Pet(lid);
 }
  Val(edLevel      .Text,lPet.Level      );
  Val(edStrength   .Text,lPet.Strength   );
  Val(edDexterity  .Text,lPet.Dexterity  );
  Val(edFocus      .Text,lPet.Focus      );
  Val(edVitality   .Text,lPet.Vitality   );
  Val(edGold       .Text,lPet.Gold       );
  Val(edSkin       .Text,lPet.Skin       );
  Val(edExperience .Text,lPet.Experience );
  Val(edFame       .Text,lPet.FameLevel  );
  Val(edFameExp    .Text,lPet.FameExp    );
  Val(edHealth     .Text,lPet.Health     );
  Val(edHealthBonus.Text,lPet.HealthBonus);
  Val(edMana       .Text,lPet.Mana       );
  Val(edManaBonus  .Text,lPet.ManaBonus  );
  lPet.Scale:=seScale.Value;

  if      rbActionIdle   .Checked then lPet.Action:=Idle
  else if rbActionAttack .Checked then lPet.Action:=Attack
  else if rbActionDefence.Checked then lPet.Action:=Defence;
{
  lbModList.Clear;
  for i:=0 to High(lPet.ModIds) do
    lbModList.AddItem(GetTL2Mod(lPet.ModIds[i]),nil);
}
end;
*)
end.
