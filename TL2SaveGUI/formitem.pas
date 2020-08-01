unit formItem;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Buttons, ComCtrls, formEffects, tl2item, tl2char;

type

  { TfmItem }

  TfmItem = class(TForm)
    pcItemInfo: TPageControl;
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

    cbEnabled   : TCheckBox;
    cbVisible   : TCheckBox;

    edItemId   : TEdit;
    edLevel    : TEdit;  lblLevel: TLabel;
    edName     : TEdit;  lblName: TLabel;
    edNameById : TEdit;
    edPrefix   : TEdit;  lblPrefix: TLabel;
    edSuffix   : TEdit;  lblSuffix: TLabel;
    edUnkn6    : TEdit;

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

    // Other
    tsOtherInfo: TTabSheet;

    procedure bbClearModClick(Sender: TObject);
    procedure bbUpdateClick(Sender: TObject);
    procedure edSocketsChange(Sender: TObject);
    procedure edStackChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);

  private
    FEffects:TfmEffects;

    FItem:TTL2Item;
    FChar:TTL2Character;
    FMaxStack:integer;

    procedure DrawItemIcon(aItem: TTL2Item; aImg: TImage);

  public
    procedure FillInfo(aItem:TTL2Item; aChar:TTL2Character=nil);

  end;

implementation

{$R *.lfm}

uses
  lazfileutils,
  formSettings,
  tl2db;

procedure TfmItem.FormCreate(Sender: TObject);
begin
  FEffects:=TfmEffects.Create(Self);
  FEffects.Parent:=tsOtherInfo;
  FEffects.Visible:=true;
end;

procedure TfmItem.edStackChange(Sender: TObject);
begin
  if not edStack.ReadOnly then
  begin
    if FMaxStack<0 then FMaxStack:=GtItemStack(FItem.ID);
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

procedure TfmItem.bbUpdateClick(Sender: TObject);
var
  ls:string;
begin
  ls:=Application.MainForm.Caption;
  ls[1]:='*';
  Application.MainForm.Caption:=ls;

  FItem.Stack:=StrToIntDef(edStack.Text,1);
  FItem.Changed:=true;
  if FChar<>nil then FChar.Changed:=true;
  bbUpdate.Visible:=false;
end;

procedure TfmItem.bbClearModClick(Sender: TObject);
begin
  FItem.ModIds:=nil;
  lbModList.Clear;
  bbClearMod.Visible:=false;
  bbUpdate.Visible:=true;
end;

function CycleDir(const adir,aicon:string):string;
var
  sr:TSearchRec;
  lname:AnsiString;
begin
  result:='';
  if FindFirst(adir+'\*.*',faAnyFile and faDirectory,sr)=0 then
  begin
    repeat
      lname:=adir+'\'+sr.Name;
      if (sr.Attr and faDirectory)=faDirectory then
      begin
        if (sr.Name<>'.') and (sr.Name<>'..') then
        begin
          result:=CycleDir(lname,aicon);
          if result<>'' then break;
        end;
      end
      else
      begin
        if UpCase(ExtractFileNameOnly(lname))=aicon then
        begin
          result:=lname;
          break;
        end;
      end;
    until FindNext(sr)<>0;
    FindClose(sr);
  end;
end;

function GetIconFileName(aItem:TTL2Item):string;
var
  licon:string;
begin
  licon:=GetItemIcon(aItem.ID);
  if licon<>'' then
    result:=CycleDir(fmSettings.edIconDir.Text,UpCase(licon))
  else
    result:='';
end;

procedure TfmItem.DrawItemIcon(aItem:TTL2Item; aImg:TImage);
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
    try
      aImg.Picture.LoadFromFile(fmSettings.edIconDir.Text+'\unknown.png');
    except
      aImg.Picture.Clear;
    end;
end;

procedure TfmItem.FillInfo(aItem:TTL2Item; aChar:TTL2Character=nil);
var
  linv,lcont:string;
  i,j:integer;
begin
  FItem:=aItem;
  FChar:=aChar;
  FMaxStack:=-1;

  edStack  .ReadOnly:=FChar=nil;
  edSockets.ReadOnly:=FChar=nil;
  
  edName    .Text := aItem.Name;
  if aItem.IsProp then
    edNameById.Text := GetTL2Prop(aItem.ID)
  else
    edNameById.Text := GetTL2Item(aItem.ID);
  edPrefix  .Text := aItem.Prefix;
  edSuffix  .Text := aItem.Suffix;
  if fmSettings.cbIdAsHex.Checked then
    edItemId.Text:='0x'+HexStr(aItem.ID,16)
  else
    edItemId.Text:=IntToStr(aItem.ID);

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

  cbFlag1.Checked:=aItem.Flags[0]; cbEquipped  .Checked:=aItem.Flags[0];
  cbFlag2.Checked:=aItem.Flags[1]; cbEnabled   .Checked:=aItem.Flags[1];
  cbFlag3.Checked:=aItem.Flags[2];
  cbFlag4.Checked:=aItem.Flags[3];
  cbFlag5.Checked:=aItem.Flags[4]; cbVisible   .Checked:=aItem.Flags[4];
  cbFlag6.Checked:=aItem.Flags[5];
  cbFlag7.Checked:=aItem.Flags[6]; cbRecognized.Checked:=aItem.Flags[6];

  edUnkn6.Text:=IntToStr(Length(aItem.Unkn6));

  FEffects.FillInfo(aItem);
{
  lbAugments.Clear;
  for i:=0 to High(aItem.Augments) do
    lbAugments.AddItem(aItem.Augments[i],nil);
}
  DrawItemIcon(aItem,imgItem);

  lbModList.Clear;
  for i:=0 to High(aItem.ModIds) do
    lbModList.AddItem(GetTL2Mod(aItem.ModIds[i]),nil);
  bbClearMod.Visible:=Length(aItem.ModIds)<>0;

  bbUpdate.Visible:=false;
end;

end.
