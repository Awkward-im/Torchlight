unit formQuests;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Grids,
  tl2save;

type

  { TfmQuests }

  TfmQuests = class(TForm)
    sgQuests: TStringGrid;
  private

  public
    procedure FillGrid(asg:TTL2SaveFile);

  end;

var
  fmQuests: TfmQuests;

implementation

{$R *.lfm}

uses
  tl2types,
  tl2db;

procedure TfmQuests.FillGrid(asg:TTL2SaveFile);
var
  lname:string;
  i,j:integer;
  lmod:TL2ID;
begin
  sgQuests.BeginUpdate;
  sgQuests.Clear;

  sgQuests.RowCount:=1;
  j:=1;
  if Length(asg.QuestsDone)>0 then
  begin
    sgQuests.RowCount:=sgQuests.RowCount+Length(asg.QuestsDone);
    for i:=0 to High(asg.QuestsDone) do
    begin
      sgQuests.Cells[0,j]:=GetTL2Quest(asg.QuestsDone[i],lmod,lname);
      sgQuests.Cells[1,j]:='1';
      sgQuests.Cells[2,j]:=lname;
      sgQuests.Cells[3,j]:=GetTL2Mod(lmod);

      inc(j);
    end;
  end;

  if Length(asg.QuestsUnDone)>0 then
  begin
    sgQuests.RowCount:=sgQuests.RowCount+Length(asg.QuestsUnDone);
    for i:=0 to High(asg.QuestsUnDone) do
    begin
      sgQuests.Cells[0,j]:=GetTL2Quest(asg.QuestsUnDone[i].id,lmod,lname);
      sgQuests.Cells[1,j]:='0';
      sgQuests.Cells[2,j]:=lname;
      sgQuests.Cells[3,j]:=GetTL2Mod(lmod);

      inc(j);
    end;
  end;

  sgQuests.EndUpdate;
end;

end.

