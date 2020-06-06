unit addons;

interface

uses
  Grids;

function DeleteSelectedRows(agrid:TStringGrid):boolean;

implementation

function DeleteSelectedRows(agrid:TStringGrid):boolean;
var
  i,col:integer;
{
  lcnt:integer;
  ar:array of integer;
}
begin
  result:=false;

  col:=agrid.ColCount-1;

  for i:=agrid.RowCount-1 downto agrid.FixedRows do
    if agrid.IsCellSelected[agrid.Col,i] then
    begin
      agrid.Objects[col,i]:=TObject(1);
      result:=true;
    end;

  for i:=agrid.RowCount-1 downto agrid.FixedRows do
    if agrid.Objects[col,i]<>nil then
      agrid.DeleteRow(i);
{
  // 1 - calc lines amount
  lcnt:=0;
  ar:=nil;
  for i:=agrid.RowCount-1 downto agrid.FixedRows do
    if agrid.IsCellSelected[agrid.Col,i] then
       inc(lcnt);
  result:=lcnt>0;
  SetLength(ar,lcnt);
  // 2 - create numbers list
  lcnt:=0;
  for i:=agrid.RowCount-1 downto agrid.FixedRows do
  begin
    if agrid.IsCellSelected[agrid.Col,i] then
    begin
      ar[lcnt]:=i;
      inc(lcnt);
    end;
  end;
  // 3 - delete rows
  for i:=0 to lcnt-1 do
    agrid.DeleteRow(ar[i]);
  SetLength(ar,0);
}
end;

end.
