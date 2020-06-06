unit formItem;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Grids, tl2item;

type

  { TfmItem }

  TfmItem = class(TForm)
    edUnkn6: TEdit;
    gbFlags: TGroupBox;
    cbFlag1: TCheckBox;
    cbFlag2: TCheckBox;
    cbFlag3: TCheckBox;
    cbFlag4: TCheckBox;
    cbFlag5: TCheckBox;
    cbFlag6: TCheckBox;
    cbFlag7: TCheckBox;

    gbCoords: TGroupBox;
    lblX: TLabel;  lblY: TLabel;  lblZ: TLabel;
    edX : TEdit ;  edY : TEdit ;  edZ : TEdit;
    gbCoords1: TGroupBox;
    lblX1: TLabel;  lblY1: TLabel;  lblZ1: TLabel;
    edX1 : TEdit ;  edY1 : TEdit ;  edZ1 : TEdit;

    edName  : TEdit;  lblName  : TLabel;  edNameById: TEdit;
    edPrefix: TEdit;  lblPrefix: TLabel;
    edSuffix: TEdit;  lblSuffix: TLabel;

    edLevel    : TEdit;   lblLevel   : TLabel;
    edStack    : TEdit;   lblStack   : TLabel;
    edEnchant  : TEdit;   lblEnchant : TLabel;
    edPosition : TEdit;   lblPosition: TLabel;
    lblContType: TLabel;  lblPosType : TLabel;
    edSockets  : TEdit;   lblSockets : TLabel;

    edWeaponDmg: TEdit;  lblWeaponDmg: TLabel;
    edArmor    : TEdit;  lblArmor    : TLabel;
    edArmorType: TEdit;  lblArmorType: TLabel;  lblArmorByType: TLabel;

    lbModList : TListBox;
    lbAugments: TListBox;  lblAugments: TLabel;
    sgEffects : TStringGrid;

  private
    FItem:TTL2Item;

  public
    procedure FillInfo(aItem:TTL2Item);

  end;

implementation

{$R *.lfm}

uses
  tl2db;

procedure TfmItem.FillInfo(aItem:TTL2Item);
var
  linv,lcont:string;
  i,j:integer;
begin
  FItem:=aItem;
  
  edName    .Text := aItem.Name;
  if aItem.IsProp then
    edNameById.Text := GetTL2Prop(aItem.ID)
  else
    edNameById.Text := GetTL2Item(aItem.ID);
  edPrefix  .Text := aItem.Prefix;
  edSuffix  .Text := aItem.Suffix;

  edX.Text:=FloatToStrF(aItem.Position1.X,ffFixed,-8,2);
  edY.Text:=FloatToStrF(aItem.Position1.Y,ffFixed,-8,2);
  edZ.Text:=FloatToStrF(aItem.Position1.Z,ffFixed,-8,2);

  if (aItem.Position1.X=aItem.Position2.X) and
     (aItem.Position1.Y=aItem.Position2.Y) and
     (aItem.Position1.Z=aItem.Position2.Z) then
  begin
    gbCoords1.Visible:=false;
  end
  else
  begin
    gbCoords1.Visible:=true;
    edX1.Text:=FloatToStrF(aItem.Position2.X,ffFixed,-8,2);
    edY1.Text:=FloatToStrF(aItem.Position2.Y,ffFixed,-8,2);
    edZ1.Text:=FloatToStrF(aItem.Position2.Z,ffFixed,-8,2);
  end;

  edLevel   .Text    := IntToStr(aItem.Level);
  edStack   .Text    := IntToStr(aItem.Stack);
  edEnchant .Text    := IntToStr(aItem.EnchantCount);
  edPosition.Text    := IntToStr(aItem.Position);
  linv:=GetItemPosition(aItem.Position, lcont);
  lblContType.Caption := lcont;
  lblPosType .Caption := linv;
  edSockets.Text     := IntToStr(aItem.SocketCount);

  edWeaponDmg   .Text   := IntToStr(aItem.WeaponDamage);
  edArmor       .Text   := IntToStr(aItem.Armor);
  edArmorType   .Text   := IntToStr(aItem.ArmorType);
  lblArmorByType.Caption:= ''; //!!

  cbFlag1.Checked:=aItem.Flags[0];
  cbFlag2.Checked:=aItem.Flags[1];
  cbFlag3.Checked:=aItem.Flags[2];
  cbFlag4.Checked:=aItem.Flags[3];
  cbFlag5.Checked:=aItem.Flags[4];
  cbFlag6.Checked:=aItem.Flags[5];
  cbFlag7.Checked:=aItem.Flags[6];

  edUnkn6.Text:=IntToStr(Length(aItem.Unkn6));

  lbAugments.Clear;
  for i:=0 to High(aItem.Augments) do
    lbAugments.AddItem(aItem.Augments[i],nil);

  sgEffects.BeginUpdate;
  sgEffects.Clear;
  sgEffects.RowCount:=1+Length(aItem.Effects1)+Length(aItem.Effects2)+Length(aItem.Effects3);
  j:=1;
  for i:=0 to High(aItem.Effects1) do
  begin
    sgEffects.Objects[0,j]:=TObject(IntPtr(i));
    sgEffects.Cells[0,j]:='1';
    sgEffects.Cells[1,j]:=IntToStr(aItem.Effects1[i].EffectType);
    sgEffects.Cells[2,j]:=aItem.Effects1[i].Name;
    inc(j);
  end;
  for i:=0 to High(aItem.Effects2) do
  begin
    sgEffects.Objects[0,j]:=TObject(IntPtr(i));
    sgEffects.Cells[0,j]:='2';
    sgEffects.Cells[1,j]:=IntToStr(aItem.Effects2[i].EffectType);
    sgEffects.Cells[2,j]:=aItem.Effects2[i].Name;
    inc(j);
  end;
  for i:=0 to High(aItem.Effects3) do
  begin
    sgEffects.Objects[0,j]:=TObject(IntPtr(i));
    sgEffects.Cells[0,j]:='3';
    sgEffects.Cells[1,j]:=IntToStr(aItem.Effects3[i].EffectType);
    sgEffects.Cells[2,j]:=aItem.Effects3[i].Name;
    inc(j);
  end;
  sgEffects.EndUpdate;

  lbModList.Clear;
  for i:=0 to High(aItem.ModIds) do
    lbModList.AddItem(GetTL2Mod(aItem.ModIds[i]),nil);
end;

end.
