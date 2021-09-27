{%TODO add errors for no prop type, no prop/node name}
uses
  rgglobal,
  rgnode;

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
    while (aptr<lend) and not (aptr^ in [#0,#10,#13]) do inc(aptr);
    lsize:=aptr-pc;

    // skip newline
    while (aptr<lend) and (aptr^ in [#10,#13]) do inc(aptr); // inc lline here?
    inc(lline);
    leof:=(aptr>=lend) or (aptr^=#0);
    if lsize=0 then
      continue;

    idx:=0;
    while (idx<lsize) and (pc[idx] in [' ',#9]) do inc(idx);
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
        if CompareWide(GetNodeName(lparents[lparent]),lname)<>0 then
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

function WideToNode(abuf:PByte; asize:cardinal; out anode:pointer):integer;
var
  lpc:PWideChar;
begin
  if (PDWord   (abuf)^=$005BFEFF) or // SIGN_UNICODE+'[' widechar
     (PWideChar(abuf)^='[') then
  begin
    lpc:=PWideChar(abuf);
    if ORD(lpc^)=$FEFF then inc(lpc);
    if asize=0 then asize:=MemSize(abuf);
  
    result:=ParseBlock(lpc,asize,anode);
  end
  else
    result:=-1;
end;

function UTF8ToNode(abuf:PByte; asize:cardinal; out anode:pointer):integer;
var
//  ls :WideString;
//  las:AnsiString;
  lpc:PAnsiChar;
  lptr:PUnicodeChar;
  i:integer;
begin
  if (PDWord   (abuf)^=$5BBFBBEF) or // UTF8 sign and '['
     (PAnsiChar(abuf)^='[') then
  begin
    if asize=0 then asize:=MemSize(abuf);

    lpc:=PAnsiChar(abuf);
    if lpc^<>'[' then
    begin
      inc(lpc  ,3);
      dec(asize,3);
    end;
{#1
    if lpc[asize-1]<>#0 then
    begin
      SetString(las,lpc,asize);
      s:=UTF8Decode(las);
    end
    else
      s:=UTF8ToString(lpc);
}
    GetMem(lptr,(asize+1)*SizeOf(WideChar));
    i:=Utf8ToUnicode(lptr,asize+1, lpc,asize);
//    if i>0 then ReallocMem(lptr,i*SizeOf(WideChar));
    lptr[i-1]:=#0;
    result:=ParseBlock(lptr,i*SizeOf(WideChar),anode);
    FreeMem(lptr);
{#2
    SetLength(ls,asize);
    i:=Utf8ToUnicode(PUnicodeChar(ls),length(ls)+1, lpc,asize);
    if i>0 then
      SetLength(ls,i-1);
    result:=ParseBlock(PWideChar(ls),i*SizeOf(WideChar),anode);
}
  end
  else
    result:=-1;
end;

{$PUSH}
{$I-}
function ParseDatFile(fname:PChar):pointer;
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
      lerror:=WideToNode(buf,i,result);
      if lerror<0 then
        lerror:=UTF8ToNode(buf,i,result);
    finally
      FreeMem(buf);
    end;
  end
  else
    lerror:=errCantOpen;
end;
{$POP}

var
  p:pointer;
begin
  p:=ParseDatFile(PChar(ParamStr(1)));
  WriteDatTree(p,'out.dat');
  DeleteNode(p);
end.
