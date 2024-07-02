{TODO: Alternative DumpNode for Vectors as "value, value, value"}
{TODO: change WriteWide to Logging?}
unit RGIO.Text;

interface

// "achild" is for show or not "CHILDREN" groups
function NodeToWide       (anode:pointer; out aptr:PWideChar; achild:boolean=true):ByteBool;
function NodeToUTF8       (anode:pointer; out aptr:PAnsiChar; achild:boolean=true):ByteBool;
function BuildTextFile    (anode:pointer; fname:PChar):ByteBool;
function BuildUTF8TextFile(anode:pointer; fname:PChar):ByteBool;

function DumpNode(var buf:PByte; var idx:cardinal; anode:pointer;
    atab:integer; achild:boolean=true):boolean;

const
  errCantOpen      =  1; // Can't open file for parsing
  errTagNoClose    =  2; // Group tag have no closing parenties
  errTagCloseWrong =  3; // Closing tag have wrong name
  errNoRoot        =  4; // Unconditional. Properties without open Group (root) tag
  errPropNoClose   =  5; // Property have no closing parenties for type
  errRootNoClose   =  6; // End of file, Root group have no closing tag
  errCloseNoRoot   =  7; // Unconditional. Closing tag without any opened (no root)
  errUnknownTag    =  8; // Unknown property type
  errNoPropDelim   =  9; // No ':' sign after prop name
  errNotTextData   = 10; // File is not in proper text format

function WideToNode(abuf:PWideChar; asize:cardinal; out anode:pointer):integer;
function UTF8ToNode(abuf:PAnsiChar; asize:cardinal; out anode:pointer):integer;
function ParseTextMem (abuf :PByte):pointer;
function ParseTextFile(fname:PChar):pointer;
function GetTextErrorDescription(aerror:integer):string;


implementation

uses
  rgglobal,
  rgnode;

resourcestring
  strCantOpen      = 'Can''t open file for parsing';
  strTagNoClose    = 'Group tag have no closing parenties';
  strTagCloseWrong = 'Closing tag have wrong name';
  strNoRoot        = 'Unconditional. Properties without open Group (root) tag';
  strPropNoClose   = 'Property have no closing parenties for type';
  strRootNoClose   = 'End of file, Root group have no closing tag';
  strCloseNoRoot   = 'Unconditional. Closing tag without any opened (no root)';
  strUnknownTag    = 'Unknown property type';
  strNoPropDelim   = 'No ":" sign after prop name';
  strNotTextData   = 'Data is not in proper text format';

const
  ErrorCodes: array [1..10] of string = (
    strCantOpen,
    strTagNoClose,
    strTagCloseWrong,
    strNoRoot,
    strPropNoClose, 
    strRootNoClose, 
    strCloseNoRoot,
    strUnknownTag,
    strNoPropDelim,
    strNotTextData
  );

// Options
const
  WriteEmpty:boolean = true;

{%REGION Node to Text}

procedure WriteWide(var buf:PByte; var idx:cardinal; atext:PWideChar);
const
  TMSGrow = 4096;
Var
  GC,NewIdx:PtrInt;
  lcnt:integer;
begin
  lcnt:=Length(atext)*SizeOf(WideChar);

  If lcnt=0 then
    exit;

  NewIdx:=idx+lcnt;
  GC:=MemSize(buf);
  If NewIdx>=GC then
  begin
    GC:=GC+(GC div 4);
    GC:=(GC+(TMSGrow-1)) and not (TMSGrow-1);

    ReallocMem(buf,GC);
  end;
  System.Move(atext^,buf[idx],lcnt);
  idx:=NewIdx;
end;


function DumpNode(var buf:PByte; var idx:cardinal; anode:pointer;
     atab:integer; achild:boolean=true):boolean;
var
  larr :array [0..127] of WideChar;
  lcrlf:array [0..3] of WideChar;
  lvalue:UnicodeString;
  lpc,lname:PWideChar;
  lfloat:Single;
  i,j,llen:integer;
  ltype:integer;

  procedure DumpVector(aletter:WideChar; avalue:Single);
  var
    lvalue:UnicodeString;
  begin
    larr[i]:=aletter;
    WriteWide(buf,idx,larr);
    if ABS(avalue)<1.0E-6 then Str(avalue:0:DoublePrec,lvalue) else Str(avalue:0:FloatPrec,lvalue);
    FixFloatStr(lvalue);
    WriteWide(buf,idx,pointer(lvalue));
    WriteWide(buf,idx,lcrlf);
  end;

begin
  result:=true;

  ltype:=GetNodeType(anode);
  lname:=GetNodeName(anode);
  if (not achild) and (ltype=rgGroup) and (CompareWide(lname,'CHILDREN')=0) then exit;

  lcrlf[0]:=#13;
  lcrlf[1]:=#10;
  lcrlf[2]:=#0;

  llen:=Length(lname);

  i:=0;
  while i<atab do
  begin
    larr[i]:=#9;
    inc(i);
  end;

  if ltype=rgGroup then
  begin
    // opening tag
    larr[i]:='['; inc(i);
    for j:=0 to llen-1 do
    begin
      larr[i]:=lname[j];
      inc(i);
    end;
    larr[i]:=']'; inc(i);
    larr[i]:=#13; inc(i);
    larr[i]:=#10; inc(i);
    larr[i]:=#0;
    WriteWide(buf,idx,@larr);

    // children
    for i:=0 to GetChildCount(anode)-1 do
      DumpNode(buf,idx,GetChild(anode,i), atab+1, achild);

    // closing tag
    i:=atab;
    larr[i]:='['; inc(i);
    larr[i]:='/'; inc(i);
    for j:=0 to llen-1 do
    begin
      larr[i]:=lname[j];
      inc(i);
    end;
    larr[i]:=']'; inc(i);
    larr[i]:=#13; inc(i);
    larr[i]:=#10; inc(i);
    larr[i]:=#0;
    WriteWide(buf,idx,@larr);
  end
  else
  begin
    if ltype in [rgVector2, rgVector3, rgVector4] then
    begin
      larr[i]:='<'; inc(i);
      larr[i]:='F'; inc(i);
      larr[i]:='L'; inc(i);
      larr[i]:='O'; inc(i);
      larr[i]:='A'; inc(i);
      larr[i]:='T'; inc(i);
      larr[i]:='>'; inc(i);

      // property name
      for j:=0 to llen-1 do
      begin
        larr[i]:=lname[j];
        inc(i);
      end;
      larr[i+1]:=':';
      larr[i+2]:=#0;

      DumpVector('X',asVector(anode)^.X);
      DumpVector('Y',asVector(anode)^.Y);
      if ltype in [rgVector3, rgVector4] then
      begin
        DumpVector('Z',asVector(anode)^.Z);
        if ltype=rgVector4 then
        begin
          DumpVector('W',asVector(anode)^.W);
        end;
      end;
    end
    else
    begin
      // property type
      larr[i]:='<'; inc(i);
      //!!
      if ltype=rgUnknown then
        lpc:=GetCustomType(anode)
      else
        lpc:=TypeToText(ltype);

      if lpc<>nil then
        while lpc^<>#0 do
        begin
          larr[i]:=lpc^;
          inc(i);
          inc(lpc);
        end;
      larr[i]:='>'; inc(i);

      // property name
      for j:=0 to llen-1 do
      begin
        larr[i]:=lname[j];
        inc(i);
      end;

      // construct value in ls
      case ltype of
        rgBool      : if asBool(anode) then lvalue:='true' else lvalue:='false';
        rgString    : lvalue:=asString   (anode);
        rgTranslate : lvalue:=asTranslate(anode);
        rgNote      : lvalue:=asNote     (anode);
        rgUnknown   : lvalue:=asString   (anode);
        rgFloat     : begin
          lfloat:=asFloat(anode);
try
          if ABS(lfloat)<1.0E-6 then
            Str(lfloat:0:DoublePrec,lvalue)
          else
            Str(lfloat:0:FloatPrec,lvalue);
except
  RGLog.AddWide(lname);
  RGLog.Add('problem with float conversion');
end;
          FixFloatStr(lvalue);
        end;
        rgDouble    : begin
          Str(asDouble(anode):0:DoublePrec,lvalue);
          FixFloatStr(lvalue);
        end;
        rgInteger   : Str(asInteger  (anode),lvalue);
        rgInteger64 : Str(asInteger64(anode),lvalue);
        rgUnsigned  : Str(asUnsigned (anode),lvalue);
  {
        // user
        rgWord      : Str(anode^.asWord     ,lvalue);
        rgByte      : Str(anode^.asByte     ,lvalue);
        rgBinary    : Str(anode^.len        ,lvalue);
  }
      else
        lvalue:='';
      end;

      // prop name or value is not empty
      if (llen>0) or ((lvalue<>'') and (lvalue<>'0')) or WriteEmpty then
      begin
        larr[i]:=':'; inc(i);
      end;
      larr[i]:=#0;
      WriteWide(buf,idx,larr);

      if (lvalue<>'') or WriteEmpty then
        WriteWide(buf,idx,pointer(lvalue));

      WriteWide(buf,idx,lcrlf);
    end;

  end;
end;

function NodeToWide(anode:pointer; out aptr:PWideChar; achild:boolean=true):ByteBool;
var
  lidx:cardinal;
begin
  result:=false;
  aptr:=nil;
  if anode=nil then exit;

  GetMem(aptr,4096);
  aptr[0]:=WideChar(SIGN_UNICODE);
  lidx:=2;

  result:=DumpNode(PByte(aptr),lidx,anode,0,achild);
  
  if not result then
  begin
    FreeMem(aptr);
    aptr:=nil;
  end
  else
  begin
    if (lidx+SizeOf(WideChar))>=MemSize(aptr) then
      ReallocMem(aptr,lidx+SizeOf(WideChar));
    aptr[lidx div SizeOf(WideChar)]:=#0;
  end;
end;

function NodeToUTF8(anode:pointer; out aptr:PAnsiChar; achild:boolean=true):ByteBool;
var
  lwide:PWideChar;
  lsize:integer;
begin
  result:=NodeToWide(anode,lwide, achild);
  if result then  
  begin
    lsize:=Length(lwide);
    GetMem(aptr,lsize*3+1);
    lsize:=UnicodeToUtf8(aptr,lsize*3+1,lwide,lsize);
    if lsize>0 then
      ReallocMem(aptr,lsize);
    FreeMem(lwide);
  end;
end;

function BuildTextFile(anode:pointer; fname:PChar):ByteBool;
var
  f:file of byte;
  lpc:PWideChar;
begin
  result:=NodeToWide(anode,lpc);

  if result then
  begin
{$PUSH}
{$I-}
    AssignFile(f, fname);
    Rewrite(f);
    BlockWrite(f,lpc^,Length(lpc)*SizeOf(WideChar));
    CloseFile(f);
{$POP}
    FreeMem(lpc);
  end;

end;

function BuildUTF8TextFile(anode:pointer; fname:PChar):ByteBool;
var
  f:file of byte;
  lpc:PAnsiChar;
begin
  result:=NodeToUTF8(anode,lpc);

  if result then
  begin
{$PUSH}
{$I-}
    AssignFile(f, fname);
    Rewrite(f);
    BlockWrite(f,lpc^,Length(lpc));
    CloseFile(f);
{$POP}
    FreeMem(lpc);
  end;

end;

{%ENDREGION}

{%REGION Text to Node}

function ParseBlock(aptr:PWideChar; asize:cardinal; out anode:pointer):integer;
var
  lparents:array [0..63] of pointer;
  lend,pc:PWideChar;
  lparent,lsize,lline,ltype,ldst,idx:integer;
  lname:array [0..127] of WideChar;
  leof,lclose:boolean;
begin
  anode:=nil;

  lend:=PWideChar(PByte(aptr)+asize);
  lline:=0;
  lparent:=0;
  lparents[0]:=nil;
  result:=0;

  repeat
    // get line to buffer
    pc:=aptr;
    while (aptr<lend) and not (ord(aptr^) in [0,10,13]) do inc(aptr);
    lsize:=aptr-pc;

    // skip newline
    while (aptr<lend) and (ord(aptr^) in [10,13]) do inc(aptr); // inc lline here?
    inc(lline);
    leof:=(aptr>=lend) or (aptr^=#0);
    if lsize=0 then
      continue;

    idx:=0;
    while (idx<lsize) and ((pc[idx]=' ') or (pc[idx]=#9)) do inc(idx);
    if idx=lsize then continue;

    //--- group
    if pc[idx]='[' then
    begin
      inc(idx);
      if (idx<lsize) and (pc[idx]='/') then
      begin
        if lparent=0 then
        begin
          result:=errCloseNoRoot;
          break;
        end;

        inc(idx);
        lclose:=true;
      end
      else
        lclose:=false;

      // get node name
      ldst:=0;
      while (idx<lsize) and (pc[idx]<>']') do
      begin
        lname[ldst]:=pc[idx];
        inc(ldst);
        inc(idx);
      end;
      lname[ldst]:=#0;
      if idx=lsize then
      begin
        result:=errTagNoClose;
        break;
      end;

      if lclose then
      begin
        if not IsNodeName(lparents[lparent],lname) then
        begin
          result:=errTagCloseWrong;
          break;
        end;
        dec(lparent);
        if lparent=0 then break;
      end
      else
      begin
        lparents[lparent+1]:=AddGroup(lparents[lparent],lname);
        inc(lparent);
      end;
    end

    //--- property
    else if pc[idx]='<' then
    begin
      // must not happens really 
      if lparent=0 then
      begin
        result:=errNoRoot;
        break;
      end;

      // type
      inc(idx);
      ldst:=0;
      while (idx<lsize) and (pc[idx]<>'>') do
      begin
        lname[ldst]:=pc[idx];
        inc(ldst);
        inc(idx);
      end;
      lname[ldst]:=#0;

      if idx=lsize then
      begin
        result:=errPropNoClose;
        break;
      end;

      ltype:=TextToType(lname);
      if ltype=rgUnknown then
      begin
        result:=errUnknownTag;
        break;
      end;

      // name
      inc(idx);
      ldst:=0;
      while (idx<lsize) and (pc[idx]<>':') do
      begin
        lname[ldst]:=pc[idx];
        inc(ldst);
        inc(idx);
      end;
      lname[ldst]:=#0;

      if idx=lsize then
      begin
        result:=errNoPropDelim;
        break;
      end;

      inc(idx);
      if (idx<lsize) then
        pc:=pc+idx
      else
        pc:=nil;
      AddNode(lparents[lparent],lname,ltype,pc,lsize-idx{pointer(Copy(pc,idx+1,lsize-idx))});
    end;
  until leof;

  if (result=0) and (lparent>0) then
    result:=errRootNoClose;

  if result<>0 then
  begin
    result:=(lline shl 8)+result;
    if lparent>0 then
      DeleteNode(lparents[1]);
  end
  else
    anode:=lparents[1];
end;

function WideToNode(abuf:PWideChar; asize:cardinal; out anode:pointer):integer;
begin
  result:=errNotTextData;
  anode:=nil;
  if {(asize<2) or} (abuf=nil) or (abuf^=#0) then exit;

  if (PDWord(abuf)^=(SIGN_UNICODE+ORD('[') shl 16)) or
//  if ((ORD(abuf[0])=SIGN_UNICODE) and (abuf[1]='[')) or
     (abuf^='[') then
  begin
    if asize=0 then asize:=(Length(abuf)+1)*SizeOf(WideChar);
    if ORD(abuf^)=SIGN_UNICODE then inc(abuf);
  
    result:=ParseBlock(abuf,asize,anode);
  end;
end;

function UTF8ToNode(abuf:PAnsiChar; asize:cardinal; out anode:pointer):integer;
var
  lptr:PUnicodeChar;
  i:integer;
begin
  result:=errNotTextData;
  anode:=nil;

  if (abuf=nil) or (abuf^=#0) then exit;

  if (PDWord(abuf)^=(SIGN_UTF8+ORD('[') shl 24)) or
     ((abuf^='[') and (abuf[1]<>#0)) then
  begin
    if asize=0 then asize:=Length(abuf)+1;

    if abuf^<>'[' then
    begin
      inc(abuf ,3);
      dec(asize,3);
    end;

    if asize>0 then
    begin
      GetMem(lptr,(asize+1)*SizeOf(WideChar));
      i:=Utf8ToUnicode(lptr,asize+1, abuf,asize);
  //    if i>0 then ReallocMem(lptr,i*SizeOf(WideChar));
      lptr[i-1]:=#0;
      result:=ParseBlock(lptr,i*SizeOf(WideChar),anode);
      FreeMem(lptr);
    end;
  end;
end;

function ParseTextMem(abuf:PByte):pointer;
var
  lerror:integer;
begin
  result:=nil;

  try
    lerror:=WideToNode(PWideChar(abuf),0,result);
    if lerror<0 then
      lerror:=UTF8ToNode(PAnsiChar(abuf),0,result);
  except
    lerror:=errCantOpen;
  end;

  if (lerror<>0) and (lerror<>errNotTextData) then
    RGLog.Add('Memory block', dword(lerror) shr 8, 'error: '+ErrorCodes[dword(lerror) and $FF]);
end;

{$PUSH}
{$I-}
function ParseTextFile(fname:PChar):pointer;
var
  f:file of byte;
  buf:PByte;//PWideChar;
  i,lerror:integer;
begin
  result:=nil;

  AssignFile(f,fname);
  Reset(f);
  if IOResult=0 then
  begin
    i:=FileSize(f);
    GetMem(buf,i{+SizeOf(WideChar)});
    BlockRead(f,buf^,i);
    CloseFile(f);
  //  buf[i div SizeOf(WideChar)]:=#0;

    try
      lerror:=WideToNode(PWideChar(buf),i,result);
      if lerror<0 then
        lerror:=UTF8ToNode(PAnsiChar(buf),i,result);
    finally
      FreeMem(buf);
    end;
  end
  else
    lerror:=errCantOpen;

  if lerror<>0 then
    RGLog.Add(fname, lerror shr 8, 'error: '+ErrorCodes[lerror and $FF]);
end;
{$POP}

function GetTextErrorDescription(aerror:integer):string;
begin
  Str(aerror shr 8,result);
  if (aerror and $FF) in [1..9] then
  begin
    result:='Error: '+ErrorCodes[aerror and $FF]+' in line '+result;
  end
  else
    result:='Unknown error in line '+result;
end;

{%ENDREGION}

end.
