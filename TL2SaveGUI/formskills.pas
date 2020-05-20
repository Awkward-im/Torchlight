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

procedure TfmSkills.FillInfo(aChar:TTL2Character);
var
  i,j:integer;
begin
  FChar:=aChar;

  sgSkills.BeginUpdate;
  sgSkills.Clear;
  sgSkills.RowCount:=1;

  //  for i:=0 to  do
  begin
    for j:=0 to High(aChar.Skills) do
    begin

    end;

  end;

  sgSkills.EndUpdate;
end;

end.

