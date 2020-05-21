unit formSkills;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Grids,
  tl2char;

type

  { TfmSkills }

  TfmSkills = class(TForm)
    sgSkills: TStringGrid;
  private
    FChar:TTL2Character;

  public
    procedure FillInfo(aChar:TTL2Character);
  end;


implementation

{$R *.lfm}

uses
  tl2types,
  tl2db;

procedure TfmSkills.FillInfo(aChar:TTL2Character);
var
  i,j:integer;
  lid:TL2ID;
  sa:TStringArray;
  ls:string;
begin
  FChar:=aChar;

  sgSkills.BeginUpdate;
  sgSkills.Clear;
  sgSkills.RowCount:=1;

  lid:=aChar.OriginId;
  if lid=TL2IdEmpty then lid:=aChar.ImageId;
  ls:=GetSkillList(lid);
  if ls<>'' then
  begin
    ls:=Copy(ls,2,Length(ls)-2);
    sa:=ls.Split(',');
    sgSkills.RowCount:=1+Length(sa);
    for i:=0 to High(sa) do
    begin
      sgSkills.Cells[1,i+1]:=GetTL2Skill(sa[i],lid);
      sgSkills.Cells[2,i+1]:='0';
      for j:=0 to High(aChar.Skills) do
      begin
        if lid=aChar.Skills[j].id then
        begin
          sgSkills.Cells[2,i+1]:=IntToStr(aChar.Skills[j].value);
          break;
        end;
      end;
    end;
  end;

  sgSkills.EndUpdate;
end;

end.

