{
  impossible to make unit coz we need source lines?
  by other side, we make REF, not storage
  parent will add ref and then need to change DUP?
}
unit TL2RefUnit;

interface

uses
  Classes;

type
  TTL2Reference = object
  private
    type
      tRefData = record
        // constant part (fills on scan)
        _file: integer;
        _tag : integer;
        _line: integer;
        // runtime part
        _dup : integer; // =0 = dupe in preloads
                        // >0 = ref # +1
                        // <0 - base, count of doubles
      end;

  private
    arRef   : array of tRefData;
    arFiles : array of AnsiString;
    arTags  : array of AnsiString;

    fRoot   : AnsiString;

    cntRef  : integer;
    cntFiles: integer;
    cntTags : integer;

    function AddFile(const fname:AnsiString):integer;
    function AddTag (const atag :AnsiString):integer;

    function  GetDup(idx:integer):integer;
    procedure SetDup(idx:integer; aval:integer);
  
  public
    procedure Init;
    procedure Free;

    function AddRef(const afile,atag:AnsiString; aline:integer):integer;
    function GetRef(idx:integer; var afile,atag:AnsiString; var aline:integer):boolean;

    function GetLine(idx:integer):integer;
    function GetFile(idx:integer):AnsiString;
    function GetTag (idx:integer):AnsiString;

    procedure SaveToStream  (astrm:TStream);
    procedure LoadFromStream(astrm:TStream);

    property  Root:AnsiString read fRoot write fRoot;

    property  RefCount :integer read cntRef;
    property  FileCount:integer read cntFiles;
    property  TagCount :integer read cntTags;
    property  Dupe[idx:integer]:integer read GetDup write SetDup;
  end;


implementation

const
  increment = 50;

function TTL2Reference.AddFile(const fname:AnsiString):integer;
var
  i:integer;
begin
  for i:=0 to cntFiles-1 do
  begin
    if fname = arFiles[i] then
    begin
      result:=i;
      exit;
    end;
  end;

  if cntFiles>=Length(arFiles) then
  begin
    SetLength(arFiles,cntFiles+increment*10);
  end;
  arFiles[cntFiles]:=fname;
  result:=cntFiles;
  inc(cntFiles);
end;

function TTL2Reference.AddTag(const atag:AnsiString):integer;
var
  i:integer;
begin
  for i:=0 to cntTags-1 do
  begin
    if atag = arTags[i] then
    begin
      result:=i;
      exit;
    end;
  end;

  if cntTags>=Length(arTags) then
  begin
    SetLength(arTags,cntTags+increment);
  end;
  arTags[cntTags]:=atag;
  result:=cntTags;
  inc(cntTags);
end;

function TTL2Reference.AddRef(const afile,atag:AnsiString; aline:integer):integer;
begin
  if cntRef>=Length(arRef) then
    SetLength(arRef,Length(arRef)+increment*20);

  with arRef[cntRef] do
  begin
    _file:=AddFile(afile);
    _tag :=AddTag (atag);
    _line:=aline;
    _dup :=-1;
  end;
  result:=cntRef;
  inc(cntRef);
end;

function TTL2Reference.GetRef(idx:integer; var afile,atag:AnsiString; var aline:integer):boolean;
begin
  if (idx>=0) and (idx<cntRef) then
  begin
    result:=true;
    afile:=arFiles[arRef[idx]._file];
    atag :=arTags [arRef[idx]._tag];
    aline:=arRef[idx]._line;
  end
  else
    result:=false;
end;

function TTL2Reference.GetLine(idx:integer):integer;
begin
  if (idx>=0) and (idx<cntRef) then
    result:=arRef[idx]._line
  else
    result:=-1;
end;

function TTL2Reference.GetFile(idx:integer):AnsiString;
begin
  if (idx>=0) and (idx<cntRef) then
    result:=arFiles[arRef[idx]._file]
  else
    result:='';
end;

function TTL2Reference.GetTag(idx:integer):AnsiString;
begin
  if (idx>=0) and (idx<cntRef) then
    result:=arTags[arRef[idx]._tag]
  else
    result:='';
end;

function TTL2Reference.GetDup(idx:integer):integer;
begin
  if (idx>=0) and (idx<cntRef) then
    result:=arRef[idx]._dup
  else
    result:=0;
end;

procedure TTL2Reference.SetDup(idx:integer; aval:integer);
begin
  if (idx>=0) and (idx<cntRef) then
    arRef[idx]._dup:=aval;
end;

//-----  -----

procedure TTL2Reference.SaveToStream(astrm:TStream);
var
  i:integer;
  lpos,lsize:integer;
begin
  try
    lpos:=astrm.Position;
    astrm.WriteDWord(0);

    astrm.WriteDWord(cntFiles);
    for i:=0 to cntFiles-1 do
    begin
      astrm.WriteAnsiString(arFiles[i]);
    end;

    astrm.WriteDWord(cntTags);
    for i:=0 to cntTags-1 do
    begin
      astrm.WriteAnsiString(arTags[i]);
    end;

    astrm.WriteDWord(cntRef);
    astrm.WriteWord(SizeOf(tRefData));
    if cntRef>0 then
      astrm.WriteBuffer(arRef[0],SizeOf(tRefData)*cntRef);

    astrm.WriteAnsiString(Root);

    lsize:=astrm.Position-lpos-4;
    astrm.Position:=lpos;
    astrm.WriteDWord(lsize);
    astrm.Position:=lpos+lsize;
  except
  end;
end;

//-----  -----

procedure TTL2Reference.LoadFromStream(astrm:TStream);
var
  lpos,i,lrefsize,lsize:integer;
begin
  try
    lrefsize:=astrm.Position+astrm.ReadDWord();
    lpos:=astrm.Position;

    cntFiles:=astrm.ReadDWord();
    SetLength(arFiles,cntFiles);
    for i:=0 to cntFiles-1 do
      arFiles[i]:=astrm.ReadAnsiString();

    cntTags:=astrm.ReadDWord();
    SetLength(arTags,cntTags);
    for i:=0 to cntTags-1 do
      arTags[i]:=astrm.ReadAnsiString();

    cntRef:=astrm.ReadDWord();
    SetLength(arRef,cntRef);
    lsize:=astrm.ReadWord();
    for i:=0 to cntRef-1 do
      astrm.ReadBuffer(arRef[i],lsize);

    if astrm.Position<(lpos+lrefsize) then
    begin
      Root:=astrm.ReadAnsiString();
    end
    else
      Root:='';
  except
  end;
end;

//-----  -----

procedure TTL2Reference.Init;
begin
  cntRef  :=0; SetLength(arRef  ,0);
  cntFiles:=0; SetLength(arFiles,0);
  cntTags :=0; SetLength(arTags ,0);
end;

procedure TTL2Reference.Free;
begin
  SetLength(arRef  ,0);
  SetLength(arFiles,0);
  SetLength(arTags ,0);
end;

end.
