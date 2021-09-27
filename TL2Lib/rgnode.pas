{%TODO move BOM from MakeDatTree to WriteDatTree}
{%TODO place text to table and store indexes (by option like 'no_changes')}
{%TODO keep hashes in nodes and global dict. But where to keep reference to dict?}
{%TODO make Vector2, Vector3 and Vector 4 values too}
{%TODO use hash (standard, if exists) for tags}
{%TODO As* for get value - add default values}
{%TODO Add blob field for use as Hash for names or ID for layout nodes. but not both?}
{%TODO Add Insert method at least for top (for IDs)}
{%TODO Change Find function for hash, not text name}
unit RGNode;

interface

function  ParseDatFile(fname:PChar):pointer;
function  ParseDat    (buf:PWideChar; aid:PChar=nil):pointer;
function  MakeDatTree (anode:pointer; out aptr:PWideChar):ByteBool;
function  WriteDatTree(anode:pointer; fname:PChar):ByteBool;
procedure DeleteNode  (anode:pointer);

function GetGroupCount(anode:pointer; aname:PWideChar=nil):integer;
function GetChildCount(anode:pointer):integer;
function GetChild     (anode:pointer; idx:integer):pointer;
function GetNodeType  (anode:pointer):integer;
function GetNodeName  (anode:pointer):PWideChar;
function GetCustomType(anode:pointer):PWideChar;

function FindNode     (anode:pointer; apath:PWideChar):pointer;
function SetNodeValue (anode:pointer; aval :PWideChar; alen:integer=0):ByteBool;

//--- Write data ---

function AsBool     (anode:pointer; aval:ByteBool ):ByteBool; 
function AsInteger  (anode:pointer; aval:Int32    ):Int32;    
function AsUnsigned (anode:pointer; aval:UInt32   ):UInt32;   
function AsFloat    (anode:pointer; aval:single   ):single;   
function AsDouble   (anode:pointer; aval:double   ):double;   
function AsInteger64(anode:pointer; aval:Int64    ):Int64;    
function AsString   (anode:pointer; aval:PWideChar):PWideChar;
function AsTranslate(anode:pointer; aval:PWideChar):PWideChar;
function AsNote     (anode:pointer; aval:PWideChar):PWideChar;

//--- Read data ---

function AsBool     (anode:pointer):ByteBool;
function AsInteger  (anode:pointer):Int32;
function AsUnsigned (anode:pointer):UInt32;
function AsFloat    (anode:pointer):single;
function AsDouble   (anode:pointer):double;
function AsInteger64(anode:pointer):Int64;
function AsString   (anode:pointer):PWideChar;
function AsTranslate(anode:pointer):PWideChar;
function AsNote     (anode:pointer):PWideChar;

//--- Add data ---

function AddNode     (aparent:pointer; aname:PWideChar;
                      atype  :integer; atext:PWideChar; alen:integer=0):pointer;
function AddGroup    (aparent:pointer; aname:PWideChar):pointer;
function AddBool     (aparent:pointer; aname:PWideChar; aval:ByteBool ):pointer;
function AddInteger  (aparent:pointer; aname:PWideChar; aval:Int32    ):pointer;
function AddFloat    (aparent:pointer; aname:PWideChar; aval:single   ):pointer;
function AddDouble   (aparent:pointer; aname:PWideChar; aval:double   ):pointer;
function AddInteger64(aparent:pointer; aname:PWideChar; aval:Int64    ):pointer;
function AddUnsigned (aparent:pointer; aname:PWideChar; aval:UInt32   ):pointer;
function AddString   (aparent:pointer; aname:PWideChar; aval:PWideChar):pointer;
function AddTranslate(aparent:pointer; aname:PWideChar; aval:PWideChar):pointer;
function AddNote     (aparent:pointer; aname:PWideChar; aval:PWideChar):pointer;
// user
function AddBinary   (aparent:pointer; aname:PWideChar; aval:UInt32   ):pointer;
function AddByte     (aparent:pointer; aname:PWideChar; aval:byte     ):pointer;
function AddWord     (aparent:pointer; aname:PWideChar; aval:word     ):pointer;
function AddCustom   (aparent:pointer; aname:PWideChar; aval:PWideChar; atype:PWideChar):pointer;


implementation

uses
  rgglobal;

type
  PARGNode = ^TARGNode;
  PRGNode = ^TRGNode;
  TRGNode = record
    name  : PWideChar;
    parent: PRGNode; // really needs just for deleting
    case nodetype:integer of
      rgGroup    : (
        count   :word;
        capacity:word;
        child   :PARGNode;
      );
      rgString,
      rgTranslate,
      rgNote,
      rgUnknown  : (
        asString  :PWideChar;
        CustomType:PWideChar;  // for rgUnknown only
      );
      rgBool     : (asBoolean  :ByteBool);
      rgInteger  : (asInteger  :Int32);
      rgUnsigned : (asUnsigned :UInt32);
      rgInteger64: (asInteger64:Int64);
      rgFloat    : (asFloat    :Single);
      rgDouble   : (asDouble   :Double);
      // custom
{
      rgVector2,
      rgVector3,
      rgVector4  : (
        X:Single;
        Y:Single;
        Z:Single;
        W:Single;
      );
}
      // user
      rgWord     : (asWord     :Word);
      rgByte     : (asByte     :Byte);
      rgBinary   : (len        :UInt32);
  end;
  TARGNode = array [0..MAXINT div SizeOf(pointer)-1] of PRGNode;

const
  SIGN_UNICODE = $FEFF;

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


//===== Nodes =====

function GetChildCount(anode:pointer):integer;
begin
  if (anode<>nil) and (PRGNode(anode)^.nodetype=rgGroup) then
    result:=PRGNode(anode)^.count
  else
    result:=0;
end;

function GetGroupCount(anode:pointer; aname:PWideChar=nil):integer;
var
  lp:PRGNode;
  i:integer;
begin
  result:=0;
  if (anode<>nil) and (PRGNode(anode)^.nodetype=rgGroup) then
  begin
    for i:=0 to PRGNode(anode)^.count-1 do
    begin
      lp:=PRGNode(anode)^.child^[i];
      if (lp^.nodetype=rgGroup) and
         ((aname=nil) or (CompareWide(lp^.name,aname)=0)) then
        inc(result);
    end;
  end;
end;

function GetChild(anode:pointer; idx:integer):pointer;
begin
  if (anode<>nil) and (PRGNode(anode)^.nodetype=rgGroup) and
     (idx>=0) and (idx<PRGNode(anode)^.count) then
    result:=PRGNode(anode)^.child^[idx]
  else
    result:=nil
end;

function GetNodeType(anode:pointer):integer;
begin
  if anode=nil then
    result:=rgNotValid
  else
    result:=PRGNode(anode)^.nodetype;
end;

function GetNodeName(anode:pointer):PWideChar;
begin
  if anode=nil then
    result:=nil
  else
    result:=PRGNode(anode)^.name;
end;

function GetCustomType(anode:pointer):PWideChar;
begin
  if (anode=nil) or (PRGNode(anode)^.nodetype<>rgUnknown) then
    result:=nil
  else
    result:=PRGNode(anode)^.CustomType;
end;

function SetNodeValue(anode:pointer; aval:PWideChar; alen:integer=0):ByteBool;
var
  lp:PWideChar;
  lval:array [0..47] of WideChar;
  i:integer;
begin
  result:=true;

  if anode<>nil then
  begin
    case PRGNode(anode)^.nodetype of
      rgString,
      rgTranslate,
      rgUnknown,
      rgNote     : begin
        if PRGNode(anode)^.asString<>nil then FreeMem(PRGNode(anode)^.asString);
        PRGNode(anode)^.asString:=CopyWide(aval,alen);
      end;
    else
      if alen>0 then
      begin
        i:=0;
        while i<alen do
        begin
          lval[i]:=aval[i];
          inc(i);
          if i=47 then break;
        end;
        lval[i]:=#0;
        lp:=@lval;
      end
      else
        lp:=aval;

      case PRGNode(anode)^.nodetype of
        rgInteger  : Val(lp,PRGNode(anode)^.asInteger);
        rgFloat    : Val(lp,PRGNode(anode)^.asFloat);
        rgDouble   : Val(lp,PRGNode(anode)^.asDouble);
        rgInteger64: Val(lp,PRGNode(anode)^.asInteger64);
        rgUnsigned : Val(lp,PRGNode(anode)^.asUnsigned);
        rgBool     : begin
         if ( lp<>nil) and (
            ((lp[0]='1') and (lp[1]=#0)) or
             (lp[0] in ['T','t']) and
             (lp[1] in ['R','r']) and
             (lp[2] in ['U','u']) and
             (lp[3] in ['E','e']) and
             (lp[4]=#0)
            ) then PRGNode(anode)^.asBoolean:=true
            else   PRGNode(anode)^.asBoolean:=false;
        end;
        // user
        rgByte     : Val(lp,PRGNode(anode)^.asByte);
        rgWord     : Val(lp,PRGNode(anode)^.asWord);
        rgBinary   : Val(lp,PRGNode(anode)^.len);
      else
        result:=false;
      end;
    end;
  end;
end;

function AddNode(aparent:pointer; aname:PWideChar;
                 atype  :integer; atext:PWideChar; alen:integer=0):pointer;
begin
  result:=nil;
  if (aparent<>nil) and (PRGNode(aparent)^.nodetype<>rgGroup) then exit;

  GetMem(result,SizeOf(TRGNode));

  FillChar(PRGNode(result)^,SizeOf(TRGNode),#0);
  PRGNode(result)^.name    :=CopyWide(aname);
  PRGNode(result)^.nodetype:=atype;
  if (atext<>nil) and (atext^<>#0) then
    SetNodeValue(result,atext,alen);

  if aparent<>nil then
  begin
    PRGNode(result)^.parent:=aparent;
    with PRGNode(aparent)^ do
    begin
      if count=capacity then
      begin
        inc(capacity,4);
        ReallocMem(child,capacity*SizeOf(PRGNode));
      end;
      child^[count]:=result;
      inc(count);
    end;
  end;

end;

procedure DeleteNodeInt(anode:pointer);
var
  i:integer;
begin
  if PRGNode(anode)^.name<>nil then FreeMem(PRGNode(anode)^.name);
  case PRGNode(anode)^.nodetype of
    rgGroup: begin
      for i:=0 to PRGNode(anode)^.count-1 do
        DeleteNodeInt(PRGNode(anode)^.child^[i]);
      FreeMem(PRGNode(anode)^.child);
    end;

    rgString,
    rgTranslate,
    rgUnknown,
    rgNote     : begin
      if PRGNode(anode)^.asString<>nil then FreeMem(PRGNode(anode)^.asString);
      if PRGNode(anode)^.nodetype=rgUnknown then
        if PRGNode(anode)^.CustomType<>nil then FreeMem(PRGNode(anode)^.customType);
    end;
  end;

  FreeMem(anode);
end;

procedure DeleteNode(anode:pointer);
var
  lnode:PRGNode;
  lchilds:PARGNode;
  i:integer;
begin
  if anode<>nil then
  begin
    lnode:=PRGNode(anode)^.parent;
    if lnode<>nil then
    begin
      lchilds:=lnode^.child;
      for i:=0 to lnode^.count-1 do
        if lchilds^[i]=anode then
        begin
          dec(lnode^.count);
          if i<lnode^.count then
            move(lchilds^[i+1],lchilds^[i],(lnode^.count-i)*SizeOf(PRGNode));
          break;
        end;
    end;

    DeleteNodeInt(anode);
  end;
end;

//----- Parse -----

function ParseDatFile(fname:PChar):pointer;
var
  f:file of byte;
  buf:PWideChar;
  i:integer;
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

  try
    result:=ParseDat(buf,fname);
  finally
    FreeMem(buf);
  end;
end;
  
function ParseDat(buf:PWideChar; aid:PChar=nil):pointer;
var
  lutype:PWideChar;
  lnode,lgroup:PRGNode;
  pc,peoln:PWideChar;
  lline,ltype,ldst,idx:integer;
  lname:array [0..127] of WideChar;
  leof,lclose:boolean;
begin
  result:=nil;

  peoln:=buf;
  if ORD(peoln^)=SIGN_UNICODE then inc(peoln);

  lgroup:=nil;

  lline:=0;

  // exit, if not ASCII in UTF16LE encoding
  if (ORD(peoln^)>$FF) then exit;

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
          if Assigned(OnError) then OnError(errCloseNoRoot,aid,lline);
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
        if (not Assigned(OnError)) or (OnError(errTagNoClose,aid,lline)<>0) then
        begin
          DeleteNode(result);
          exit;
        end;
      end;

      if lclose then
      begin
        if CompareWide(lgroup^.name,lname)<>0 then
        begin
          if (not Assigned(OnError)) or (OnError(errTagCloseWrong,aid,lline)<>0) then
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
        lgroup:=AddNode(lgroup,lname,rgGroup,nil);
        if result=nil then
          result:=lgroup;
      end;
    end
    //--- property
    else if pc[idx]='<' then
    begin
      if lgroup=nil then
      begin
        if Assigned(OnError) then OnError(errNoRoot,aid,lline);
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
        if (not Assigned(OnError)) or (OnError(errPropNoClose,aid,lline)<>0) then
        begin
          DeleteNode(result);
          exit;
        end;
      end;
      inc(idx);
      ltype:=TextToType(lname);
      if ltype=rgUnknown then lutype:=CopyWide(lname);

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

      lnode:=AddNode(lgroup,lname,ltype,@pc[idx]);
      if ltype=rgUnknown then
      begin
        lnode^.CustomType:=lutype;
        if Assigned(OnError) then OnError(errUnknownTag,aid,lline);
      end;
    end;
  until leof;
  if lgroup<>nil then
  begin
    if (not Assigned(OnError)) or (OnError(errRootNoClose,aid,lline)<>0) then
    begin
      DeleteNode(result);
      exit;
    end;
  end;

end;

//----- Dump -----

function DumpNode(var buf:PByte; var idx:integer; anode:PRGNode; atab:integer):boolean;
var
  larr:array [0..127] of WideChar;
  ls:WideString;
  pc:PWideChar;
  i,j,llen:integer;
begin
  result:=true;

  i:=0;
  while i<atab do
  begin
    larr[i]:=#9;
    inc(i);
  end;

  llen:=Length(anode^.name);

  if anode^.nodetype=rgGroup then
  begin
    // opening tag
    larr[i]:='['; inc(i);
    for j:=0 to llen-1 do
    begin
      larr[i]:=anode^.name[j];
      inc(i);
    end;
    larr[i]:=']'; inc(i);
    larr[i]:=#13; inc(i);
    larr[i]:=#10; inc(i);
    larr[i]:=#0;
    WriteWide(buf,idx,@larr);

    // children
    for i:=0 to anode^.count-1 do
      DumpNode(buf,idx,anode^.child^[i], atab+1);

    // closing tag
    i:=atab;
    larr[i]:='['; inc(i);
    larr[i]:='/'; inc(i);
    for j:=0 to llen-1 do
    begin
      larr[i]:=anode^.name[j];
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
    pc:=TypeToText(anode^.nodetype);
    if anode^.nodetype=rgUnknown then // pc=nil
      pc:=anode^.CustomType;

    while pc^<>#0 do
    begin
      larr[i]:=pc^;
      inc(i);
      inc(pc);
    end;
    larr[i]:='>'; inc(i);

    // property name
    for j:=0 to llen-1 do
    begin
      larr[i]:=anode^.name[j];
      inc(i);
    end;

    // construct value in ls
    case anode^.nodetype of
      rgBool      : if anode^.asBoolean then ls:='true' else ls:='false';
      rgString,
      rgTranslate,
      rgNote,
      rgUnknown   : ls:=anode^.asString;
      rgFloat     : begin
        Str(anode^.asFloat:0:4,ls);
        j:=Length(ls);

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
      rgDouble    : Str(anode^.asDouble:0:4,ls);
      rgInteger   : Str(anode^.asInteger  ,ls);
      rgInteger64 : Str(anode^.asInteger64,ls);
      rgUnsigned  : Str(anode^.asUnsigned ,ls);
      // custom
{ 
      rgVector2   : ;
      rgVector3   : ;
      rgVector4   : ;
}
      // user
      rgWord      : Str(anode^.asWord     ,ls);
      rgByte      : Str(anode^.asByte     ,ls);
      rgBinary    : Str(anode^.len        ,ls);
    else
      ls:='';
    end;

    // prop name or value is not empty
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

function MakeDatTree(anode:pointer; out aptr:PWideChar):ByteBool;
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

function WriteDatTree(anode:pointer; fname:PChar):ByteBool;
var
  f:file of byte;
  lpc:PWideChar;
begin
  result:=MakeDatTree(anode,lpc);

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

//----- Adding -----

function AddGroup(aparent:pointer; aname:PWideChar):pointer;
begin
  result:=AddNode(aparent, aname, rgGroup, nil);
end;

function AddString(aparent:pointer; aname:PWideChar; aval:PWideChar):pointer;
begin
  result:=AddNode(aparent, aname, rgString, aval);
end;

function AddTranslate(aparent:pointer; aname:PWideChar; aval:PWideChar):pointer;
begin
  result:=AddNode(aparent, aname, rgTranslate, aval);
end;

function AddNote(aparent:pointer; aname:PWideChar; aval:PWideChar):pointer;
begin
  result:=AddNode(aparent, aname, rgNote, aval);
end;

function AddBool(aparent:pointer; aname:PWideChar; aval:ByteBool):pointer;
begin
  result:=AddNode(aparent, aname, rgBool, nil);
  if result<>nil then PRGNode(result)^.asBoolean:=aval;
end;

function AddInteger(aparent:pointer; aname:PWideChar; aval:Int32):pointer;
begin
  result:=AddNode(aparent, aname, rgInteger, nil);
  if result<>nil then PRGNode(result)^.asInteger:=aval;
end;

function AddFloat(aparent:pointer; aname:PWideChar; aval:single):pointer;
begin
  result:=AddNode(aparent, aname, rgFloat, nil);
  if result<>nil then PRGNode(result)^.asFloat:=aval;
end;

function AddDouble(aparent:pointer; aname:PWideChar; aval:double):pointer;
begin
  result:=AddNode(aparent, aname, rgDouble, nil);
  if result<>nil then PRGNode(result)^.asDouble:=aval;
end;

function AddInteger64(aparent:pointer; aname:PWideChar; aval:Int64):pointer;
begin
  result:=AddNode(aparent, aname, rgInteger64, nil);
  if result<>nil then PRGNode(result)^.asInteger64:=aval;
end;

function AddUnsigned(aparent:pointer; aname:PWideChar; aval:UInt32):pointer;
begin
  result:=AddNode(aparent, aname, rgUnsigned, nil);
  if result<>nil then PRGNode(result)^.asUnsigned:=aval;
end;

// User types

function AddByte(aparent:pointer; aname:PWideChar; aval:byte):pointer;
begin
  result:=AddNode(aparent, aname, rgByte, nil);
  if result<>nil then PRGNode(result)^.asByte:=aval;
end;

function AddWord(aparent:pointer; aname:PWideChar; aval:word):pointer;
begin
  result:=AddNode(aparent, aname, rgWord, nil);
  if result<>nil then PRGNode(result)^.asWord:=aval;
end;

function AddBinary(aparent:pointer; aname:PWideChar; aval:UInt32):pointer;
begin
  result:=AddNode(aparent, aname, rgBinary, nil);
  if result<>nil then PRGNode(result)^.len:=aval;
end;

function AddCustom(aparent:pointer; aname:PWideChar; aval:PWideChar; atype:PWideChar):pointer;
begin
  result:=AddNode(aparent, aname, rgUnknown, aval);
  if result<>nil then PRGNode(result)^.CustomType:=CopyWide(atype);
end;

//----- Write data -----

function AsBool(anode:pointer; aval:ByteBool):ByteBool;
begin
  if (anode<>nil) and
     (PRGNode(anode)^.nodetype=rgBool) then
    PRGNode(anode)^.asBoolean:=aval;

  result:=aval;
end;

function AsInteger(anode:pointer; aval:Int32):Int32;
begin
  if (anode<>nil) and
     (PRGNode(anode)^.nodetype in [rgInteger,rgUnsigned]) then
    PRGNode(anode)^.asInteger:=aval;

  result:=aval;
end;

function AsUnsigned(anode:pointer; aval:UInt32):UInt32;
begin
  if (anode<>nil) and
     (PRGNode(anode)^.nodetype in [rgInteger,rgUnsigned]) then
    PRGNode(anode)^.asUnsigned:=aval;

  result:=aval;
end;

function AsFloat(anode:pointer; aval:single):single;
begin
  if (anode<>nil) and
     (PRGNode(anode)^.nodetype=rgFloat) then
    PRGNode(anode)^.asFloat:=aval;

  result:=aval;
end;

function AsDouble(anode:pointer; aval:double):double;
begin
  if (anode<>nil) and
     (PRGNode(anode)^.nodetype=rgDouble) then
    PRGNode(anode)^.asDouble:=aval;

  result:=aval;
end;

function AsInteger64(anode:pointer; aval:Int64):Int64;
begin
  if (anode<>nil) and
     (PRGNode(anode)^.nodetype=rgInteger64) then
    PRGNode(anode)^.asInteger64:=aval;

  result:=aval;
end;

function AsString(anode:pointer; aval:PWideChar):PWideChar;
begin
  if (anode<>nil) and
     (PRGNode(anode)^.nodetype in [rgString,rgTranslate,rgNote]) then
  begin
    FreeMem(PRGNode(anode)^.asString);
    PRGNode(anode)^.asString:=CopyWide(aval);
  end;

  result:=aval;
end;

function AsTranslate(anode:pointer; aval:PWideChar):PWideChar;
begin
  if (anode<>nil) and
     (PRGNode(anode)^.nodetype in [rgString,rgTranslate,rgNote]) then
  begin
    FreeMem(PRGNode(anode)^.asString);
    PRGNode(anode)^.asString:=CopyWide(aval);
  end;

  result:=aval;
end;

function AsNote(anode:pointer; aval:PWideChar):PWideChar;
begin
  if (anode<>nil) and
     (PRGNode(anode)^.nodetype in [rgString,rgTranslate,rgNote]) then
  begin
    FreeMem(PRGNode(anode)^.asString);
    PRGNode(anode)^.asString:=CopyWide(aval);
  end;

  result:=aval;
end;

//----- Read data -----

function AsBool(anode:pointer):ByteBool;
begin
  if (anode<>nil) and
     (PRGNode(anode)^.nodetype=rgBool) then
    result:=PRGNode(anode)^.asBoolean
  else
    result:=false;
end;

function AsInteger(anode:pointer):Int32;
begin
  if (anode<>nil) and
     (PRGNode(anode)^.nodetype in [rgInteger,rgUnsigned]) then
    result:=PRGNode(anode)^.asInteger
  else
    result:=0;
end;

function AsUnsigned(anode:pointer):UInt32;
begin
  if (anode<>nil) and
     (PRGNode(anode)^.nodetype in [rgInteger,rgUnsigned]) then
    result:=PRGNode(anode)^.asUnsigned
  else
    result:=0;
end;

function AsFloat(anode:pointer):single;
begin
  if (anode<>nil) and
     (PRGNode(anode)^.nodetype=rgFloat) then
    result:=PRGNode(anode)^.asFloat
  else
    result:=0;
end;

function AsDouble(anode:pointer):double;
begin
  if (anode<>nil) and
     (PRGNode(anode)^.nodetype=rgDouble) then
    result:=PRGNode(anode)^.asDouble
  else
    result:=0;
end;

function AsInteger64(anode:pointer):Int64;
begin
  if (anode<>nil) and
     (PRGNode(anode)^.nodetype=rgInteger64) then
    result:=PRGNode(anode)^.asInteger64
  else
    result:=0;
end;

function AsString(anode:pointer):PWideChar;
begin
  if (anode<>nil) and
     (PRGNode(anode)^.nodetype in [rgString,rgTranslate,rgNote]) then
    result:=PRGNode(anode)^.asString
  else
    result:=nil;
end;

function AsTranslate(anode:pointer):PWideChar;
begin
  if (anode<>nil) and
     (PRGNode(anode)^.nodetype in [rgString,rgTranslate,rgNote]) then
    result:=PRGNode(anode)^.asString
  else
    result:=nil;
end;

function AsNote(anode:pointer):PWideChar;
begin
  if (anode<>nil) and
     (PRGNode(anode)^.nodetype in [rgString,rgTranslate,rgNote]) then
    result:=PRGNode(anode)^.asString
  else
    result:=nil;
end;

//----- Search -----

function FindNode(anode:pointer; apath:PWideChar):pointer;
var
  lname:array [0..127] of WideChar;
  lnode,lcnode:PRGNode;
  p1,p2:PWideChar;
  i:integer;
begin
  result:=nil;
  if (anode=nil) then exit;
  if (apath=nil) or (apath^=#0) then exit(anode);
  if PRGNode(anode)^.nodetype<>rgGroup then exit;

  if (CharPosWide('\',apath)=nil) and (CharPosWide('/',apath)=nil) then
  begin
    for i:=0 to PRGNode(anode)^.count-1 do
    begin
      lcnode:=PRGNode(anode)^.child^[i];
      if CompareWide(lcnode^.name,apath)=0 then
        exit(lcnode);
    end;
  end
  else
  begin
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
      if lnode^.nodetype<>rgGroup then exit;
      for i:=0 to lnode^.count-1 do
      begin
        lcnode:=lnode^.child^[i];
        if (p2^=#0) xor (lcnode^.nodetype=rgGroup) then
        begin
          if CompareWide(lcnode^.name,lname)=0 then
          begin
            result:=lcnode;
            break;
          end;
        end
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
end;

end.
