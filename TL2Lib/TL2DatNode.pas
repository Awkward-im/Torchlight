{
  All text from nodes must not be changed manually. If you want to change property text, you need to use
  corresponding function. other values can be changed freely.
  Text file MUST have root node.
   
}
{$CALLING cdecl}

unit TL2DatNode;

interface

const
  ntGroup     = 0;
  ntInteger   = 1;
  ntString    = 2;
  ntFloat     = 3;
  ntBool      = 4;
  ntTranslate = 5;
  ntInteger64 = 6;
  ntUnsigned  = 7;
  // custom
  ntNote      = 8;
  ntDouble    = 9;
  // user
  ntWord      = 10;
  ntByte      = 11;
  ntVector    = $FC;
  ntBinary    = $FD;
  ntDeleted   = $FE;
  ntUnknown   = $FF;

type
  PATL2Node = ^TATL2Node;
  PTL2Node = ^TTL2Node;
  TTL2Node = record
    name  : PWideChar;
    parent: PTL2Node;
    case nodetype:byte of
      ntGroup    : (
        children  :PATL2Node;
        childcount:Int32;
      );
      ntString,
      ntTranslate,
      ntNote,
      ntUnknown  : (
        asString  :PWideChar;
        CustomType:PWideChar;  // for ntUnknown only
      );
      ntBool     : (asBoolean  :ByteBool);
      ntInteger  : (asInteger  :Int32);
      ntUnsigned : (asUnsigned :UInt32);
      ntInteger64: (asInteger64:Int64);
      ntFloat    : (asFloat    :Single);
      ntDouble   : (asDouble   :Double);
      ntWord     : (asWord     :Word);
      ntByte     : (asByte     :Byte);
      ntBinary   : (len        :UInt32);
  end;
  TATL2Node = array [0..16383] of TTL2Node;

function ParseDatFile(fname:PChar):PTL2Node; export;

function WriteDatTree(anode:PTL2Node; fname:PChar):ByteBool; export;

procedure DeleteNode(var anode:PTL2Node); export;
function ExtractNode(src:PTL2Node):PTL2Node; export;

const
  actSkip      = 0;
  actOverwrite = 1;
  actAppend    = 2;
// both nodes MUST BE a group
// groups will append always
function JoinNode(dst:PTL2Node; var anode:PTL2Node; action:Int32):ByteBool; export;

function FindNode  (anode:PTL2Node; apath:PWideChar):PTL2Node; export;
function CloneNode (anode:PTL2Node):PTL2Node; export;
function ChangeNode(anode:PTL2Node; aval:PWideChar):ByteBool; export;

function  Defrag  (anode:PTL2Node):Int32; export;
procedure Compact (anode:PTL2Node); export;
function  ExpandBy(anode:PTL2Node; amount:Int32):ByteBool; export;

function MakeNewNode(aparent:PTL2Node; aname:PWideChar; atype:byte; atext:PWideChar):PTL2Node; export;

procedure AddNode     (dst:PTL2Node; anode:PTL2Node); export;
function  AddGroup    (dst:PTL2Node; aname:PWideChar):PTL2Node; export;
function  AddBool     (dst:PTL2Node; aname:PWideChar; aval:ByteBool):PTL2Node; export;
function  AddInteger  (dst:PTL2Node; aname:PWideChar; aval:Int32   ):PTL2Node; export;
function  AddFloat    (dst:PTL2Node; aname:PWideChar; aval:single  ):PTL2Node; export;
function  AddInteger64(dst:PTL2Node; aname:PWideChar; aval:Int64   ):PTL2Node; export;
function  AddUnsigned (dst:PTL2Node; aname:PWideChar; aval:UInt32  ):PTL2Node; export;
function  AddText     (dst:PTL2Node; aname:PWideChar; aval:PWideChar; atype:byte):PTL2Node; export;
// custom
function  AddDouble   (dst:PTL2Node; aname:PWideChar; aval:double  ):PTL2Node; export;
// user
function  AddBinary   (dst:PTL2Node; aname:PWideChar; aval:UInt32  ):PTL2Node; export;
function  AddByte     (dst:PTL2Node; aname:PWideChar; aval:byte    ):PTL2Node; export;
function  AddWord     (dst:PTL2Node; aname:PWideChar; aval:word    ):PTL2Node; export;
function  AddCustom   (dst:PTL2Node; aname:PWideChar; aval:PWideChar; atype:PWideChar):PTL2Node; export;


implementation

const
  SIGN_UNICODE = $FEFF;

const
  PropTypes: array [0..11] of record
    name:PWideChar;
    code:integer;
  end = (
    (name: 'INTEGER'     ; code: ntInteger),
    (name: 'STRING'      ; code: ntString),
    (name: 'FLOAT'       ; code: ntFloat),
    (name: 'BOOL'        ; code: ntBool),
    (name: 'TRANSLATE'   ; code: ntTranslate),
    (name: 'INTEGER64'   ; code: ntInteger64),
    (name: 'UNSIGNED INT'; code: ntUnsigned),
    // custom
    (name: 'NOTE'        ; code: ntNote),
    (name: 'DOUBLE'      ; code: ntDouble),
    // user
    (name: 'WORD'        ; code: ntWord),
    (name: 'BYTE'        ; code: ntByte),
    (name: 'BINARY'      ; code: ntBinary)
  );

//===== Error handler =====

const
  errCantOpen      = 1; // (Error) Can't open file for parsing
  errTagNoClose    = 2; // (Error) Group tag have no closing parenties
  errTagCloseWrong = 3; // (Error) Closing tag have wrong name
  errNoRoot        = 4; // (Error) Unconditional. Properties without open Group (root) tag
  errPropNoClose   = 5; // (Error) Property have no closing parenties
  errRootNoClose   = 6; // (Error) End of file, Root group have no closing tag
  errCloseNoRoot   = 7; // (Error) Unconditional. Closing tag without any opened (no root)
  errUnknownTag    = 8; // (Warning) Unknown property type

type
  TErrorHandler = function(acode:integer; aFile:PChar; aLine:integer):integer; cdecl;

var
  OnError:TErrorHandler = nil;

function SetDatErrorHandler(aproc:TErrorHandler):TErrorHandler;
begin
  result :=OnError;
  OnError:=aproc;
end;

//===== Support =====

function beforedecimaldb(aval:double):integer; public;
begin
  aval:=abs(aval);
  result:=5;
  while aval>=1 do
  begin
    inc(result);
    aval:=aval/10;
  end;
end;

function CopyWide(asrc:PWideChar):PWideChar;
var
  llen:integer;
begin
  if (asrc=nil) or (asrc^=#0) then exit(nil);
  llen:=Length(asrc);
  GetMem(result,(llen+1)*SizeOf(WideChar));
  move(asrc^,result^,llen*SizeOf(WideChar));
  result[llen]:=#0;
end;

function CompareWide(s1,s2:PWideChar):boolean;
begin
  if s1=s2 then exit(true);
  if ((s1=nil) and (s2^=#0)) or
     ((s2=nil) and (s1^=#0)) then exit(true);
  repeat
    if s1^<>s2^ then exit(false);
    if s1^=#0 then exit(true);
    inc(s1);
    inc(s2);
  until false;
end;

type
  TBytes = array of byte;

procedure WriteWide(var buf:TBytes; var idx:integer; atext:PWideChar);
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
  GC:=Length(buf);
  If NewIdx>GC then
  begin
    GC:=GC+(GC div 4);
    GC:=(GC+(TMSGrow-1)) and not (TMSGrow-1);

    SetLength(buf,GC);
  end;
  System.Move(atext^,buf[idx],lcnt);
  idx:=NewIdx;
end;

function GetPropertyType(atype:PWideChar):integer; overload;
var
  i:integer;
begin
  for i:=0 to High(PropTypes) do
    if CompareWide(PropTypes[i].name,atype) then
      exit(PropTypes[i].code);

  result:=ntUnknown;
end;

function GetPropertyType(atype:integer):PWideChar; overload;
var
  i:integer;
begin
  for i:=0 to High(PropTypes) do
    if PropTypes[i].code=atype then
      exit(PropTypes[i].name);

  result:=nil;
end;

//===== Nodes =====

function Defrag(anode:PTL2Node):Int32;
var
  i,j:integer;
begin
  if (anode=nil) or (anode^.nodetype<>ntGroup) then exit(0);

  j:=anode^.childcount;
  i:=0;
  while i<anode^.childcount do
  begin
    if anode^.children^[i].nodetype=ntDeleted then
    begin
      while j>i do
      begin
        dec(j);
        if anode^.children^[j].nodetype<>ntDeleted then
        begin
          move(anode^.children^[j],anode^.children^[i],SizeOf(TTL2Node));
          anode^.children^[j].nodetype:=ntDeleted;
          break;
        end;
      end;
    end;
    if i>=j then break;
    inc(i);
  end;
  result:=i;
end;

procedure Compact(anode:PTL2Node);
var
  i:integer;
begin
  i:=Defrag(anode);
  if (anode<>nil) and (anode^.nodetype=ntGroup) then
  begin
    while (i<anode^.childcount) and (anode^.children^[i].nodetype<>ntDeleted) do inc(i);
    if i<anode^.childcount then
      ReallocMem(anode^.children,i*SizeOf(TTL2Node));
  end;
end;

function ExpandBy(anode:PTL2Node; amount:Int32):ByteBool;
var
  i:integer;
begin
  if (amount<=0) or (anode=nil) then
    exit(true);
  if (anode^.nodetype<>ntGroup) then
    exit(false);

  result:=true;
  i:=Defrag(anode);
  while (i<anode^.childcount) and (anode^.children^[i].nodetype<>ntDeleted) do inc(i);
  dec(amount,anode^.childcount-i);
  if amount>0 then
  begin
    inc(anode^.childcount,amount);
    ReallocMem(anode^.children,anode^.childcount*SizeOf(TTL2Node));
    while i<anode^.childcount do
    begin
      anode^.children^[i].nodetype:=ntDeleted;
      inc(i);
    end;
  end;
end;

function AllocateNode(dst:PTL2Node):PTL2Node;
var
  lidx:integer;
begin
  result:=nil;

  if (dst=nil) or (dst^.nodetype<>ntGroup) then exit;

  with dst^ do
  begin
    for lidx:=0 to integer(childcount)-1 do
    begin
      if children^[lidx].nodetype=ntDeleted then
      begin
        result:=@children^[lidx];
        break;
      end;
    end;

    if result=nil then
    begin
      ReallocMem(children,(childcount+1)*SizeOf(TTL2Node));
      result:=@children^[childcount];
      inc(childcount);
    end;
  end;
  result^.parent:=dst;
end;

function ChangeNode(anode:PTL2Node; aval:PWideChar):ByteBool;
begin
  result:=true;

  if anode<>nil then
    case anode^.nodetype of
      ntInteger  : Val(aval,anode^.asInteger);
      ntFloat    : Val(aval,anode^.asFloat);
      ntInteger64: Val(aval,anode^.asInteger64);
      ntUnsigned : Val(aval,anode^.asUnsigned);
      ntString,
      ntTranslate,
      ntUnknown,
      ntNote     : begin
        if anode^.asString<>nil then FreeMem(anode^.asString);
        anode^.asString:=CopyWide(aval);
      end;
      ntBool     : begin
       if (aval<>nil) and (
          ((aval[0]='1') and (aval[1]=#0)) or
          ((aval[0] in ['t','T']) and
           (aval[1] in ['r','R']) and
           (aval[2] in ['u','U']) and
           (aval[3] in ['e','E']) and
           (aval[4]=#0))
          ) then anode^.asBoolean:=true;
      end;
      // custom
      ntDouble   : Val(aval,anode^.asDouble);
      // user
      ntByte     : Val(aval,anode^.asByte);
      ntWord     : Val(aval,anode^.asWord);
      ntBinary   : Val(aval,anode^.len);
    else
      result:=false;
    end;
end;

function MakeNewNode(aparent:PTL2Node; aname:PWideChar; atype:byte; atext:PWideChar):PTL2Node;
begin
  if aparent<>nil then
  begin
    result:=AllocateNode(aparent);
    if result=nil then exit;
  end
  else
    GetMem(result,SizeOf(TTL2Node));

  FillChar(result^,SizeOf(TTL2Node),#0);
  result^.name    :=CopyWide(aname);
  result^.parent  :=aparent;
  result^.nodetype:=atype;
  if atype<>ntGroup then
    ChangeNode(result,atext);
end;

procedure DeleteNode(var anode:PTL2Node);
var
  lnode:PTL2Node;
  i:integer;
begin
  if (anode<>nil) and (anode^.nodetype<>ntDeleted) then
  begin
    if anode^.name<>nil then FreeMem(anode^.name);
    case anode^.nodetype of
      ntGroup: begin
        for i:=0 to anode^.childcount-1 do
        begin
          lnode:=@anode^.children^[i];
          DeleteNode(lnode);
        end;
        FreeMem(anode^.children);
      end;

      ntString,
      ntTranslate,
      ntUnknown,
      ntNote     : begin
        if anode^.asString<>nil then FreeMem(anode^.asString);
        if anode^.nodetype=ntUnknown then
          if anode^.CustomType<>nil then FreeMem(anode^.customType);
      end;
    end;

    if anode^.parent=nil then
    begin
      FreeMem(anode);
      anode:=nil;
    end
    else
    begin
      FillChar(anode^,SizeOf(anode^),0);
      anode^.nodetype:=ntDeleted;
    end;
  end;
end;

function ExtractNode(src:PTL2Node):PTL2Node;
begin
  if src=nil then
    result:=nil
  else if src^.parent=nil then
    result:=src
  else
  begin
    GetMem   (result ,SizeOf(TTL2Node));
    move(src^,result^,SizeOf(TTL2Node));
    result^.parent:=nil;
    src^.nodetype:=ntDeleted;
  end;
end;

function ParseDatFile(fname:PChar):PTL2Node;
var
  f:file of byte;
  lutype,buf:PWideChar;
  lnode,lgroup:PTL2Node;
  pc,peoln:PWideChar;
  lline,ltype,ldst,i,idx:integer;
  lname:array [0..127] of WideChar;
  leof,lclose:boolean;
begin
  result:=nil;

  // Load file into buffer

{$PUSH}
{$I-}
  AssignFile(f,fname);
  Reset(f);
  if IOResult<>0 then
  begin
    if Assigned(OnError) then
    begin
      OnError(errCantOpen,fname,0);
    end;
    exit;
  end;

  i:=FileSize(f);
  GetMem(buf,i+SizeOf(WideChar));
  BlockRead(f,buf^,i);
  CloseFile(f);
  buf[i div SizeOf(WideChar)]:=#0;
{$POP}
  peoln:=buf;
  if ORD(peoln^)=SIGN_UNICODE then inc(peoln);

  lgroup:=nil;

  lline:=0;

  try
    repeat
      // Set pc to line start and peoln to line end
      while (peoln^ in [#10,#13]) do inc(peoln); // lline going wrong if several crlf one-by-one
      if peoln^=#0 then break;

      inc(lline);

      pc:=peoln;
      while not (peoln^ in [#0{,#10},#13]) do inc(peoln);
      leof:=peoln^=#0;
      if not leof then
      begin
        peoln^:=#0;
        inc(peoln);
      end;

      idx:=0;
      while (pc[idx] in [' ',#9]) do inc(idx);

      //--- group
      if pc[idx]='[' then
      begin
        inc(idx);
        if pc[idx]='/' then
        begin
          if lgroup=nil then
          begin
            if Assigned(OnError) then OnError(errCloseNoRoot,fname,lline);
            exit;
          end;

          inc(idx);
          lclose:=true;
        end
        else
          lclose:=false;

        ldst:=0;
        while not (pc[idx] in [#0,']']) do
        begin
          lname[ldst]:=pc[idx];
          inc(ldst);
          inc(idx);
        end;
        lname[ldst]:=#0;
        if pc[idx]=#0 then
        begin
          if (not Assigned(OnError)) or (OnError(errTagNoClose,fname,lline)<>0) then
          begin
            DeleteNode(result);
            exit;
          end;
        end;

        if lclose then
        begin
          if not CompareWide(lgroup^.name,lname) then
          begin
            if (not Assigned(OnError)) or (OnError(errTagCloseWrong,fname,lline)<>0) then
            begin
              DeleteNode(result);
              exit;
            end;
          end;

          lgroup:=lgroup^.parent;
          leof:=lgroup=nil;
        end
        else
        begin
          lgroup:=MakeNewNode(lgroup,lname,ntGroup,nil);
          if result=nil then
            result:=lgroup;
        end;
      end
      //--- property
      else if pc[idx]='<' then
      begin
        if lgroup=nil then
        begin
          if Assigned(OnError) then OnError(errNoRoot,fname,lline);
          exit;
        end;

        inc(idx);
        // type
        ldst:=0;
        while not (pc[idx] in [#0,'>']) do
        begin
          lname[ldst]:=pc[idx];
          inc(ldst);
          inc(idx);
        end;
        lname[ldst]:=#0;
        if pc[idx]=#0 then
        begin
          if (not Assigned(OnError)) or (OnError(errPropNoClose,fname,lline)<>0) then
          begin
            DeleteNode(result);
            exit;
          end;
        end;
        inc(idx);
        ltype:=GetPropertyType(lname);
        if ltype=ntUnknown then lutype:=CopyWide(lname);
        
        // name
        ldst:=0;
        while not (pc[idx] in [#0,':']) do
        begin
          lname[ldst]:=pc[idx];
          inc(ldst);
          inc(idx);
        end;
        lname[ldst]:=#0;
        if pc[idx]=':' then
          inc(idx);

        lnode:=MakeNewNode(lgroup,lname,ltype,@pc[idx]);
        if ltype=ntUnknown then
        begin
          lnode^.CustomType:=lutype;
          if Assigned(OnError) then OnError(errUnknownTag,fname,lline);
        end;
      end;
    until leof;
    if lgroup<>nil then
    begin
      if (not Assigned(OnError)) or (OnError(errRootNoClose,fname,lline)<>0) then
      begin
        DeleteNode(result);
        exit;
      end;
    end;

  finally
    FreeMem(buf);
  end;
end;

function DumpNode(var buf:TBytes; var idx:integer; const anode:TTL2Node; atab:integer):boolean;
var
  larr:array [0..127] of WideChar;
  ls:WideString;
  pc:PWideChar;
  i,j,llen:integer;
//  k:integer;
begin
  result:=true;

  if anode.nodetype=ntDeleted then exit;

  i:=0;
  while i<atab do
  begin
    larr[i]:=#9;
    inc(i);
  end;

  llen:=Length(anode.name);

  if anode.nodetype=ntGroup then
  begin
    larr[i]:='['; inc(i);
    for j:=0 to llen-1 do
    begin
      larr[i]:=anode.name[j];
      inc(i);
    end;
    larr[i]:=']'; inc(i);
    larr[i]:=#13; inc(i);
    larr[i]:=#10; inc(i);
    larr[i]:=#0;
    WriteWide(buf,idx,@larr);

    for i:=0 to anode.childcount-1 do
      DumpNode(buf,idx,anode.children^[i], atab+1);

    i:=atab;
    larr[i]:='['; inc(i);
    larr[i]:='/'; inc(i);
    for j:=0 to llen-1 do
    begin
      larr[i]:=anode.name[j];
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
    larr[i]:='<'; inc(i);
    pc:=GetPropertyType(anode.nodetype);
    if anode.nodetype=ntUnknown then // pc=nil
      pc:=anode.CustomType;

    while pc^<>#0 do
    begin
      larr[i]:=pc^;
      inc(i);
      inc(pc);
    end;
    larr[i]:='>'; inc(i);

    for j:=0 to llen-1 do
    begin
      larr[i]:=anode.name[j];
      inc(i);
    end;

    case anode.nodetype of
      ntBool      : if anode.asBoolean then ls:='true' else ls:='false';
      ntString,
      ntTranslate,
      ntNote,
      ntUnknown   : ls:=anode.asString;
      ntInteger   : Str(anode.asInteger  ,ls);
      ntFloat     : begin
        Str(anode.asFloat:0:4,ls);
        j:=Length(ls);
{
        k:=1;
        while k<=j do
          if ls[k]<>'.' then inc(k)
          else break;
        if k>j then k:=2;
        while j>=k do
        begin
          if (ls[j]='0') or (ls[j]='.') then dec(j)
          else break;
        end;
}
        while j>1 do
        begin
          if      (ls[j]='0') then dec(j)
          else if (ls[j]='.') then
          begin
            dec(j);
            break;
          end
          else break;
        end;
        if j<>Length(ls) then SetLength(ls,j);
      end;
      ntInteger64 : Str(anode.asInteger64,ls);
      ntUnsigned  : Str(anode.asUnsigned ,ls);
      // custom
      ntDouble    : Str(anode.asDouble:0:4,ls);
      // user
      ntWord      : Str(anode.asWord     ,ls);
      ntByte      : Str(anode.asByte     ,ls);
      ntBinary    : Str(anode.len        ,ls);
    end;

    if (llen>0) or ((ls<>'') and (ls<>'0')) then
    begin
      larr[i]:=':'; inc(i);
    end;
    larr[i]:=#0;
    WriteWide(buf,idx,larr);

    if ls<>'' then
      WriteWide(buf,idx,pointer(ls));

    larr[0]:=#13;
    larr[1]:=#10;
    larr[2]:=#0;
    WriteWide(buf,idx,larr);
  end;
end;

function WriteDatTree(anode:PTL2Node; fname:PChar):ByteBool;
var
  f:file of byte;
  lbuf:TBytes;
  lidx:integer;
begin
  result:=false;
  if anode=nil then exit;

  SetLength(lbuf,2);
  lbuf[0]:=$FF;
  lbuf[1]:=$FE;
  lidx:=2;

  DumpNode(lbuf,lidx,anode^,0);

{$PUSH}
{$I-}
  AssignFile(f, fname);
  Rewrite(f);
  BlockWrite(f,lbuf[0],lidx);
  CloseFile(f);
{$POP}

end;

procedure AddNode(dst:PTL2Node; anode:PTL2Node);
var
  lnode:PTL2Node;
begin
  lnode:=AllocateNode(dst);
  if lnode<>nil then
  begin
    move(anode^,lnode^,SizeOf(TTL2Node));
    if anode^.parent=nil then
      FreeMem(anode)
    else
      anode^.nodetype:=ntDeleted;
  end;
end;

function AddGroup(dst:PTL2Node; aname:PWideChar):PTL2Node;
begin
  result:=MakeNewNode(dst, aname, ntGroup, nil);
end;

function AddCustom(dst:PTL2Node; aname:PWideChar; aval:PWideChar; atype:PWideChar):PTL2Node;
begin
  result:=MakeNewNode(dst, aname, ntUnknown, aval);
  result^.CustomType:=CopyWide(atype);
end;

function AddText(dst:PTL2Node; aname:PWideChar; aval:PWideChar; atype:byte):PTL2Node;
begin
  result:=MakeNewNode(dst, aname, atype, aval);
end;

function AddBinary(dst:PTL2Node; aname:PWideChar; aval:UInt32):PTL2Node;
begin
  result:=MakeNewNode(dst, aname, ntBinary, nil);
  if result<>nil then result^.len:=aval;
end;

function AddBool(dst:PTL2Node; aname:PWideChar; aval:ByteBool):PTL2Node;
begin
  result:=MakeNewNode(dst, aname, ntBool, nil);
  if result<>nil then result^.asBoolean:=aval;
end;

function AddByte(dst:PTL2Node; aname:PWideChar; aval:byte):PTL2Node;
begin
  result:=MakeNewNode(dst, aname, ntByte, nil);
  if result<>nil then result^.asByte:=aval;
end;

function AddWord(dst:PTL2Node; aname:PWideChar; aval:word):PTL2Node;
begin
  result:=MakeNewNode(dst, aname, ntWord, nil);
  if result<>nil then result^.asWord:=aval;
end;

function AddInteger(dst:PTL2Node; aname:PWideChar; aval:Int32):PTL2Node;
begin
  result:=MakeNewNode(dst, aname, ntInteger, nil);
  if result<>nil then result^.asInteger:=aval;
end;

function AddFloat(dst:PTL2Node; aname:PWideChar; aval:single):PTL2Node;
begin
  result:=MakeNewNode(dst, aname, ntFloat, nil);
  if result<>nil then result^.asFloat:=aval;
end;

function AddInteger64(dst:PTL2Node; aname:PWideChar; aval:Int64):PTL2Node;
begin
  result:=MakeNewNode(dst, aname, ntInteger64, nil);
  if result<>nil then result^.asInteger64:=aval;
end;

function AddUnsigned(dst:PTL2Node; aname:PWideChar; aval:UInt32):PTL2Node;
begin
  result:=MakeNewNode(dst, aname, ntUnsigned, nil);
  if result<>nil then result^.asUnsigned:=aval;
end;

function AddDouble(dst:PTL2Node; aname:PWideChar; aval:double):PTL2Node;
begin
  result:=MakeNewNode(dst, aname, ntDouble, nil);
  if result<>nil then result^.asDouble:=aval;
end;

function FindNode(anode:PTL2Node; apath:PWideChar):PTL2Node;
var
  lname:array [0..127] of WideChar;
  lnode,lcnode:PTL2Node;
  p1,p2:PWideChar;
  i:integer;
begin
  result:=nil;
  if (anode=nil) or (anode^.nodetype=ntDeleted) or
     (apath=nil) or (apath^=#0) then exit;

  lnode:=anode;
  p2:=apath;

  while p2^<>#0 do
  begin
    // 1 - get path part
    p1:=@lname[0];
    while not (p2^ in ['\','/',#0]) do
    begin
      p1^:=p2^;
      inc(p1);
      inc(p2);
    end;
    p1^:=#0;
    if lname[0]=#0 then exit;

    // 2 - search this part
    result:=nil;
    for i:=0 to lnode^.childcount-1 do
    begin
      lcnode:=@lnode^.children^[i];
      if lcnode^.nodetype<>ntDeleted then
      begin
        if (p2^=#0) xor (lcnode^.nodetype=ntGroup) then
        begin
          if CompareWide(lcnode^.name,lname) then
          begin
            result:=lcnode;
            break;
          end;
        end
      end;
    end;
    if result=nil then exit;

    // 3 - if not "name" then next cycle
    if p2^<>#0 then
    begin
      inc(p2);
      lnode:=result;
    end;
  end;
end;

procedure CopyNodeInt(asrc, adst:PTL2Node);
var
  i:integer;
begin
  if asrc^.nodetype=ntDeleted then exit;

  adst^.name:=CopyWide(asrc^.name);

  case asrc^.nodetype of
    ntString,
    ntNote,
    ntUnknown,
    ntTranslate: begin
      adst^.asString:=CopyWide(asrc^.asString);
      if asrc^.nodetype=ntUnknown then
        adst^.CustomType:=CopyWide(asrc^.CustomType);
    end;

    ntGroup: if asrc^.childcount>0 then
      begin
        GetMem(adst^.children,asrc^.childcount*SizeOf(TTL2Node));
        move(asrc^.children^,
             adst^.children^,
             asrc^.childcount*SizeOf(TTL2Node));

        for i:=0 to asrc^.childcount-1 do
        begin
          CopyNodeInt(
              @(asrc^.children^[i]),
              @(adst^.children^[i]));
          adst^.children^[i].parent:=adst;
        end;
      end;
  end;
end;

function CloneNode(anode:PTL2Node):PTL2Node;
begin
  if anode=nil then
    exit(nil);

  GetMem(result,SizeOf(TTL2Node));
  move(anode^,result^,SizeOf(TTL2Node));

  CopyNodeInt(anode,result);
  result^.parent:=nil;
end;

// action is: 0 - skip; 1 - overwrite; 2 - append
function JoinNode(dst:PTL2Node; var anode:PTL2Node; action:Int32):ByteBool;
var
  lcnode,lnode:PTL2Node;
  i:integer;
begin
  result:=false;
  if dst=nil then exit;
  if anode=nil then exit(true);
  if (dst^.nodetype<>ntGroup) or (anode^.nodetype<>ntGroup) then exit;

  ExpandBy(dst,anode^.childcount);

  for i:=0 to anode^.childcount-1 do
  begin
    lcnode:=@anode^.children^[i];
    if lcnode^.nodetype<>ntDeleted then
    begin
      if (lcnode^.nodetype=ntGroup) or (action=actAppend) then
        lnode:=nil
      else
        lnode:=FindNode(dst,lcnode^.name);

      if lnode=nil then
      begin
        AddNode(dst,lcnode);
      end
      else if action=actOverwrite then
      begin
        //!! clear+set value can be better to keep order
        // but if no holes before and no autopack,
        // then all will work as we need
        DeleteNode(lnode);
        AddNode(dst,lcnode);
      end;
    end;
  end;
  DeleteNode(anode);
end;


exports

  ParseDatFile,
  WriteDatTree,

  DeleteNode,
  ExtractNode,
  FindNode,
  CloneNode,
  ChangeNode,

  Defrag,
  Compact,
  ExpandBy,

  MakeNewNode,
  AddNode,
  AddGroup,
  AddBool,
  AddInteger,
  AddFloat,
  AddInteger64,
  AddUnsigned,
  AddText,
  // custom
  AddDouble,
  // user
  AddCustom,
  AddBinary,
  AddByte,
  AddWord;

end.
