unit formEffects;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Grids, StdCtrls,
  CheckLst, tlsgactive;

type

  { TfmEffects }

  TfmEffects = class(TForm)
    clbFlags: TCheckListBox;
    edLevel     : TEdit;  lblLevel     : TLabel;
    edDamageType: TEdit;  lblDamageType: TLabel;
    edActivation: TEdit;  lblActivation: TLabel;
    edSource    : TEdit;  lblSource    : TLabel;
    edDuration  : TEdit;  lblDuration  : TLabel;
    edUnknown1  : TEdit;  lblUnknown   : TLabel;
    edDisplay   : TEdit;  lblDisplay   : TLabel;
    edBaseClass : TEdit;  lblBaseClass : TLabel;
    edUnitTheme : TEdit;  lblUnitTheme : TLabel;
    edEffectName: TEdit;  lblEffectName: TLabel;
    edLinkName  : TEdit;  lblLinkName  : TLabel;
    edGraph     : TEdit;  lblGraph     : TLabel;
    edParticles : TEdit;  lblParticles : TLabel;
    edIcon      : TEdit;  lblIcon      : TLabel;

    lbProps   : TListBox   ;  lblProperties: TLabel;
    sgEffects : TStringGrid;  lblEffects   : TLabel;
    sgStats   : TStringGrid;

//    procedure sgEffectsAfterSelection(Sender: TObject; aCol, aRow: Integer);
    procedure FormCreate(Sender: TObject);
    procedure sgEffectsSelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);

  private
    FObject:TLActiveClass;

    procedure ClearData;

  public
    procedure FillInfo(aobj:TLActiveClass);
  end;

var
  fmEffects: TfmEffects;

implementation

{$R *.lfm}

uses
  rgglobal,
  tlsgeffects,
  TLSGBase,
  tlsgchar,
  rgdb;

resourcestring
  ef00 = 'Unknown1';
  ef01 = 'Unknown2';
  ef02 = 'Exclusive';
  ef03 = 'Not Magical';
  ef04 = 'Saves';
  ef05 = 'Display Positive';
  ef06 = 'Unknown3';
  ef07 = 'Use Owner Level';
  ef08 = 'Has Graph';
  ef09 = 'Is Bonus';
  ef10 = 'Is Enchantment';
  ef11 = 'Has Link Name';
  ef12 = 'Has Particles';
  ef13 = 'Has Unit Theme';
  ef14 = 'Unknown4';
  ef15 = 'Unknown5';
  ef16 = 'Remove On Death';
  ef17 = 'Has Icon';
  ef18 = 'Display Max Modifier';
  ef19 = 'Is For Weapon';
  ef20 = 'Is For Armor';
  ef21 = 'Is Disabled';

procedure TfmEffects.ClearData;
var
  i:integer;
begin
  edEffectName.Text:='';
  edLinkName  .Text:='';
  edGraph     .Text:='';
  edParticles .Text:='';
  edIcon      .Text:='';
  edUnitTheme .Text:='';
  edBaseClass .Text:='';

  for i:=0 to clbFlags.Items.Count-1 do
  begin
    clbFlags.Checked[i]:=false;
  end;
  lbProps.Clear;
  sgStats.Clear;

  edDamageType.Text:='';
  edActivation.Text:='';
  edSource    .Text:='';
  edLevel     .Text:='';
  edDuration  .Text:='';
  edUnknown1  .Text:='';
  edDisplay   .Text:='';
end;

procedure TfmEffects.sgEffectsSelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
//procedure TfmEffects.sgEffectsAfterSelection(Sender: TObject; aCol, aRow: Integer);
var
  ls1,ls:string;
  leffect:TTLEffect;
  i,llist,lidx:integer;
begin
  if aRow=0 then exit;

  llist:=IntPtr(sgEffects.Objects[0,aRow]);
  lidx :=llist mod 1000;
  llist:=llist div 1000;
  if FObject.Effects[llist]=nil then exit; // workaround of LCL

  leffect:=FObject.Effects[llist][lidx];

  // Left side

  edEffectName.Text:=GetEffectType(leffect.EffectType);
  edLinkName  .Text:=leffect.LinkName;
  edGraph     .Text:=leffect.Graph;
  edParticles .Text:=leffect.Particles;
  edIcon      .Text:=leffect.Icon;
  edUnitTheme .Text:=RGDBGetUnitTheme(leffect.UnitThemeId);

  // Right side

  for i:=0 to clbFlags.Items.Count-1 do
  begin
//    clbFlags.ItemEnabled[i]:=false;
    clbFlags.Checked[i]:=(DWord(leffect.Flags) and (1 shl i))<>0;
  end;

  ls1:=RGDBGetEffectValueNames(leffect.EffectType);
  lbProps.Clear;
  for i:=0 to leffect.Properties-1 do
  begin
    Str(leffect.Properties[i]:0:4,ls);
    FixFloatStr(ls);
    lbProps.AddItem(RGDBGetEffectValueName(ls1,i)+' = '+ls,nil);
  end;

  sgStats.Clear;
  sgStats.RowCount:=1+leffect.Stats;
  for i:=0 to leffect.Stats-1 do
  begin
    sgStats.Cells[0,i+1]:=RGDBGetTL2Stat(leffect.Stats[i].id);
    Str(leffect.Stats[i].percentage:0:4,ls);
    sgStats.Cells[1,i+1]:=ls;
  end;

  edDamageType.Text:=GetEffectDamageType(leffect.DamageType);
  edActivation.Text:=GetEffectActivation(leffect.Activation);
  edSource    .Text:=GetEffectSource(leffect.Source);

  edLevel.Text:=IntToStr(leffect.Level);
  Str(leffect.Duration    :0:4,ls); FixFloatStr(ls); edDuration.Text:=ls;
  Str(leffect.Unknown     :0:4,ls); FixFloatStr(ls); edUnknown1.Text:=ls;
  Str(leffect.DisplayValue:0:4,ls); FixFloatStr(ls); edDisplay .Text:=ls;

  lblBaseClass.Visible:=FObject.DataType=dtChar;
  edBaseClass .Visible:=FObject.DataType=dtChar;
  if edBaseClass.Visible then
  begin
    case (FObject as TTLCharacter).CharType of
      ctPlayer: ls:=RGDBGetClass(leffect.ClassId);
      ctPet   : ls:=RGDBGetPet  (leffect.ClassId);
      ctMob   : ls:=RGDBGetMob  (leffect.ClassId);
    end;
    edBaseClass.Text:=ls;
  end;
end;

procedure TfmEffects.FormCreate(Sender: TObject);
begin
  clbFlags.Clear;
  clbFlags.AddItem(ef00,nil);
  clbFlags.AddItem(ef01,nil);
  clbFlags.AddItem(ef02,nil);
  clbFlags.AddItem(ef03,nil);
  clbFlags.AddItem(ef04,nil);
  clbFlags.AddItem(ef05,nil);
  clbFlags.AddItem(ef06,nil);
  clbFlags.AddItem(ef07,nil);
  clbFlags.AddItem(ef08,nil);
  clbFlags.AddItem(ef09,nil);
  clbFlags.AddItem(ef10,nil);
  clbFlags.AddItem(ef11,nil);
  clbFlags.AddItem(ef12,nil);
  clbFlags.AddItem(ef13,nil);
  clbFlags.AddItem(ef14,nil);
  clbFlags.AddItem(ef15,nil);
  clbFlags.AddItem(ef16,nil);
  clbFlags.AddItem(ef17,nil);
  clbFlags.AddItem(ef18,nil);
  clbFlags.AddItem(ef19,nil);
  clbFlags.AddItem(ef20,nil);
  clbFlags.AddItem(ef21,nil);
end;

procedure TfmEffects.FillInfo(aobj:TLActiveClass);
var
  leffect:TTLEffect;
  i,j,lcnt:integer;
  dummy:boolean;
begin
  FObject:=aobj;

  ClearData;

  sgEffects.BeginUpdate;
  sgEffects.Clear;
  //!! Next line works as selection
  sgEffects.RowCount:=1+Length(aobj.Effects[0])+Length(aobj.Effects[1])+Length(aobj.Effects[2]);
  if sgEffects.RowCount>1 then
  begin
    lcnt:=1;
    for i:=0 to 2 do
      for j:=0 to High(aobj.Effects[i]) do
      begin
        leffect:=aobj.Effects[i][j];
        sgEffects.Objects[0,lcnt]:=TObject(i*1000+j);
        sgEffects.Cells  [0,lcnt]:=GetEffectActivation(TTLEffectActivation(i));//IntToStr(i+1);
        sgEffects.Cells  [1,lcnt]:=IntToStr(leffect.EffectType);
        if leffect.Name<>'' then
          sgEffects.Cells[2,lcnt]:=leffect.Name
        else
          sgEffects.Cells[2,lcnt]:='<'+GetEffectType(leffect.EffectType)+'>';
        inc(lcnt);
      end;
//    sgEffectsSelectCell(sgEffects,0,1,dummy);
  end;
  sgEffects.EndUpdate;
  if sgEffects.RowCount>1 then
    if sgEffects.RowCount=2 then
      sgEffectsSelectCell(sgEffects,1,1,dummy)
    else
      sgEffects.Row:=1;
end;

end.
