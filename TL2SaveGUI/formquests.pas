unit formQuests;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Grids,
  tl2save;

type

  { TfmQuests }

  TfmQuests = class(TForm)
    sgQuests: TStringGrid;
  private

  public
    procedure FillInfo(aSGame:TTL2SaveFile);

  end;


implementation

{$R *.lfm}

uses
  tl2types,
  tl2db;

procedure TfmQuests.FillInfo(aSGame:TTL2SaveFile);
var
  lname:string;
  i,j:integer;
  lmod:string;
begin
  sgQuests.BeginUpdate;
  sgQuests.Clear;

  sgQuests.RowCount:=1;
  j:=1;
  if Length(aSGame.Quests.QuestsDone)>0 then
  begin
    sgQuests.RowCount:=sgQuests.RowCount+Length(aSGame.Quests.QuestsDone);
    for i:=0 to High(aSGame.Quests.QuestsDone) do
    begin
      sgQuests.Cells[0,j]:=GetTL2Quest(aSGame.Quests.QuestsDone[i],lmod,lname);
      sgQuests.Cells[1,j]:='1';
      sgQuests.Cells[2,j]:=lname;
      sgQuests.Cells[3,j]:=GetTL2Mod(lmod);
      sgQuests.Cells[4,j]:=HexStr(aSGame.Quests.QuestsDone[i],16);//IntToStr(aSGame.Quests.QuestsDone[i]);
      inc(j);
    end;
  end;

  if Length(aSGame.Quests.QuestsUnDone)>0 then
  begin
    sgQuests.RowCount:=sgQuests.RowCount+Length(aSGame.Quests.QuestsUnDone);
    for i:=0 to High(aSGame.Quests.QuestsUnDone) do
    begin
      sgQuests.Cells[0,j]:=GetTL2Quest(aSGame.Quests.QuestsUnDone[i].id,lmod,lname);
      sgQuests.Cells[1,j]:='0';
      sgQuests.Cells[2,j]:=lname;
      sgQuests.Cells[3,j]:=GetTL2Mod(lmod);
      sgQuests.Cells[4,j]:=HexStr(aSGame.Quests.QuestsUnDone[i].id,16);//IntToStr(aSGame.Quests.QuestsUnDone[i].id);
      inc(j);
    end;
  end;

  sgQuests.EndUpdate;
end;

end.

