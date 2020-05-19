unit formKeyBinding;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Grids,
  tl2save;

type

  { TfmKeyBinding }

  TfmKeyBinding = class(TForm)
    sgKeyBinding: TStringGrid;
  private

  public
    procedure FillInfo(aSGame:TTL2SaveFile);

  end;


implementation

{$R *.lfm}

uses
  tl2types,
  tl2db;

procedure TfmKeyBinding.FillInfo(aSGame:TTL2SaveFile);
var
  i,j:integer;
  lmod:string;
begin
  sgKeybinding.BeginUpdate;
  sgKeybinding.Clear;
  sgKeyBinding.RowCount:=1;

  if Length(aSGame.Keys)>0 then
  begin
    for i:=0 to High(aSGame.Keys) do
    begin
      j:=sgKeyBinding.RowCount;
      sgKeyBinding.RowCount:=sgKeyBinding.RowCount+1;
      with aSGame.Keys[i] do
      begin
        sgKeybinding.Cells[0,j]:=GetTL2KeyType(key);
        case datatype of
          0: begin
            sgKeyBinding.Cells[1,j]:='item';
            sgKeyBinding.Cells[2,j]:=GetTL2Item(id,lmod);
            sgKeyBinding.Cells[3,j]:=GetTL2Mod(lmod);
          end;

          2: begin
            sgKeyBinding.Cells[1,j]:='skill';
            sgKeyBinding.Cells[2,j]:=GetTL2Skill(id,lmod);
            sgKeyBinding.Cells[3,j]:=GetTL2Mod(lmod);
          end;

        else
          sgKeyBinding.Cells[2,j]:=GetTL2Skill(id,lmod);
          sgKeyBinding.Cells[3,j]:=GetTL2Mod(lmod);
          if lmod<>'' then
            sgKeyBinding.Cells[1,j]:='skill'
          else
            sgKeyBinding.Cells[1,j]:='['+inttostr(datatype)+']';
        end;
      end;
    end;
  end;
  if Length(aSGame.Functions)>0 then
  begin
    for i:=0 to High(aSGame.Functions) do
      with aSGame.Functions[i] do
      begin
        if id<>TL2IdEmpty then
        begin
          j:=sgKeyBinding.RowCount;
          sgKeyBinding.RowCount:=sgKeyBinding.RowCount+1;
          sgKeyBinding.Cells[0,j]:='F'+IntToStr(i+1);
          sgKeyBinding.Cells[1,j]:='skill';
          sgKeyBinding.Cells[2,j]:=GetTL2Skill(id,lmod);
          sgKeyBinding.Cells[3,j]:=GetTL2Mod(lmod);
        end;
      end;
  end;
  sgKeyBinding.AutoAdjustColumns;
  sgKeybinding.EndUpdate;
end;

end.
