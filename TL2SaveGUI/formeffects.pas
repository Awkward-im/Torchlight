unit formEffects;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Grids, StdCtrls,
  CheckLst, tl2active;

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
    procedure sgEffectsSelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);

  private
    FObject:TL2ActiveClass;

    procedure ClearData;

  public
    procedure FillInfo(aobj:TL2ActiveClass);
  end;

var
  fmEffects: TfmEffects;

implementation

{$R *.lfm}

uses
  tl2effects,
  tl2base,
  tl2db;

procedure TfmEffects.ClearData;
var
  i:integer;
begin
  edEffectName.Text:='';
  edLinkName  .Text:='';
  edGraph     .Text:='';
  edParticles .Text:='';
  edIcon      .Text:='';

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
  ls:string;
  leffect:TTL2Effect;
  i,llist,lidx:integer;
begin
  if aRow=0 then exit;

  llist:=IntPtr(sgEffects.Objects[0,aRow]);
  lidx :=llist mod 1000;
  llist:=llist div 1000;
  if FObject.Effects[llist]=nil then exit; // workaround of LCL

  leffect:=FObject.Effects[llist][lidx];

  edEffectName.Text:=GetEffectType(leffect.EffectType);
  edLinkName  .Text:=leffect.LinkName;
  edGraph     .Text:=leffect.Graph;
  edParticles .Text:=leffect.Particles;
  edIcon      .Text:=leffect.Icon;
  edUnitTheme .Text:='0x'+HexStr(leffect.UnitThemeId,16);

  for i:=0 to clbFlags.Items.Count-1 do
  begin
//    clbFlags.ItemEnabled[i]:=false;
    clbFlags.Checked[i]:=(DWord(leffect.Flags) and (1 shl i))<>0;
  end;

  lbProps.Clear;
  for i:=0 to leffect.Properties-1 do
  begin
    Str(leffect.Properties[i]:0:4,ls);
    lbProps.AddItem(ls,nil);
  end;

  sgStats.Clear;
  sgStats.RowCount:=1+leffect.Stats;
  for i:=0 to leffect.Stats-1 do
  begin
    sgStats.Cells[0,i+1]:=GetTL2Stat(leffect.Stats[i].id);
    Str(leffect.Stats[i].percentage:0:4,ls);
    sgStats.Cells[1,i+1]:=ls;
  end;

  edDamageType.Text:=GetEffectDamageType(leffect.DamageType);
  edActivation.Text:=GetEffectActivation(leffect.Activation);
  edSource    .Text:=GetEffectSource(leffect.Source);

  edLevel.Text:=IntToStr(leffect.Level);
  Str(leffect.Duration:0:4,ls); edDuration.Text:=ls;
  Str(leffect.Unknown:0:4,ls); edUnknown1.Text:=ls;
  Str(leffect.DisplayValue:0:4,ls); edDisplay .Text:=ls;

  lblBaseClass.Visible:=FObject.DataType=dtChar;
  edBaseClass .Visible:=FObject.DataType=dtChar;
  if edBaseClass.Visible then
    edBaseClass.Text:=GetTL2Class(leffect.ClassId);
end;

procedure TfmEffects.FillInfo(aobj:TL2ActiveClass);
var
  leffect:TTL2Effect;
  i,j,lcnt:integer;
//  dummy:boolean;
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
        sgEffects.Cells[0,lcnt]:=IntToStr(i+1);
        sgEffects.Cells[1,lcnt]:=IntToStr(leffect.EffectType);
        if leffect.Name<>'' then
          sgEffects.Cells[2,lcnt]:=leffect.Name
        else
          sgEffects.Cells[2,lcnt]:='<'+GetEffectType(leffect.EffectType)+'>';
        inc(lcnt);
      end;
    sgEffects.Row:=1;
//    sgEffectsSelectCell(sgEffects,0,1,dummy);
  end;
  sgEffects.EndUpdate;
end;

end.

