uses
  rgglobal,
  rgnode;

procedure WriteWide(var buf:PByte; var idx:integer; atext:PWideChar);
const
  TMSGrow = 4096;
Var
  GC,NewIdx:PtrInt;
  lcnt:integer;
begin
  lcnt:=Length(atext)*SizeOf(WideChar);

  If (lcnt=0) or (idx<0) then
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


function DumpNode(var buf:PByte; var idx:integer; anode:pointer; atab:integer):boolean;
var
  larr:array [0..127] of WideChar;
  lvalue:WideString;
  lpc,lname:PWideChar;
  i,j,llen:integer;
  ltype:integer;
begin
  result:=true;

  i:=0;
  while i<atab do
  begin
    larr[i]:=#9;
    inc(i);
  end;

  lname:=GetNodeName(anode);
  llen:=Length(lname);

  ltype:=GetNodeType(anode);
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
      DumpNode(buf,idx,GetChild(anode,i), atab+1);

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
        Str(asFloat(anode):0:4,lvalue);
        j:=Length(lvalue);

        while j>1 do
        begin
          if      (lvalue[j]='0') then dec(j)
          else if (lvalue[j]='.') then
          begin
            dec(j);
            break;
          end
          else break;
        end;
        if j<>Length(lvalue) then SetLength(lvalue,j);
      end;
      rgDouble    : Str(asDouble   (anode):0:6,lvalue);
      rgInteger   : Str(asInteger  (anode),lvalue);
      rgInteger64 : Str(asInteger64(anode),lvalue);
      rgUnsigned  : Str(asUnsigned (anode),lvalue);
      // custom
{ 
      rgVector2   : ;
      rgVector3   : ;
      rgVector4   : ;
}
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
    if (llen>0) or ((lvalue<>'') and (lvalue<>'0')) then
    begin
      larr[i]:=':'; inc(i);
    end;
    larr[i]:=#0;
    WriteWide(buf,idx,larr);

    if lvalue<>'' then
      WriteWide(buf,idx,pointer(lvalue));

    larr[0]:=#13;
    larr[1]:=#10;
    larr[2]:=#0;
    WriteWide(buf,idx,larr);
  end;
end;

function NodeToWide(anode:pointer; out aptr:PWideChar):ByteBool;
var
  lidx:integer;
begin
  result:=false;
  aptr:=nil;
  if anode=nil then exit;

  GetMem(aptr,4096);
  aptr[0]:=WideChar($FEFF);
  lidx:=2;

  result:=DumpNode(PByte(aptr),lidx,anode,0);
  
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

function NodeToUTF8(anode:pointer; out aptr:PAnsiChar):ByteBool;
var
  lwide:PWideChar;
  lsize:integer;
begin
  result:=NodeToWide(anode,lwide);
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

function _WriteDatTree(anode:pointer; fname:PChar):ByteBool;
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

function _WriteDatTree8(anode:pointer; fname:PChar):ByteBool;
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

var
  p:pointer;

begin
  p:=ParseDatFile(PChar(ParamStr(1)));
  _WriteDatTree8(p,'out.dat');
  DeleteNode(p);
end.
