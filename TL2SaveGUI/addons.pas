unit addons;

interface

uses
  Grids;

function SearchForFileName(const adir,aname:string):string;
function DeleteSelectedRows(agrid:TStringGrid):boolean;

implementation

uses
  SysUtils,
  rgglobal;

const
  dirstart = 1024;
  dirdelta = 32;
var
  rootdir:string;
  dirlist:array of record
    full:string;
    name:string;
  end;
  dircnt:integer;

procedure GetDirList(const adir:string);
var
  sr:TSearchRec;
  lname:string;
begin
  if FindFirst(adir+'\*.*',faAnyFile and faDirectory,sr)=0 then
  begin
    repeat
      lname:=adir+'\'+sr.Name;
      if (sr.Attr and faDirectory)=faDirectory then
      begin
        if (sr.Name<>'.') and (sr.Name<>'..') then
        begin
          GetDirList(lname);
        end;
      end
      else
      begin
        if dircnt>=Length(dirlist) then
        begin
          if Length(dirlist)=0 then
            SetLength(dirlist,dirstart)
          else
            SetLength(dirlist,Length(dirlist)+dirdelta);
        end;
        dirlist[dircnt].full:=lname;
        dirlist[dircnt].name:=UpCase(ExtractNameOnly(sr.Name));
        inc(dircnt);

      end;
    until FindNext(sr)<>0;
    FindClose(sr);
  end;
end;

procedure MakeDirList(const aroot:string);
begin
  SetLength(dirlist,0);
  dircnt:=0;
  GetDirList(aroot);
end;

procedure FreeDirList();
begin
  SetLength(dirlist,0);
end;

function SearchForFileName(const adir,aname:string):string;
var
  ldir:string;
  i:integer;
begin
  if Pos(':',adir)=0 then
    ldir:=UpCase(rootdir+'\'+adir)
  else
    ldir:=UpCase(adir);

  for i:=0 to High(dirlist) do
  begin
    if Pos(ldir,UpCase(dirlist[i].full))=1 then
    begin
      if dirlist[i].name=aname then
      begin
        result:=dirlist[i].full;
        exit;
      end;
    end;
  end;
  result:='';
end;
{
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
}
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
  SetLength(ar,lcnt); // agrid.RowCount
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


initialization

  rootdir:=ExtractFileDir(ParamStr(0));
  MakeDirList(rootdir);

finalization

  FreeDirList;

end.
