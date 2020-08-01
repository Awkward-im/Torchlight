unit addons;

interface

uses
  Grids;

function SearchForFileName(const adir,aname:string):string;
function DeleteSelectedRows(agrid:TStringGrid):boolean;

implementation

uses
  SysUtils;

// from LazFileUtils
function ExtractFileNameOnly(const AFilename: string): string;
var
  StartPos: Integer;
  ExtPos: Integer;
begin
  StartPos:=length(AFilename)+1;
  while (StartPos>1)
  and not (AFilename[StartPos-1] in AllowDirectorySeparators)
  {$IF defined(Windows) or defined(HASAMIGA)}and (AFilename[StartPos-1]<>':'){$ENDIF}
  do
    dec(StartPos);
  ExtPos:=length(AFilename);
  while (ExtPos>=StartPos) and (AFilename[ExtPos]<>'.') do
    dec(ExtPos);
  if (ExtPos<StartPos) then ExtPos:=length(AFilename)+1;
  Result:=copy(AFilename,StartPos,ExtPos-StartPos);
end;

function SearchForFileName(const adir,aname:string):string;
var
  sr:TSearchRec;
  lname:string;
begin
  result:='';
  if aname='' then exit;

  if FindFirst(adir+'\*.*',faAnyFile and faDirectory,sr)=0 then
  begin
    repeat
      lname:=adir+'\'+sr.Name;
      if (sr.Attr and faDirectory)=faDirectory then
      begin
        if (sr.Name<>'.') and (sr.Name<>'..') then
        begin
          result:=SearchForFileName(lname,aname);
          if result<>'' then break;
        end;
      end
      else
      begin
        if UpCase(ExtractFileNameOnly(lname))=aname then
        begin
          result:=lname;
          break;
        end;
      end;
    until FindNext(sr)<>0;
    FindClose(sr);
  end;
end;

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
