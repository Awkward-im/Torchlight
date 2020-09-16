unit formStat;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, Grids,
  StdCtrls, Buttons, tl2save;

type

  { TfmStat }

  TfmStat = class(TForm)
    bbClearLearnHistory: TBitBtn;
    gbInitial: TGroupBox;
    edName : TEdit;
    lblSkillHistoryTitle: TLabel;
  lblName : TLabel;
    edClass: TEdit;  lblClass: TLabel;
    edPet  : TEdit;  lblPet  : TLabel;
    lbSkillHistory: TListBox;

    pcStatistic: TPageControl;
    tsLearn: TTabSheet;

    tsCommon : TTabSheet;
    tsMobs   : TTabSheet;  sgMobs   : TStringGrid;
    tsItems  : TTabSheet;  sgItems  : TStringGrid;
    tsSkills : TTabSheet;  sgSkills : TStringGrid;
    tsLevelUp: TTabSheet;  sgLevelUp: TStringGrid;
    tsArea1  : TTabSheet;  sgArea1  : TStringGrid;
    tsArea2  : TTabSheet;  sgArea2  : TStringGrid;
    tsKillers: TTabSheet;  sgKillers: TStringGrid;
    procedure bbClearLearnHistoryClick(Sender: TObject);
    procedure sgCompareCells(Sender: TObject; ACol, ARow, BCol,
      BRow: Integer; var Result: integer);
  private
    SGame:TTL2SaveFile;

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

procedure TfmStat.bbClearLearnHistoryClick(Sender: TObject);
var
  llist:TL2IdList;
begin
  llist:=SGame.History;
  SetLength(llist,0);
  SGame.History:=llist;

  lbSkillHistory.Clear;
  bbClearLearnHistory.Enabled:=false;
end;

procedure TfmStat.sgCompareCells(Sender: TObject; ACol, ARow, BCol,
  BRow: Integer; var Result: integer);
var
  s1,s2:string;
begin
  s1:=(Sender as TStringGrid).Cells[ACol,ARow];
  s2:=(Sender as TStringGrid).Cells[BCol,BRow];
  if (ACol=0) or
    ((ACol>1) and (Pos(':',TStringGrid(Sender).Cells[ACol,ARow])=0)) then
  begin
    result:=StrToIntDef(s1,0)-
            StrToIntDef(s2,0);
  end
  else
    result:=CompareStr(s1,s2);

  if (Sender as TStringGrid).SortOrder=soDescending then
    result:=-result;
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
  SGame:=aSGame;

  lstat:=aSGame.Stats;

  // common
  edName .Text:=lstat.PlayerName;
  edClass.Text:=lstat.PlayerClass;
  edPet  .Text:=lstat.PetClass;

  // skill learn history
  lbSkillHistory.Clear;
  for i:=0 to High(aSGame.History) do
    lbSkillHistory.AddItem(GetTL2Skill(aSGame.History[i]),nil);
  bbClearLearnHistory.Enabled:=Length(aSGame.History)>0;

  // mobs
  sgMobs.BeginUpdate;
  sgMobs.Clear;
  sgMobs.RowCount:=1+Length(lstat.Mobs);
  for i:=0 to High(lstat.Mobs) do
  begin
    sgMobs.Cells[ 1,i+1]:=GetTL2Mob(lstat.Mobs[i].id);
    sgMobs.Cells[ 2,i+1]:=IntToStr (lstat.Mobs[i].field1);
    sgMobs.Cells[ 3,i+1]:=IntToStr (lstat.Mobs[i].field2);
    sgMobs.Cells[ 4,i+1]:=IntToStr (lstat.Mobs[i].exp   );
    sgMobs.Cells[ 5,i+1]:=IntToStr (lstat.Mobs[i].field4);
    sgMobs.Cells[ 6,i+1]:=IntToStr (lstat.Mobs[i].field5);
    sgMobs.Cells[ 7,i+1]:=IntToStr (lstat.Mobs[i].field6);
    sgMobs.Cells[ 8,i+1]:=IntToStr (lstat.Mobs[i].field7);
    sgMobs.Cells[ 9,i+1]:=IntToStr (lstat.Mobs[i].field8);
    sgMobs.Cells[10,i+1]:=IntToStr (lstat.Mobs[i].field9);
  end;
  sgMobs.EndUpdate;

  // items
  sgItems.BeginUpdate;
  sgItems.Clear;
  sgItems.RowCount:=1+Length(lstat.Items);
  for i:=0 to High(lstat.Items) do
  begin
    sgItems.Cells[1,i+1]:=GetTL2Item(lstat.Items[i].id);
    sgItems.Cells[2,i+1]:=IntToStr  (lstat.Items[i].Normals);
    sgItems.Cells[3,i+1]:=IntToStr  (lstat.Items[i].Blues);
    sgItems.Cells[4,i+1]:=IntToStr  (lstat.Items[i].Greens);
    sgItems.Cells[5,i+1]:=IntToStr  (lstat.Items[i].Golden);
    sgItems.Cells[6,i+1]:=IntToStr  (lstat.Items[i].IsSet);
    sgItems.Cells[7,i+1]:=IntToStr  (lstat.Items[i].Bonuses);
    sgItems.Cells[8,i+1]:=IntToStr  (lstat.Items[i].field7);
  end;
  sgItems.EndUpdate;

  // skills
  sgSkills.BeginUpdate;
  sgSkills.Clear;
  sgSkills.RowCount:=1+Length(lstat.Skills);
  for i:=0 to High(lstat.Skills) do
  begin
    sgSkills.Cells[0,i+1]:=GetTL2Skill(lstat.Skills[i].id);
    sgSkills.Cells[1,i+1]:=IntToStr(lstat.Skills[i].times);
    sgSkills.Cells[2,i+1]:=IntToStr(lstat.Skills[i].field2);
    sgSkills.Cells[3,i+1]:=IntToStr(lstat.Skills[i].level);
  end;
  sgSkills.EndUpdate;

  // Levelup
  sgLevelUp.BeginUpdate;
  sgLevelUp.Clear;
  sgLevelUp.RowCount:=1+Length(lstat.levelup);
  for i:=0 to High(lstat.levelup) do
  begin
    sgLevelUp.Cells[ 0,i+1]:=IntToStr(i+2);
    sgLevelUp.Cells[ 1,i+1]:=SecToTime(Trunc(lstat.levelup[i].uptime));
    sgLevelUp.Cells[ 2,i+1]:=IntToStr(lstat.levelup[i].MinPhys);
    sgLevelUp.Cells[ 3,i+1]:=IntToStr(lstat.levelup[i].MaxPhys);
    sgLevelUp.Cells[ 4,i+1]:=IntToStr(lstat.levelup[i].field4);
    sgLevelUp.Cells[ 5,i+1]:=IntToStr(lstat.levelup[i].field5);
    sgLevelUp.Cells[ 6,i+1]:=IntToStr(lstat.levelup[i].GoldGet);
    sgLevelUp.Cells[ 7,i+1]:=IntToStr(lstat.levelup[i].field7);
    sgLevelUp.Cells[ 8,i+1]:=IntToStr(lstat.levelup[i].field7);
    sgLevelUp.Cells[ 9,i+1]:=IntToStr(lstat.levelup[i].field8);
    sgLevelUp.Cells[10,i+1]:=IntToStr(lstat.levelup[i].RightMinPhys);
    sgLevelUp.Cells[11,i+1]:=IntToStr(lstat.levelup[i].RightMaxPhys);
    sgLevelUp.Cells[12,i+1]:=IntToStr(lstat.levelup[i].field12);
  end;
  sgLevelUp.EndUpdate;

  // area 1
  sgArea1.BeginUpdate;
  sgArea1.Clear;
  sgArea1.RowCount:=1+Length(lstat.Area1);
  for i:=0 to High(lstat.Area1) do
  begin
    sgArea1.Cells[1,i+1]:=lstat.Area1[i].name;
    i2f.i:=lstat.Area1[i].value;
    sgArea1.Cells[2,i+1]:= SecToTime(Trunc(i2f.f));
  end;
  sgArea1.EndUpdate;

  // area 2
  sgArea2.BeginUpdate;
  sgArea2.Clear;
  sgArea2.RowCount:=1+Length(lstat.Area2);
  for i:=0 to High(lstat.Area2) do
  begin
    sgArea2.Cells[1,i+1]:=lstat.Area2[i].name;
    sgArea2.Cells[2,i+1]:=IntToStr(lstat.Area2[i].value);
  end;
  sgArea2.EndUpdate;

  // killers
  sgKillers.BeginUpdate;
  sgKillers.Clear;
  sgKillers.RowCount:=1+Length(lstat.Killers);
  for i:=0 to High(lstat.Killers) do
  begin
    sgKillers.Cells[1,i+1]:=GetTL2Mob(lstat.Killers[i].id);
    sgKillers.Cells[2,i+1]:=IntToStr (lstat.Killers[i].value);
  end;
  sgKillers.EndUpdate;

end;

end.

