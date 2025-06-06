{TODO: signal about changes}

unit formItem;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Buttons, ComCtrls, Grids, formEffects, tlsgitem, tlsgchar, tlsave;

type

  { TfmItem }

  TfmItem = class(TForm)
    edIconName: TEdit;
    edQuestName: TEdit;
    edUnkn1_1: TEdit;
    edQuestID: TEdit;
    edUnkn1_2: TEdit;
    edUnkn1_3: TEdit;
    edUnkn2_byte: TEdit;
    edUnkn2_1: TEdit;
    edUnkn2_2: TEdit;
    edUnkn2_3: TEdit;
    edUnkn2_4: TEdit;
    edUnkn4: TEdit;
    edUnkn5: TEdit;
    lblUnkn1_1: TLabel;
    lblQuestID: TLabel;
    lblUnkn1_2: TLabel;
    lblUnkn1_3: TLabel;
    lblUnkn2_byte: TLabel;
    lblUnkn2_1: TLabel;
    lblUnkn2_2: TLabel;
    lblUnkn2_3: TLabel;
    lblUnkn2_4: TLabel;
    lblUnkn4: TLabel;
    lblIconName: TLabel;
    lblModList: TLabel;
    lblUnkn5_3: TLabel;
    lblWeaponDamageBonuses: TLabel;
    pcItemInfo: TPageControl;
    sgDmgBonus: TStringGrid;
    tsTechInfo: TTabSheet;
    tsCommonInfo: TTabSheet;

    // Common
    bbUpdate: TBitBtn;

    gbFlags: TGroupBox;
    cbFlag1: TCheckBox;
    cbFlag2: TCheckBox;
    cbFlag3: TCheckBox;
    cbFlag4: TCheckBox;
    cbFlag5: TCheckBox;
    cbFlag6: TCheckBox;
    cbFlag7: TCheckBox;

    cbEnabled: TCheckBox;
    cbVisible: TCheckBox;

    edItemId   : TEdit;
    edLevel    : TEdit;  lblLevel: TLabel;
    edName     : TEdit;  lblName : TLabel;
    edNameById : TEdit;
    edPrefix   : TEdit;  lblPrefix: TLabel;
    edSuffix   : TEdit;  lblSuffix: TLabel;

    gbCoords: TGroupBox;
    edX : TEdit;  lblX : TLabel;
    edY : TEdit;  lblY : TLabel;
    edZ : TEdit;  lblZ : TLabel;

    gbCoords1: TGroupBox;
    edX1: TEdit;  lblX1: TLabel;
    edY1: TEdit;  lblY1: TLabel;
    edZ1: TEdit;  lblZ1: TLabel;

    imgItem: TImage;

    lbModList: TListBox;
    bbClearMod: TBitBtn;

    // Item
    tsItemInfo: TTabSheet;
    cbEquipped  : TCheckBox;
    cbRecognized: TCheckBox;
    edPosition : TEdit;  lblPosition : TLabel;  lblPosType: TLabel;  lblContType: TLabel;
    edArmor    : TEdit;  lblArmor    : TLabel;
    edArmorType: TEdit;  lblArmorType: TLabel;  lblArmorByType: TLabel;
    edEnchant  : TEdit;  lblEnchant  : TLabel;
    edWeaponDmg: TEdit;  lblWeaponDmg: TLabel;
    edSockets  : TEdit;  lblSockets  : TLabel;
    edStack    : TEdit;  lblStack    : TLabel;

    // Prop
    tsPropInfo: TTabSheet;
    cbActivated : TCheckBox;
    edPropState: TEdit;
    lblPropState: TLabel;

    // Other
    tsOtherInfo: TTabSheet;

    procedure bbClearModClick(Sender: TObject);
    procedure bbUpdateClick  (Sender: TObject);
    procedure edNameChange   (Sender: TObject);
    procedure edSocketsChange(Sender: TObject);
    procedure edStackChange  (Sender: TObject);
    procedure FormCreate(Sender: TObject);

  private
    FEffects:TfmEffects;

    FSGame:TTLSaveFile;
    FItem:TTLItem;
    FChar:TTLCharacter;
    FMaxStack:integer;

    procedure DrawItemIcon(aItem: TTLItem; aImg: TImage);

  public
    procedure FillInfo(aSGame:TTLSaveFile; aItem:TTLItem; aChar:TTLCharacter=nil);

  end;

implementation

{$R *.lfm}

uses
  lazfileutils,
  formSettings,
  rgglobal,
  tlsgeffects,
  addons,
  rgdb;

procedure TfmItem.FormCreate(Sender: TObject);
begin
  FEffects:=TfmEffects.Create(Self);
  FEffects.Parent :=tsOtherInfo;
  FEffects.Align  :=alClient;
  FEffects.Visible:=true;

  pcItemInfo.ActivePage:=tsCommonInfo;
end;

procedure TfmItem.edStackChange(Sender: TObject);
begin
  if not edStack.ReadOnly then
  begin
    if FMaxStack<0 then FMaxStack:=RGDBGetItemStack(FItem.ID);
    if StrToIntDef(edStack.Text,1)>FMaxStack then
      edStack.Text:=IntToStr(FMaxStack);
    bbUpdate.Visible:=true;
  end;
end;

procedure TfmItem.edSocketsChange(Sender: TObject);
begin
  if not edSockets.ReadOnly then
  begin
    if StrToIntDef(edSockets.Text,0)>4 then
      edSockets.Text:='4';
    bbUpdate.Visible:=true;
  end;
end;

procedure TfmItem.edNameChange(Sender: TObject);
begin
  bbUpdate.Visible:=true;
end;

procedure TfmItem.bbUpdateClick(Sender: TObject);
var
  ls:string;
begin
  ls:=Application.MainForm.Caption;
  ls[1]:='*';
  Application.MainForm.Caption:=ls;

  FItem.Name:=edName.Text;
  FItem.ItemStack:=StrToIntDef(edStack.Text,1);
  FItem.Changed:=true;
  if FChar<>nil then FChar.Changed:=true;
  bbUpdate.Visible:=false;
end;

procedure TfmItem.bbClearModClick(Sender: TObject);
begin
  FItem.ModIds  :=nil;
  FItem.ModNames:=nil;
  lbModList.Clear;
  bbClearMod.Visible:=false;
  bbUpdate.Visible:=true;
end;

function GetIconFileName(aItem:TTLItem):string;
begin
  result:=SearchForFileName(fmSettings.IconDir,UpCase(RGDBGetItemIcon(aItem.ID)))
end;

procedure TfmItem.DrawItemIcon(aItem:TTLItem; aImg:TImage);
var
  licon:string;
begin
  licon:=GetIconFileName(aItem);

  if licon<>'' then
    try
      aImg.Picture.LoadFromFile(licon);
    except
      licon:='';
    end;

  if licon='' then
  begin
    try
      aImg.Picture.LoadFromFile(fmSettings.IconDir+'\unknown.png');
    except
      aImg.Picture.Clear;
    end;
  end;
end;

procedure TfmItem.FillInfo(aSGame:TTLSaveFile; aItem:TTLItem; aChar:TTLCharacter=nil);
var
  linv,lcont:string;
  i:integer;
  lprop:boolean;
begin
  FSGame:=aSGame;
  FItem :=aItem;
  FChar :=aChar;

  lprop :=aItem.IsProp;

  tsPropInfo .TabVisible:=lprop;
  tsItemInfo .TabVisible:=not lprop;
  tsOtherInfo.TabVisible:=fmSettings.cbShowAll.Checked;
  tsTechInfo .TabVisible:=
      fmSettings.cbShowTech.Checked and
      fmSettings.cbShowAll.Checked;

  if ((pcItemInfo.ActivePage=tsPropInfo ) and tsPropInfo .TabVisible) or
     ((pcItemInfo.ActivePage=tsOtherInfo) and tsOtherInfo.TabVisible) or
     ((pcItemInfo.ActivePage=tsItemInfo ) and tsItemInfo .TabVisible) or
     ((pcItemInfo.ActivePage=tsTechInfo ) and tsTechInfo .TabVisible) then
  else
    pcItemInfo.ActivePage:=tsCommonInfo;

  FMaxStack:=-1;

  edStack  .ReadOnly:=FChar=nil;
  edSockets.ReadOnly:=FChar=nil;
  
  //--- Common ---

  edName  .Text:=aItem.Name;
  edPrefix.Text:=aItem.Prefix;
  edSuffix.Text:=aItem.Suffix;

  if lprop then
    edNameById.Text:=RGDBGetProp(aItem.ID)
  else
    edNameById.Text:=RGDBGetItem(aItem.ID);

  edX.Text:=FloatToStrF(aItem.Position1.X,ffFixed,-8,2);
  edY.Text:=FloatToStrF(aItem.Position1.Y,ffFixed,-8,2);
  edZ.Text:=FloatToStrF(aItem.Position1.Z,ffFixed,-8,2);

  if (aItem.Position1.X=aItem.Coord.X) and
     (aItem.Position1.Y=aItem.Coord.Y) and
     (aItem.Position1.Z=aItem.Coord.Z) then
  begin
    gbCoords1.Visible:=false;
  end
  else
  begin
    gbCoords1.Visible:=true;
    edX1.Text:=FloatToStrF(aItem.Coord.X,ffFixed,-8,2);
    edY1.Text:=FloatToStrF(aItem.Coord.Y,ffFixed,-8,2);
    edZ1.Text:=FloatToStrF(aItem.Coord.Z,ffFixed,-8,2);
  end;

  cbFlag1.Checked:=aItem.Flags[0];
  cbFlag2.Checked:=aItem.Flags[1];
  cbFlag3.Checked:=aItem.Flags[2];
  cbFlag4.Checked:=aItem.Flags[3];
  cbFlag5.Checked:=aItem.Flags[4];
  cbFlag6.Checked:=aItem.Flags[5];
  cbFlag7.Checked:=aItem.Flags[6];
  cbFlag7.Visible:=FSGame.GameVersion=verTL2;

  //--- Technical ---

  if tsTechInfo.TabVisible then
  begin
    edUnkn1_1.Text:=TextId(aItem.FUnkn1[0]);
    edUnkn1_2.Text:=TextId(aItem.FUnkn1[1]);
    edUnkn1_3.Text:=TextId(aItem.FUnkn1[2]);
    edUnkn1_3 .Visible:=FSGame.GameVersion=verTL2;
    lblUnkn1_3.Visible:=FSGame.GameVersion=verTL2;

    edUnkn2_byte.Text:=IntToStr(aItem.FUnkn2b);
    edUnkn2_1   .Text:=TextId  (aItem.FUnkn20);
    edUnkn2_2   .Text:=TextId  (aItem.FUnkn21);
    edUnkn2_3   .Text:=TextId  (aItem.FUnkn22);
    edUnkn2_4   .Text:=IntToStr(aItem.FUnkn23);
    edUnkn2_3 .Visible:=FSGame.GameVersion=verTL2;
    lblUnkn2_3.Visible:=FSGame.GameVersion=verTL2;

    edUnkn4.Text  :=IntToStr(aItem.FUnkn4);

    edQuestID  .Text:=TextId(aItem.QuestID);
    edQuestName.Text:=RGDBGetQuest(aItem.QuestID);
    edUnkn5    .Text:=IntToStr(integer(aItem.FUnkn5))+
        ' / '+BinStr(aItem.FUnkn5,8);
  end;

  if lprop then
  begin
    edPropState.Text:=IntToStr(aItem.PropState);
  end
  else
  begin
    edLevel   .Text    := IntToStr(aItem.Level);
    edStack   .Text    := IntToStr(aItem.ItemStack);
    edEnchant .Text    := IntToStr(aItem.EnchantCount);
    edSockets.Text     := IntToStr(aItem.SocketCount);

    edPosition.Text    := IntToStr(aItem.Position);
    linv:=RGDBGetItemPosition(aItem.Position, lcont);
    lblContType.Caption:= lcont;
    lblPosType .Caption:= linv;

    edWeaponDmg   .Text   := IntToStr(aItem.WeaponDamage);
    edArmor       .Text   := IntToStr(aItem.Armor);
    edArmorType   .Text   := IntToStr(aItem.ArmorType);
    lblArmorByType.Caption:= ''; //!!

    cbEquipped  .Checked:=aItem.Flags[0];
    cbEnabled   .Checked:=aItem.Flags[1];
    cbVisible   .Checked:=aItem.Flags[4];
    cbRecognized.Checked:=aItem.Flags[6];

    sgDmgBonus.Clear;
    sgDmgBonus.RowCount:=Length(aItem.DmgBonus)+1;
    for i:=0 to High(aItem.DmgBonus) do
    begin
      sgDmgBonus.Cells[0,i+1]:=GetEffectDamageType(TTLEffectDamageType(aItem.DmgBonus[i].dmgtype));
      sgDmgBonus.Cells[1,i+1]:=IntToStr(Round(aItem.DmgBonus[i].bonus));
    end;
  end;

  //--- Setup changing visibility

  if fmSettings.cbShowTech.Checked then
  begin
    edItemId.Visible:=true;
    edItemId.Text:=TextId(aItem.ID);
  end
  else
  begin
    edItemId.Visible:=false;
  end;

  if tsOtherInfo.TabVisible then
    FEffects.FillInfo(aItem);

{
  lbAugments.Clear;
  for i:=0 to High(aItem.Augments) do
    lbAugments.AddItem(aItem.Augments[i],nil);
}
  edIconName.Text:=RGDBGetItemIcon(aItem.ID);
  DrawItemIcon(aItem,imgItem);

  lbModList.Clear;
  if aItem.ModIds<>nil then
    for i:=0 to High(aItem.ModIds) do
      lbModList.AddItem(RGDBGetMod(aItem.ModIds[i]),nil);
  if aItem.ModNames<>nil then
    for i:=0 to High(aItem.ModNames) do
      lbModList.AddItem(aItem.ModNames[i],nil);

  bbClearMod.Visible:=Length(aItem.ModIds)<>0;

  bbUpdate.Visible:=false;
end;

end.
