{
  Right now dicts are unsorted, search 1 by 1
  check hash for non-ascii chars, Utf8 or utf16?
}
unit RGDict;

interface

//--- Functions

function RGHash(instr:PChar; alen:integer):dword;

function GetTagStr(adict:pointer; ahash:dword):PWideChar;
// return result coz we can use custom tags too
procedure LoadTags(out adict:pointer; const fname:string='');
procedure FreeTags(adict:pointer);

procedure FreeObjectInfo(aobj:pointer);
function LoadObjectInfo(const fname:string=''):pointer;
// no scene name = search in all
function SelectObject(adict:pointer; aid:dword; ascene:PWideChar=nil):pointer;
function GetObjectName    (aobj:pointer):PWideChar;
function GetObjectProperty(aobj:pointer; aid:dword; var aname:PWideChar):integer;

//----- Implementation

implementation

uses
  Classes,
  rgglobal,
  rgnode;

const
  defdictname = 'dictionary.txt';
  deftagsname = 'tags.dat';
  defobjname  = 'objects.dat';

const
  SIGN_UNICODE = $FEFF;
  SIGN_UTF8    = $BFBBEF;

type
  TDict = array of record
    name:string;
    hash:dword;
  end;

{$PUSH}
{$O-}
function RGHash(instr:PChar; alen:integer):dword;
var
  i:integer;
begin
  result:=alen;
  for i:=0 to alen-1 do
    result:=(result SHR 27) xor (result SHL 5) xor ORD(instr[i]);
end;
{$POP}

//===== DAT tags =====

var
  strbuf:WideString;

function GetTagStr(adict:pointer; ahash:dword):PWideChar;
var
  i:integer;
begin
  result:=nil;
  for i:=0 to High(TDict(adict)) do
  begin
    if TDict(adict)[i].hash=ahash then
    begin
      strbuf:=UTF8Decode(TDict(adict)[i].name);
      result:=pointer(strbuf);
      break;
    end;
  end;
end;

procedure FreeTags(adict:pointer);
begin
  SetLength(TDict(adict),0);
end;

function LoadTagsFile(const fname:string):TDict;
var
  lnode:pointer;
  pcw:PWideChar;
  lc,i,lcnt:integer;
begin
  result:=nil;

  lnode:=ParseDatFile(pointer(fname));
  if lnode<>nil then
  begin
    i:=0;
    lcnt:=0;
    lc:=GetChildCount(lnode);
    SetLength(result,lc div 2);
    while i<lc do
    begin
      pcw:=asString(GetChild(lnode,i));
      if asString(GetChild(lnode,i))<>nil then
      begin
        result[lcnt].name:=UTF8Encode(WideString(pcw));
        result[lcnt].hash:=AsUnsigned(GetChild(lnode,i));
        inc(lcnt);
      end;
      inc(i,2);
    end;
    DeleteNode(lnode);
  end;
end;

function LoadDictionary(const fname:string):TDict;
var
  sl:TStringList;
  ls:UTF8String;
  lns:string[31];
  lstart,lcnt,tmpi,i,p:integer;
begin
  result:=nil;

  sl:=TStringList.Create;
//  sl.DefaultEncoding:=TEncoding.UTF8;

  try
    try
      sl.LoadFromFile(fname{,TEncoding.UTF8});
      SetLength(result,sl.Count);
      lcnt:=0;
      for i:=0 to sl.Count-1 do
      begin
        ls:=sl[i];
        if ls<>'' then
        begin
          if ls[1]='-' then
            lstart:=2
          else
            lstart:=1;

          for p:=lstart to Length(ls) do
          begin
            if (ls[p] in ['0'..'9']) then
              lns[p]:=ls[p]
            else
            begin
              SetLength(lns,p-1);
              if lstart=2 then
              begin
                val(lns,tmpi);
                result[lcnt].hash:=dword(-tmpi);
              end
              else
                val(lns,result[lcnt].hash);
              result[lcnt].name:=Copy(ls,p+1);
              inc(lcnt);
              break;
            end;
          end;
        end;
      end;
      SetLength(result,lcnt);

    except
      if IsConsole then
      begin
        writeln('Can''t load '+fname);
        if ls<>'' then  writeln('Possible problem with ',ls);
      end;
      result:=nil;
    end;
  finally
    sl.Free;
  end;
end;

function LoadList(const fname:string):TDict;
var
  sl:TStringList;
  ls:string;
  lcnt,i:integer;
begin
  result:=nil;

  sl:=TStringList.Create;
  sl.LoadFromFile(fname{,TEncoding.UTF8});
  SetLength(result,sl.Count);
  lcnt:=0;
  for i:=0 to sl.Count-1 do
  begin
    ls:=sl[i];
    if ls<>'' then
    begin
      result[lcnt].name:=ls;
      result[lcnt].hash:=RGHash(pointer(ls),Length(ls));
      inc(lcnt);
    end;
  end;
  SetLength(result,lcnt);
  sl.Free;
end;

procedure LoadTags(out adict:pointer; const fname:string='');
var
  f:file of byte;
  buf:array [0..7] of byte;
  ls:string;
begin
  adict:=nil;

  // 1 - trying to open dict file (empty name = load defaults)
  if fname<>'' then
    ls:=fname
  else
    ls:=defdictname;

{$PUSH}
{$I-}
  Assign(f,ls);
  Reset(f);
  if IOResult<>0 then
  begin
    if fname='' then
    begin
      ls:=deftagsname;
      Assign(f,ls);
      Reset(f);
      if IOResult<>0 then
      begin
        if IsConsole then
        begin
          if fname='' then
            ls:='default tags file'
          else
            ls:='tag info file "'+fname+'"';
          writeln('Can''t open '+ls);
        end;
        exit;
      end;
    end
    else
    begin
      writeln('Can''t open '+ls);
      exit;
    end;
  end;
  BlockRead(f,buf,7);
  Close(f);
{$POP}

  // 2 - trying to recognize dic format: like "TAGS.DAT" or "dictionary.txt"
  if (pword(@buf)^=SIGN_UNICODE) and (buf[3]=ORD('[')) then
  begin
    TDict(adict):=LoadTagsFile(ls)
  end
  else if (CHAR(buf[0]) in ['-','0'..'9']) or
      (((pdword(@buf)^ and $FFFFFF)=SIGN_UTF8) and
       ((CHAR(buf[3]) in ['-','0'..'9']))) then
  begin
    TDict(adict):=LoadDictionary(ls);
  end
  else
    TDict(adict):=LoadList(ls);
end;

//===== Layout =====

//----- Objects.dat -----

function LoadObjectInfo(const fname:string=''):pointer;
var
  ls:string;
begin
  if fname='' then
    ls:=defobjname
  else
    ls:=fname;
  result:=pointer(ParseDatFile(pointer(ls)));

  if (result=nil) and IsConsole then
    writeln('Can''t load layout info from file "'+ls+'"');
end;

procedure FreeObjectInfo(aobj:pointer);
begin
  DeleteNode(aobj);
end;

function SelectObject(adict:pointer; aid:dword; ascene:PWideChar=nil):pointer;
var
  lscene,lsprop,lobj:pointer;
  lobjects,lparts:integer;
  lok:boolean;
begin
  result:=nil;

  for lparts:=0 to GetChildCount(adict)-1 do
  begin
    lscene:=GetChild(adict,lparts);
    // for all scenes
    if CompareWide(GetNodeName(lscene),'SCENE') then
    begin

      if ascene<>nil then
        lok:=CompareWide(AsString(FindChild(lscene,'NAME')),ascene)
      else
        lok:=true;

      if lok then
      begin
        lsprop:=FindChild(lscene,'OBJECT GROUP');
        if lsprop<>nil then
        begin
          // for all objects in scene group
          for lobjects:=0 to GetChildCount(lsprop)-1 do
          begin
            lobj:=GetChild(lsprop,lobjects);

            if AsUnsigned(FindChild(lobj,'ID'))=aid then
              exit(lobj);
          end;
        end;

        if ascene<>nil then
          break;
      end;
    end;
  end;
end;

function GetObjectName(aobj:pointer):PWideChar;
begin
  result:=AsString(FindChild(aobj,'NAME'))
end;

function GetObjectProperty(aobj:pointer; aid:dword; var aname:PWideChar):integer;
var
  lprop,lnode:pointer;
  pcw:PWideChar;
  i:integer;
begin
  result:=rgNotValid;
  aname:=nil;

  for i:=0 to GetChildCount(aobj)-1 do
  begin
    lprop:=GetChild(aobj,i);
    if (GetNodeType(lprop)=rgGroup) and
       (CompareWide(GetNodeName(lprop),'PROPERTY')) then
    begin
      // Search property with required id
      lnode:=FindChild(lprop,'ID');
      if AsUnsigned(lnode)=aid then
      begin
        aname:=AsString(FindChild(lprop,'NAME'));

        pcw:=AsString(FindChild(lprop,'TYPEOFDATA'));
        result:=TextToType(pcw);
        if result=rgNotValid then
          if IsConsole then writeln('UNKNOWN PROPERTY TYPE ',string(widestring(pcw)));

        exit;
      end;
    end;
  end;
end;

//----- Processed -----

type
  TPropInfo = record
    name   :string;
    name_v2:string;
    id     :dword; // byte
    id_v2  :dword;
    ptype  :integer;
  end;
type
  TObjInfo = record
    name   :string;
    name_v2:string;
    id     :dword;
    id_v2  :dword;
    props  :array of TPropInfo;
  end;
type
  TLayInfo = array of TObjInfo;


initialization

finalization

end.
