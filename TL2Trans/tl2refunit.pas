{
  This object don't have any text info.
  It saves just text reference info like: file-line-tag
  and reference to base placement for doubles
}
unit TL2RefUnit;

interface

uses
  Classes;

const
  RefSizeV1 = SizeOf(Integer)*4;

type
  TTL2Reference = object
  private
    type
      tRefData = packed record
        // constant part (fills on scan)
        _file: integer;
        _tag : integer;
        _line: integer;
        // runtime part
        _dup : integer; // =0 = dupe in preloads
                        // >0 = ref # +1
                        // <0 - base, count of doubles
        _flag: integer;
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

    function  GetOpt(idx,aflag:integer):boolean;
    procedure SetOpt(idx,aflag:integer; aval:boolean);
    function  GetFlag(idx:integer):integer;
    procedure SetFlag(idx:integer; aval:integer);
    function  GetDup (idx:integer):integer;
    procedure SetDup (idx:integer; aval:integer);
    procedure SetRoot(const aroot:String);
    function  GetRoot():string;
  
  public
    procedure Init;
    procedure Free;

    function AddRef(const afile,atag:AnsiString; aline:integer):integer;
    function GetRef(idx:integer; var afile,atag:AnsiString):integer;

    function GetLine(idx:integer):integer;
    function GetFile(idx:integer):AnsiString;
    function GetTag (idx:integer):AnsiString;

    procedure SaveToStream  (astrm:TStream);
    procedure LoadFromStream(astrm:TStream);

    property  Root:AnsiString read GetRoot write SetRoot;

    property  RefCount :integer read cntRef;
    property  FileCount:integer read cntFiles;
    property  TagCount :integer read cntTags;

    property  Dupe   [idx:integer]:integer         read GetDup  write SetDup;
    property  Flag   [idx:integer]:integer         read GetFlag write SetFlag;
    property  IsSkill[idx:integer]:boolean index 1 read GetOpt  write SetOpt;
  end;


implementation

const
  rfIsSkill = 1;

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
    _flag:=0;
//!!
    if Pos('SKILLS'+DirectorySeparator,afile)=7 then
      _flag:=_flag or rfIsSkill;
  end;
  result:=cntRef;
  inc(cntRef);
end;

function TTL2Reference.GetRef(idx:integer; var afile,atag:AnsiString):integer;
begin
  if (idx>=0) and (idx<cntRef) then
  begin
    with arRef[idx] do
    begin
      afile :=arFiles[_file];
      atag  :=arTags [_tag];
      result:=_line;
    end;
  end
  else
    result:=-1;
end;

//--- File line ---

function TTL2Reference.GetLine(idx:integer):integer;
begin
  if (idx>=0) and (idx<cntRef) then
    result:=arRef[idx]._line
  else
    result:=-1;
end;

//--- File (path+name) ---

function TTL2Reference.GetFile(idx:integer):AnsiString;
begin
  if (idx>=0) and (idx<cntRef) then
    result:=arFiles[arRef[idx]._file]
  else
    result:='';
end;

//--- Attrib (tag) ---

function TTL2Reference.GetTag(idx:integer):AnsiString;
begin
  if (idx>=0) and (idx<cntRef) then
    result:=arTags[arRef[idx]._tag]
  else
    result:='';
end;

//----- Properties -----

//--- Root ---

procedure TTL2Reference.SetRoot(const aroot:String);
begin
  if fRoot<>aroot then
    fRoot:=aroot;
end;

function TTL2Reference.GetRoot():string;
begin
  result:=fRoot;
end;

//--- Duplicates ---

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

//--- Option flag ---

function TTL2Reference.GetFlag(idx:integer):integer;
begin
  if (idx>=0) and (idx<cntRef) then
    result:=arRef[idx]._flag
  else
    result:=0;
end;

procedure TTL2Reference.SetFlag(idx:integer; aval:integer);
begin
  if (idx>=0) and (idx<cntRef) then
    arRef[idx]._flag:=aval;
end;

//--- Separate option ---

function TTL2Reference.GetOpt(idx,aflag:integer):boolean;
begin
  if (idx>=0) and (idx<cntRef) then
    result:=(arRef[idx]._flag and aflag)<>0
  else
    result:=false;
end;

procedure TTL2Reference.SetOpt(idx,aflag:integer; aval:boolean);
var
  f:integer;
begin
  if (idx>=0) and (idx<cntRef) then
  begin
    f:=(arRef[idx]._flag and not aflag);
    if aval then
      f:=f or aflag;
    arRef[idx]._flag:=f;
  end;
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
  lflag,lpos,i,lrefsize,lsize:integer;
begin
  lpos    :=astrm.Position;
  lrefsize:=0;
  try
    lrefsize:=astrm.ReadDWord();
    inc(lpos,SizeOf(DWord));

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
    if lsize=SizeOf(tRefData) then
      astrm.ReadBuffer(arRef[0],SizeOf(tRefData)*cntRef)
    else
    begin
      for i:=0 to cntRef-1 do
        astrm.ReadBuffer(arRef[i],lsize);

      if lsize=RefSizeV1 then
        for i:=0 to cntRef-1 do
        begin
          lflag:=0;
          if Pos('SKILLS'+DirectorySeparator,arFiles[arRef[i]._file])=7 then
            lflag:=lflag or rfIsSkill;
          arRef[i]._flag:=lflag;
        end;

    end;

    if astrm.Position<(lpos+lrefsize) then
    begin
      Root:=astrm.ReadAnsiString();
    end
    else
      Root:='';
  except
  end;

  astrm.Position:=lpos+lrefsize;
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
