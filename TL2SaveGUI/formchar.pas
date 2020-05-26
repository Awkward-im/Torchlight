unit formChar;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Spin, Buttons,
  tl2char, tl2db;

type

  { TfmChar }

  TfmChar = class(TForm)
    bbUpdate: TBitBtn;

    cbEnabled  : TCheckBox;
    cbSpell1: TComboBox;
    cbSpell2: TComboBox;
    cbSpell3: TComboBox;
    cbSpell4: TComboBox;
    edName     : TEdit;
    cbSpellLvl1: TComboBox;
    cbSpellLvl2: TComboBox;
    cbSpellLvl3: TComboBox;
    cbSpellLvl4: TComboBox;
    gbSpells: TGroupBox;
    lblSuffix  : TLabel;

    cbImage   : TComboBox;
    lblImage  : TLabel;
    edOriginal: TEdit;

    seScale: TFloatSpinEdit;  lblScale: TLabel;

    gbCoords: TGroupBox;
    lblX: TLabel;  edX: TEdit;
    lblY: TLabel;  edY: TEdit;
    lblZ: TLabel;  edZ: TEdit;


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
    procedure cbSpellChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    FChar :TTL2Character;
    FSpells:tSkillArray;

    procedure GetCharSpell(cb: TComboBox; idx: integer);
    function GetMainFlag:boolean;
    function GetCharFlag:boolean;
    function GetPetFlag :boolean;
    procedure ChangeVisibility;
    procedure SetCharSpell(cb: TComboBox; idx: integer);
  public
    procedure FillInfo(aChar:TTL2Character);

    property IsMain:boolean read GetMainFlag;
    property IsChar:boolean read GetCharFlag;
    property IsPet :boolean read GetPetFlag;
  end;

implementation

{$R *.lfm}

uses
  tl2types;

function TfmChar.GetCharFlag:boolean;
begin
  result:=FChar.IsChar;
end;

function TfmChar.GetPetFlag:boolean;
begin
  result:=FChar.IsPet;
end;

function TfmChar.GetMainFlag:boolean;
begin
  result:=(FChar.Sign=$FF);
end;

procedure TfmChar.ChangeVisibility;
var
  lChar,lPet:boolean;
begin
  lChar:=IsChar;
  lPet :=IsPet;

  cbEnabled  .Visible:=lPet;
  lblTownTime.Visible:=lPet;
  edTownTime .Visible:=lPet;
  lblSkin    .Visible:=lPet;
  edSkin     .Visible:=lPet;
  gbAction   .Visible:=lPet;

  cbImage     .Visible:=lChar or lPet;
  lblMorphTime.Visible:=lChar or lPet;
  edMorphTime .Visible:=lChar or lPet;
  gbSpells    .Visible:=lChar or lPet;
end;

procedure TfmChar.GetCharSpell(cb:TComboBox; idx:integer);
var
  lid:TL2ID;
  lspell:TTL2Spell;
begin
  lspell:=FChar.Spells[idx];
  cb.Text:=GetTL2Skill(lspell.name,lid);
  cbSpellChange(cb);
  TComboBox(cb.Tag).Text:=IntToStr(lspell.level);
end;

procedure TfmChar.SetCharSpell(cb:TComboBox; idx:integer);
var
  lspell:TTL2Spell;
  lcb:TComboBox;
begin
  if cb.ItemIndex>=0 then
  begin
    lcb:=TComboBox(cb.Tag);
    lspell.name :=FSpells[integer(cb .Items.Objects[cb .ItemIndex])].name;
    lspell.level:=        integer(lcb.Items.Objects[lcb.ItemIndex]);
  end
  else
  begin
    lspell.name :='';
    lspell.level:=0;
  end;
  FChar.Spells[idx]:=lspell;
end;

procedure TfmChar.FillInfo(aChar:TTL2Character);
var
  lid:TL2ID;
  lspell:TTL2Spell;
  i:integer;
begin
  FChar:=aChar;
  ChangeVisibility;

  cbEnabled.Checked:=aChar.Enabled;

  edName.Text      :=aChar.Name;
  lblSuffix.Caption:=aChar.Suffix;

  if      aChar.IsChar then edOriginal.Caption:=GetTL2Class(aChar.ClassId)
  else if aChar.IsPet  then edOriginal.Caption:=GetTL2Pet  (aChar.ClassId)
  else                      edOriginal.Caption:=GetTL2Mobs (aChar.ClassId);

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

  if aChar.IsPet or aChar.IsChar then
  begin
    GetCharSpell(cbSpell1,0);
    GetCharSpell(cbSpell2,1);
    GetCharSpell(cbSpell3,2);
    GetCharSpell(cbSpell4,3);
  end;
end;

procedure TfmChar.bbUpdateClick(Sender: TObject);
var
  lid:TL2ID;
  lspell:TTL2Spell;
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

  if FChar.IsPet or FChar.IsChar then
  begin
    SetCharSpell(cbSpell1,0);
    SetCharSpell(cbSpell2,1);
    SetCharSpell(cbSpell3,2);
    SetCharSpell(cbSpell4,3);
  end;
{
  lbModList.Clear;
  for i:=0 to High(FChar.ModIds) do
    lbModList.AddItem(GetTL2Mod(FChar.ModIds[i]),nil);
}
end;

procedure TfmChar.cbSpellChange(Sender: TObject);
var
  cb:TComboBox;
  i,idx:integer;
begin
  with (Sender as TComboBox) do
  begin
    cb:=TComboBox(Tag);
    idx:=integer(Items.Objects[ItemIndex]);
    cb.Clear;
    if idx>=0 then
    begin
      for i:=1 to FSpells[idx].level do
        cb.Items.AddObject(IntToStr(i),TObject(i));
      cb.ItemIndex:=0;
    end;
  end;
end;

procedure TfmChar.FormCreate(Sender: TObject);
var
  i:integer;
begin
  CreateSpellList(FSpells);

  cbSpell1.Clear;
  cbSpell1.Sorted:=true;
  cbSpell1.Items.BeginUpdate;
  cbSpell1.Items.Capacity:=Length(FSpells);
  cbSpell1.Items.AddObject('',TObject(-1));
  for i:=0 to High(FSpells) do
    cbSpell1.Items.AddObject(FSpells[i].title,TObject(i));
  cbSpell1.Items.EndUpdate;
  cbSpell2.Items.Assign(cbSpell1.Items);
  cbSpell3.Items.Assign(cbSpell1.Items);
  cbSpell4.Items.Assign(cbSpell1.Items);

  cbSpell1.Tag:=PtrUInt(cbSpellLvl1);
  cbSpell2.Tag:=PtrUInt(cbSpellLvl2);
  cbSpell3.Tag:=PtrUInt(cbSpellLvl3);
  cbSpell4.Tag:=PtrUInt(cbSpellLvl4);
end;

end.
