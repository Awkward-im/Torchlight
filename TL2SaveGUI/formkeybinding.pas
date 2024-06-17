unit formKeyBinding;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Grids,
  tlsave;

type

  { TfmKeyBinding }

  TfmKeyBinding = class(TForm)
    sgKeyBinding: TStringGrid;
  private

  public
    procedure FillInfo(aSGame:TTLSaveFile);

  end;


implementation

{$R *.lfm}

uses
  rgglobal,
  tl2db;

resourcestring
  rsItem  = 'item';
  rsSkill = 'skill';

  rsNotUsed = 'Not used';

procedure TfmKeyBinding.FillInfo(aSGame:TTLSaveFile);
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
            sgKeyBinding.Cells[1,j]:=rsItem;
            sgKeyBinding.Cells[2,j]:=GetTL2Item(id,lmod);
            sgKeyBinding.Cells[3,j]:=GetTL2Mod(lmod);
          end;

          2: begin
            sgKeyBinding.Cells[1,j]:=rsSkill;
            sgKeyBinding.Cells[2,j]:=GetTL2Skill(id,lmod);
            sgKeyBinding.Cells[3,j]:=GetTL2Mod(lmod);
          end;

        else
          lmod:='';
          sgKeyBinding.Cells[2,j]:=rsNotUsed;// GetTL2Skill(id,lmod);
          sgKeyBinding.Cells[3,j]:= '';//GetTL2Mod(lmod);
          if lmod<>'' then
            sgKeyBinding.Cells[1,j]:=rsSkill
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
        if id<>RGIdEmpty then
        begin
          j:=sgKeyBinding.RowCount;
          sgKeyBinding.RowCount:=sgKeyBinding.RowCount+1;
          sgKeyBinding.Cells[0,j]:='F'+IntToStr(i+1);
          sgKeyBinding.Cells[1,j]:=rsSkill;
          sgKeyBinding.Cells[2,j]:=GetTL2Skill(id,lmod);
          sgKeyBinding.Cells[3,j]:=GetTL2Mod(lmod);
        end;
      end;
  end;

  sgKeyBinding.AutoAdjustColumns;
  sgKeybinding.EndUpdate;
end;

end.
