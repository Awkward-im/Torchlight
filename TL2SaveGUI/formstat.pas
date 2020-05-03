unit formStat;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, Grids,
  tl2save, Types;

type

  { TfmStat }

  TfmStat = class(TForm)
    PageControl1: TPageControl;
    sgStat: TStringGrid;
    sgArea2: TStringGrid;
    sgArea1: TStringGrid;
    sgUnknown: TStringGrid;
    sgSkills: TStringGrid;
    sgItems: TStringGrid;
    sgMobs: TStringGrid;
    tsCommon: TTabSheet;
    tsMobs: TTabSheet;
    tsItems: TTabSheet;
    tsSkills: TTabSheet;
    tsUnknown: TTabSheet;
    tsArea1: TTabSheet;
    tsArea2: TTabSheet;
    tsStats: TTabSheet;
    procedure tsMobsContextPopup(Sender: TObject; MousePos: TPoint;
      var Handled: Boolean);
  private

  public
    procedure FillInfo(aSGame:TTL2SaveFile);

  end;

implementation

{$R *.lfm}

uses
  tl2types,
  tl2common,
  tl2stats,
  tl2db;

procedure TfmStat.tsMobsContextPopup(Sender: TObject; MousePos: TPoint;
  var Handled: Boolean);
begin

end;

procedure TfmStat.FillInfo(aSGame:TTL2SaveFile);
var
  lstat:TTL2Stats;
  i2f:record
  case boolean of
    false: (i:TL2Integer);
    true : (f:TL2Float);
  end;
  i:integer;
begin
  lstat:=aSGame.Stats;

  // mobs
  sgMobs.BeginUpdate;
  sgMobs.Clear;
  sgMobs.RowCount:=1+Length(lstat.Mobs);
  for i:=0 to High(lstat.Mobs) do
  begin
    sgMobs.Cells[0,i+1]:=GetTL2Mobs(lstat.Mobs[i].id);
    sgMobs.Cells[1,i+1]:=IntToStr(lstat.Mobs[i].field1);
    sgMobs.Cells[2,i+1]:=IntToStr(lstat.Mobs[i].field2);
    sgMobs.Cells[3,i+1]:=IntToStr(lstat.Mobs[i].field3);
    sgMobs.Cells[4,i+1]:=IntToStr(lstat.Mobs[i].field4);
    sgMobs.Cells[5,i+1]:=IntToStr(lstat.Mobs[i].field5);
    sgMobs.Cells[6,i+1]:=IntToStr(lstat.Mobs[i].field6);
    sgMobs.Cells[7,i+1]:=IntToStr(lstat.Mobs[i].field7);
    sgMobs.Cells[8,i+1]:=IntToStr(lstat.Mobs[i].field8);
    sgMobs.Cells[9,i+1]:=IntToStr(lstat.Mobs[i].field9);
  end;
  sgMobs.EndUpdate;

  // items
  sgItems.BeginUpdate;
  sgItems.Clear;
  sgItems.RowCount:=1+Length(lstat.Items);
  for i:=0 to High(lstat.Items) do
  begin
    sgItems.Cells[1,i+1]:=GetTL2Item(lstat.Items[i].id);
    sgItems.Cells[2,i+1]:='0x'+IntToHex(lstat.Items[i].field1,8);
    sgItems.Cells[3,i+1]:='0x'+IntToHex(lstat.Items[i].field2,8);
    sgItems.Cells[4,i+1]:='0x'+IntToHex(lstat.Items[i].field3,8);
    sgItems.Cells[5,i+1]:='0x'+IntToHex(lstat.Items[i].field4,8);
  end;
  sgItems.EndUpdate;

  // skills
  sgSkills.BeginUpdate;
  sgSkills.Clear;
  sgSkills.RowCount:=1+Length(lstat.Skills);
  for i:=0 to High(lstat.Skills) do
  begin
    sgSkills.Cells[0,i+1]:=GetTL2Skill(lstat.Skills[i].id);
    sgSkills.Cells[1,i+1]:=IntToStr(lstat.Skills[i].field1);
    sgSkills.Cells[2,i+1]:=IntToStr(lstat.Skills[i].field2);
    sgSkills.Cells[3,i+1]:=IntToStr(lstat.Skills[i].field3);
  end;
  sgSkills.EndUpdate;

  // unknown
  sgUnknown.BeginUpdate;
  sgUnknown.Clear;
  sgUnknown.RowCount:=1+Length(lstat.Unknown);
  for i:=0 to High(lstat.Unknown) do
  begin
    sgUnknown.Cells[ 0,i+1]:=FloatToStr(lstat.Unknown[i].field1);
    sgUnknown.Cells[ 1,i+1]:=IntToStr(lstat.Unknown[i].field2);
    sgUnknown.Cells[ 2,i+1]:=IntToStr(lstat.Unknown[i].field3);
    sgUnknown.Cells[ 3,i+1]:=IntToStr(lstat.Unknown[i].field4);
    sgUnknown.Cells[ 4,i+1]:=IntToStr(lstat.Unknown[i].field5);
    sgUnknown.Cells[ 5,i+1]:='0x'+IntToHex(lstat.Unknown[i].field6,8);
    sgUnknown.Cells[ 6,i+1]:=IntToStr(lstat.Unknown[i].field7);
    sgUnknown.Cells[ 7,i+1]:=IntToStr(lstat.Unknown[i].field8);
    sgUnknown.Cells[ 8,i+1]:=IntToStr(lstat.Unknown[i].field9);
    sgUnknown.Cells[ 9,i+1]:=IntToStr(lstat.Unknown[i].field10);
  end;
  sgUnknown.EndUpdate;

  // area 1
  sgArea1.BeginUpdate;
  sgArea1.Clear;
  sgArea1.RowCount:=1+Length(lstat.Area1);
  for i:=0 to High(lstat.Area1) do
  begin
    sgArea1.Cells[0,i+1]:=lstat.Area1[i].name;
    i2f.i:=lstat.Area1[i].value;
    sgArea1.Cells[1,i+1]:=//{'0x'+HexStr(i2f.i,8);//}FloatToStr(i2f.f);
        SecToTime(Trunc(i2f.f));
//    IntToStr(trunc(i2f.f))+':'+IntToStr(Trunc(Frac(i2f.f)*60));
  end;
  sgArea1.EndUpdate;

  // area 2
  sgArea2.BeginUpdate;
  sgArea2.Clear;
  sgArea2.RowCount:=1+Length(lstat.Area2);
  for i:=0 to High(lstat.Area2) do
  begin
    sgArea2.Cells[0,i+1]:=lstat.Area2[i].name;
    sgArea2.Cells[1,i+1]:=IntToStr(lstat.Area2[i].value);
  end;
  sgArea2.EndUpdate;

  // stats
  sgStat.BeginUpdate;
  sgStat.Clear;
  sgStat.RowCount:=1+Length(lstat.Stats);
  for i:=0 to High(lstat.Stats) do
  begin
    sgStat.Cells[0,i+1]:=GetTL2Mobs(lstat.Stats[i].id);
    sgStat.Cells[1,i+1]:=IntToStr  (lstat.Stats[i].value);
  end;
  sgStat.EndUpdate;

end;

end.

