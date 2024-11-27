{NOTE: don't do it (node extract harder, global structure needs) separate node -> array of nodes like rgfs. pointer -> index}
{TODO: Add line numbers support}
{TODO: change Add*** to AddNode+As***}
{TODO: make variant of node with arrays of nodes for non-cutting actions}
{TODO: Add UTF8Text field with one-time conversion on request}
{TODO: Keep all numeric as Int64}
{TODO: Rename As* method to Get*/Set*}
{TODO: As* for get value - add default values}
{TODO: Add blob field for use as Hash for names or ID for layout nodes. but not both?}
{TODO: Add Insert method at least for top (for IDs)}
{
  Tree-like object
  every node almost independent, have it's own child list
}
unit RGNode;

interface

uses
  rgglobal;

procedure DeleteNode  (anode:pointer);
function  CutNode     (anode:pointer):pointer;
function  FindNode    (anode:pointer; apath:PWideChar):pointer;
function  CloneNode   (anode:pointer):pointer;

function GetChildCount(anode:pointer):integer;
function GetChild     (anode:pointer; idx:cardinal):pointer;
function GetGroupCount(anode:pointer; aname:PWideChar=nil):integer;
function GetNodeType  (anode:pointer):integer;
function GetNodeName  (anode:pointer):PWideChar;
function GetNodeParent(anode:pointer):pointer;
function GetCustomType(anode:pointer):PWideChar;

function SetNodeValue (anode:pointer; aval :PWideChar; alen:integer=0):ByteBool;
function SetNodeName  (anode:pointer; aname:PWideChar):boolean;
function IsNodeName   (anode:pointer; ahash:dword    ):boolean;
function IsNodeName   (anode:pointer; aname:PWideChar):boolean;

//--- Write data ---

function AsBool     (anode:pointer; aval:ByteBool ):ByteBool;
function AsInteger  (anode:pointer; aval:Int32    ):Int32;
function AsUnsigned (anode:pointer; aval:UInt32   ):UInt32;
function AsFloat    (anode:pointer; aval:single   ):single;
function AsDouble   (anode:pointer; aval:double   ):double;
function AsInteger64(anode:pointer; aval:Int64    ):Int64;
function AsQWord    (anode:pointer; aval:QWord    ):QWord;
function AsString   (anode:pointer; aval:PWideChar):PWideChar;
function AsTranslate(anode:pointer; aval:PWideChar):PWideChar;
function AsNote     (anode:pointer; aval:PWideChar):PWideChar;
function AsVector   (anode:pointer; var aval):PVector;

//--- Read data ---

function AsBool     (anode:pointer):ByteBool;
function AsInteger  (anode:pointer):Int32;
function AsUnsigned (anode:pointer):UInt32;
function AsFloat    (anode:pointer):single;
function AsDouble   (anode:pointer):double;
function AsInteger64(anode:pointer):Int64;
function AsQWord    (anode:pointer):QWord;
function AsString   (anode:pointer):PWideChar;
function AsTranslate(anode:pointer):PWideChar;
function AsNote     (anode:pointer):PWideChar;
function AsVector   (anode:pointer):PVector;

//--- Add data ---

function AddNode     (aparent:pointer; anode:pointer):pointer;
function AddNode     (aparent:pointer; aname:PWideChar;
                      atype  :integer; atext:PWideChar; alen:integer=0):pointer;
function AddGroup    (aparent:pointer; aname:PWideChar):pointer;
function AddBool     (aparent:pointer; aname:PWideChar; aval:ByteBool ):pointer;
function AddInteger  (aparent:pointer; aname:PWideChar; aval:Int32    ):pointer;
function AddUnsigned (aparent:pointer; aname:PWideChar; aval:UInt32   ):pointer;
function AddFloat    (aparent:pointer; aname:PWideChar; aval:single   ):pointer;
function AddDouble   (aparent:pointer; aname:PWideChar; aval:double   ):pointer;
function AddInteger64(aparent:pointer; aname:PWideChar; aval:Int64    ):pointer;
function AddQWord    (aparent:pointer; aname:PWideChar; aval:QWord    ):pointer;
function AddString   (aparent:pointer; aname:PWideChar; aval:PWideChar):pointer;
function AddTranslate(aparent:pointer; aname:PWideChar; aval:PWideChar):pointer;
function AddNote     (aparent:pointer; aname:PWideChar; aval:PWideChar):pointer;
// user
function AddBinary   (aparent:pointer; aname:PWideChar; aval:UInt32   ):pointer;
function AddByte     (aparent:pointer; aname:PWideChar; aval:byte     ):pointer;
function AddWord     (aparent:pointer; aname:PWideChar; aval:word     ):pointer;
function AddCustom   (aparent:pointer; aname:PWideChar; aval:PWideChar; atype:PWideChar):pointer;
function AddVector   (aparent:pointer; aname:PWideChar; var aval      ; atype:integer  ):pointer;


implementation

uses
  rgdict;

{.$DEFINE UseBlocks}

const
  CapacityStep = 10;

const
  setNumeric = [rgInteger, rgUnsigned , rgInteger64];
  setText    = [rgString , rgTranslate, rgNote];
  setVector  = [rgVector2, rgVector3  , rgVector4];

{$IFDEF UseBlocks}
type
  TNodeText = record
  case boolean of
    false: (buf: array [0..15] of UnicodeChar);
    true : (ptr: PUnicodeChar);
  end;
{$ENDIF}
type
  PARGNode = ^TARGNode;
  PRGNode = ^TRGNode;
{$IFDEF UseBlocks}
  TRGNode = record
    name   : TNodeText;
    parent : PRGNode; // really needs just for deleting
    hash   : dword;
    namelen: word;
    case nodetype:SmallInt of
      rgGroup    : (
        count   :word;
        capacity:word;
        case boolean of
          false: (
            child:PARGNode);
          true:  (
            child1:PRGNode;
            child2:PRGNode);
      );
      rgString,
      rgTranslate,
      rgNote,
      rgUnknown  : (
        length    :word;
        asString  :TNodeText;
        CustomType:PWideChar;  // for rgUnknown only
      );
{$ELSE}
  TRGNode = record
    name   : PWideChar;
    parent : PRGNode; // really needs just for deleting
    hash   : dword;
    case nodetype:SmallInt of
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
{$ENDIF}
      rgBool     : (asBoolean  :ByteBool);
      rgInteger  : (asInteger  :Int32);
      rgUnsigned : (asUnsigned :UInt32);
      rgInteger64: (asInteger64:Int64);
      rgFloat    : (asFloat    :Single);
      rgDouble   : (asDouble   :Double);
      // custom
      rgVector2,
      rgVector3,
      rgVector4  : (
        X:Single;
        Y:Single;
        Z:Single;
        W:Single;
      );
      // user
      rgQWord    : (asQWord    :QWord);
      rgWord     : (asWord     :Word);
      rgByte     : (asByte     :Byte);
      rgBinary   : (len        :UInt32);
  end;
  TARGNode = array [0..MAXINT div SizeOf(pointer)-1] of PRGNode;


function IsNumber(astr:PWideChar):boolean;
begin
  result:=false;
  if (astr=nil) or (astr^=#0) then exit;
  if astr^='-' then inc(astr);
  repeat
    if not (ord(astr^) in [ord('0')..ord('9')]) then exit;
    inc(astr);
  until astr^=#0;
  result:=true;
end;

{%REGION Name}
function IsNodeName(anode:pointer; aname:PWideChar):boolean;
begin
  result:=(anode<>nil) and (PRGNode(anode)^.hash=RGHash(aname));
end;

function IsNodeName(anode:pointer; ahash:dword):boolean;
begin
  result:=(anode<>nil) and (PRGNode(anode)^.hash=ahash);
end;

function GetNodeName(anode:pointer):PWideChar;
begin
  if anode=nil then
    result:=nil
{$IFDEF UseBlocks}
  else if PRGNode(anode)^.namelen>15 then
    result:=PRGNode(anode)^.name.ptr
  else if PRGNode(anode)^.namelen>0 then
    result:=PWideChar(@PRGNode(anode)^.name.buf[0])
{$ELSE}
  else if PRGNode(anode)^.name<>nil then
    result:=PRGNode(anode)^.name
{$ENDIF}
  else
    result:=RGTags.Tag[PRGNode(anode)^.hash];
end;

procedure FreeNodeName(anode:pointer);
begin
{$IFDEF UseBlocks}
  if PRGNode(anode)^.namelen>15 then FreeMem(PRGNode(anode)^.name.ptr);
  PRGNode(anode)^.namelen:=0;
{$ELSE}
  FreeMem(PRGNode(anode)^.name);
{$ENDIF}
end;

function SetNodeName(anode:pointer; aname:PWideChar):boolean;
begin
  if anode=nil then
    result:=false
  else
  begin
    FreeNodeName(anode);

    if (aname<>nil) and (aname^<>#0) then
    begin
      if IsNumber(aname) then
        Val(aname,PRGNode(anode)^.hash)
      else
        PRGNode(anode)^.hash:=RGHash(aname);

      if not RGTags.Exists(PRGNode(anode)^.hash) then
      begin
{$IFDEF UseBlocks}
        PRGNode(anode)^.namelen:=Length(aname);
        if PRGNode(anode)^.namelen>15 then
          CopyWide(PRGNode(anode)^.name.ptr,aname)
        else
          move(aname^, PRGNode(anode)^.name.buf[0],
              (PRGNode(anode)^.namelen+1)*SizeOf(WideChar));
{$ELSE}
        CopyWide(PRGNode(anode)^.name,aname)
{$ENDIF}
      end;
    end
    else
      PRGNode(anode)^.hash:=0;

    result:=true;
  end;
end;
{%ENDREGION Name}

{%REGION Node}
procedure SetNodeType(anode:pointer; atype:integer); inline;
begin
  PRGNode(anode)^.nodetype:=atype;
end;

function GetNodeType(anode:pointer):integer;
begin
  if anode=nil then
    result:=rgNotValid
  else
    result:=PRGNode(anode)^.nodetype;
end;

function GetChildCount(anode:pointer):integer;
begin
  if GetNodeType(anode)=rgGroup then
    result:=PRGNode(anode)^.count
  else
    result:=0;
end;

function GetChild(anode:pointer; idx:cardinal):pointer;
begin
  if (GetNodeType(anode)=rgGroup) and
     (idx<PRGNode(anode)^.count) then
  begin
{$IFDEF UseBlocks}
    if PRGNode(anode)^.count>2 then
      result:=PRGNode(anode)^.child^[idx]
    else if idx=0 then
      result:=PRGNode(anode)^.child1
    else
      result:=PRGNode(anode)^.child2;
{$ELSE}
    result:=PRGNode(anode)^.child^[idx]
{$ENDIF}
  end
  else
    result:=nil;
end;

function GetGroupCount(anode:pointer; aname:PWideChar=nil):integer;
var
  lp:PRGNode;
  lhash:dword;
  i:integer;
begin
  result:=0;
  lhash:=0;
  if GetNodeType(anode)=rgGroup then
  begin
    if (aname<>nil) and (aname^<>#0) then
      lhash:=RGHash(aname)
    else
      lhash:=0;

    for i:=0 to GetChildCount(anode)-1 do
    begin
      lp:=GetChild(anode,i);
      if (GetNodeType(lp)=rgGroup) and
         ((lhash=0) or (lp^.hash=lhash)) then
        inc(result);
    end;
  end;
end;

function GetCustomType(anode:pointer):PWideChar;
begin
  if (anode=nil) or (GetNodeType(anode)<>rgUnknown) then
    result:=nil
  else
    result:=PRGNode(anode)^.CustomType;
end;

function GetNodeParent(anode:pointer):pointer;
begin
  if anode=nil then
    result:=nil
  else
    result:=PRGNode(anode)^.parent;
end;

procedure FreeStringValue(anode:pointer);
begin
{$IFDEF UseBlocks}
  if PRGNode(anode)^.length>15 then FreeMem(PRGNode(anode)^.asString.ptr);
{$ELSE}
  FreeMem(PRGNode(anode)^.asString);
{$ENDIF}
end;

function GetStringValue(anode:pointer):PWideChar;
begin
{$IFDEF UseBlocks}
  if PRGNode(anode)^.length>15 then
    result:=PRGNode(anode)^.asString.ptr
  else if PRGNode(anode)^.length=0 then
    result:=nil
  else
    result:=PWideChar(@PRGNode(anode)^.AsString.buf[0]);
{$ELSE}
    result:=PRGNode(anode)^.asString;
{$ENDIF}
end;

procedure SetStringValue(anode:pointer; aval:PWideChar; alen:integer=0);
begin
  FreeStringValue(anode);

{$IFDEF UseBlocks}
  if alen=0 then
    PRGNode(anode)^.length:=Length(aval)
  else
    PRGNode(anode)^.length:=alen;

  if PRGNode(anode)^.length>15 then
    PRGNode(anode)^.asString.ptr:=CopyWide(aval,alen)
  else if PRGNode(anode)^.length=0 then
    PRGNode(anode)^.asString.buf[0]:=#0
  else
  begin
    move(aval^, PRGNode(anode)^.asString.buf[0],
        (PRGNode(anode)^.length)*SizeOf(WideChar));
    PRGNode(anode)^.asString.buf[PRGNode(anode)^.length]:=#0;
  end;
{$ELSE}
  PRGNode(anode)^.asString:=CopyWide(aval,alen)
{$ENDIF}
end;

procedure SetFloatValue(var aval:PWideChar; var adst:Single);
var
  lval:array [0..47] of WideChar;
  lidx:integer;
begin
  if aval^=#0 then
  begin
    adst:=0;
    exit;
  end;

  lidx:=0;
  repeat
    while not (AnsiChar(ORD(aval^)) in ['+','-','.','0'..'9']) do inc(aval);
    lval[lidx]:=aval^;
    inc(lidx);
    inc(aval);
  until (aval^=',') or (aval^=#0);
  lval[lidx]:=#0;
  Val(lval, adst);
end;

function SetNodeValue(anode:pointer; aval:PWideChar; alen:integer=0):ByteBool;
var
  lp:PWideChar;
  lval:array [0..47] of WideChar;
  i,ltype:integer;
  res:word;
begin
  result:=true;

  if anode<>nil then
  begin
    ltype:=GetNodeType(anode);
    case ltype of
      rgString,
      rgTranslate,
      rgUnknown,
      rgNote     : begin
        SetStringValue(anode,aval,alen);
      end;

      rgVector2: begin
        SetFloatValue(aval,PRGNode(anode)^.X);
        SetFloatValue(aval,PRGNode(anode)^.Y);
      end;
      rgVector3: begin
        SetFloatValue(aval,PRGNode(anode)^.X);
        SetFloatValue(aval,PRGNode(anode)^.Y);
        SetFloatValue(aval,PRGNode(anode)^.Z);
      end;
      rgVector4: begin
        SetFloatValue(aval,PRGNode(anode)^.X);
        SetFloatValue(aval,PRGNode(anode)^.Y);
        SetFloatValue(aval,PRGNode(anode)^.Z);
        SetFloatValue(aval,PRGNode(anode)^.W);
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

      res:=0;
      case ltype of
        rgInteger  : Val(lp,PRGNode(anode)^.asInteger,res);
        rgFloat    : Val(lp,PRGNode(anode)^.asFloat,res);
        rgDouble   : Val(lp,PRGNode(anode)^.asDouble,res);
        rgInteger64: Val(lp,PRGNode(anode)^.asInteger64,res);
        rgUnsigned : Val(lp,PRGNode(anode)^.asUnsigned,res);
        rgBool     : begin
         if  (lp<>nil) and (
             ((lp[0]='1') and (lp[1]=#0 )) or
            (((lp[0]='T') or  (lp[0]='t')) and
             ((lp[1]='R') or  (lp[1]='r')) and
             ((lp[2]='U') or  (lp[2]='u')) and
             ((lp[3]='E') or  (lp[3]='e')) and
              (lp[4]=#0))
            ) then PRGNode(anode)^.asBoolean:=true
            else   PRGNode(anode)^.asBoolean:=false;
        end;
        // user
        rgByte     : Val(lp,PRGNode(anode)^.asByte,res);
        rgWord     : Val(lp,PRGNode(anode)^.asWord,res);
        rgQWord    : Val(lp,PRGNode(anode)^.asQWord,res);
        rgBinary   : Val(lp,PRGNode(anode)^.len,res);
      else
        result:=false;
      end;
      if res<>0 then
        RGLog.Add('Wrong conversion to number: "'+string(lp)+'"');
    end;
  end;
end;

function AddNode(aparent:pointer; anode:pointer):pointer;
{$IFDEF UseBlocks}
var
  lptr:PARGNode;
{$ENDIF}
begin
  result:=anode;
  if anode=nil then exit;

  if (aparent<>nil) and (GetNodeType(aparent)=rgGroup) then
  begin
    PRGNode(result)^.parent:=aparent;
    with PRGNode(aparent)^ do
    begin
      if capacity=0 then
      begin
{$IFDEF UseBlocks}
        if      count=0 then child1:=result
        else if count=1 then child2:=result
        else
        begin
          capacity:=CapacityStep;
          GetMem(lptr,capacity*SizeOf(PRGNode));
          lptr^[0]:=child1;
          lptr^[1]:=child2;
          child:=lptr;
        end
{$ELSE}
        capacity:=CapacityStep;
        GetMem(child,capacity*SizeOf(PRGNode));
{$ENDIF}
      end
      else if count>=capacity then
      begin
        inc(capacity,CapacityStep);
        ReallocMem(child,capacity*SizeOf(PRGNode));
      end;
{$IFDEF UseBlocks}
      if count>=2 then
{$ENDIF}
        child^[count]:=result;

      inc(count);
    end;
  end;
end;

function AddNode(aparent:pointer; aname:PWideChar;
                 atype  :integer; atext:PWideChar; alen:integer=0):pointer;
begin
  if (aparent<>nil) and (GetNodeType(aparent)<>rgGroup) then exit(nil);

  GetMem(result,SizeOf(TRGNode));

  FillChar(PRGNode(result)^,SizeOf(TRGNode),#0);
  
  SetNodeType(result, atype);
  if (atext<>nil) and (atext^<>#0) then SetNodeValue(result, atext, alen);
  if (aname<>nil) and (aname^<>#0) then SetNodeName (result, aname);

  AddNode(aparent,result);
end;

function CutNode(anode:pointer):pointer;
var
  lnode:PRGNode;
{$IFDEF UseBlocks}
  lchild1,lchild2:pointer;
{$ENDIF}
  i:integer;
begin
  result:=anode;
  if anode=nil then exit;

  lnode:=PRGNode(anode)^.parent;
  if lnode<>nil then
  begin
    dec(lnode^.count);
{$IFDEF UseBlocks}
    if      lnode^.count=0 then // do nothing, was single child
    else if lnode^.count=1 then
    begin
      if lnode^.child1=anode then lnode^.child1:=lnode^.child2;
    end
    else
{$ENDIF}
    begin
      for i:=0 to lnode^.count do
        if lnode^.child^[i]=anode then
        begin
          if i<lnode^.count then
            move(lnode^.child^[i+1],lnode^.child^[i],(lnode^.count-i)*SizeOf(PRGNode));
{$IFDEF UseBlocks}
          if lnode^.count=2 then
          begin
            lchild1:=lnode^.child^[0];
            lchild2:=lnode^.child^[1];

            FreeMem(lnode^.child);
            lnode^.capacity:=0;

            lnode^.child1:=lchild1;
            lnode^.child2:=lchild2;
          end;
{$ENDIF}
          break;
        end;
    end;

    PRGNode(anode)^.parent:=nil;
  end;
end;

procedure FreeNode(anode:pointer);
var
  i,lcnt,ltype:integer;
begin
  FreeNodeName(anode);

  ltype:=GetNodeType(anode);
  case ltype of
    rgGroup: begin
      lcnt:=GetChildCount(anode);
      for i:=0 to lcnt-1 do
        FreeNode(GetChild(anode,i));
{$IFDEF UseBlocks}
      if lcnt>2 then
{$ENDIF}
        FreeMem(PRGNode(anode)^.child);
    end;

    rgString,
    rgTranslate,
    rgUnknown,
    rgNote     : begin
      FreeStringValue(anode);

      if ltype=rgUnknown then
        if PRGNode(anode)^.CustomType<>nil then FreeMem(PRGNode(anode)^.customType);
    end;
  end;

  FreeMem(anode);
end;

procedure DeleteNode(anode:pointer);
begin
  if anode<>nil then
  begin
    CutNode(anode);
    FreeNode(anode);
  end;
end;

function ReplaceNode(aparent:pointer; anode:pointer):boolean;
var
  lname:PWideChar;
  lnode:pointer;
  i:integer;
begin
  result:=false;
  lname:=GetNodeName(anode);
{
    lchilds:=aparent^.child;
    for i:=0 to aparent^.count-1 do
}
  for i:=0 to GetChildCount(aparent)-1 do
  begin
    lnode:=GetChild(aparent,i);
    if CompareWide(lname,GetNodeName(lnode))=0 then
    begin
      // FreeNode(lchilds^[i]);
      // lchilds^[i]:=anode;
      result:=true;
      break;
    end;
  end;
end;

//----- Search -----

function FindNode(anode:pointer; apath:PWideChar):pointer;
var
  lnode,lcnode:PRGNode;
  p1:PWideChar;
  lhash:dword;
  i:integer;
begin
  result:=nil;
  if GetNodeType(anode)<>rgGroup then exit;
  if (apath=nil) or (apath^=#0) then exit(anode);

  // search just direct child
  if (CharPosWide('\',apath)=nil) and (CharPosWide('/',apath)=nil) then
  begin
    lhash:=RGHash(apath);
    for i:=0 to GetChildCount(anode)-1 do
    begin
      lcnode:=GetChild(anode,i);
      if lcnode^.hash=lhash then
        exit(lcnode);
    end;
  end
  else
  begin
    lnode:=anode;

    while apath^<>#0 do
    begin
      // 1 - get path part
      i:=0;
      p1:=apath;
      while not (ord(apath^) in [ord('\'),ord('/'),0]) do
      begin
        inc(apath);
        inc(i);
      end;
      if i=0 then exit;
      lhash:=RGHash(p1,i);

      // 2 - search this part
      result:=nil;
      if GetNodeType(lnode)<>rgGroup then exit;
      for i:=0 to GetChildCount(lnode)-1 do
      begin
        lcnode:=GetChild(lnode,i);
        if (apath^=#0) xor (GetNodeType(lcnode)=rgGroup) then
        begin
          if lcnode^.hash=lhash then
          begin
            result:=lcnode;
            break;
          end;
        end
      end;
      if result=nil then exit;

      // 3 - if not "name" then next cycle
      if apath^<>#0 then
      begin
        inc(apath);
        lnode:=result;
      end;
    end;
  end;
end;

//----- Clone -----

function CopyNodeValue(adst, asrc:pointer):pointer;
var
  ltype:integer;
begin
  ltype:=GetNodeType(adst);
  SetNodeType(adst,ltype);

  if ltype in [rgString,rgTranslate,rgNote] then
    SetStringValue(adst,asString(asrc))
  else
    move(PRGNode(asrc)^.X,PRGNode(adst)^.X,SizeOf(TVector4));

  result:=adst;
end;

function CloneNode(anode:pointer):pointer;
var
  i,lcnt,ltype:integer;
begin
  ltype:=GetNodeType(anode);

  if ltype<>rgNotValid then
  begin
    result:=AddNode(nil,GetNodeName(anode),ltype,nil);
    if ltype<>rgGroup then
      CopyNodeValue(result,anode)
    else
    begin
      lcnt:=GetChildCount(anode);
      PRGNode(result)^.count:=lcnt;

{$IFDEF UseBlocks}
      if lcnt=1 then
      begin
        PRGNode(result)^.child1:=CloneNode(GetChild(anode,0));
        PRGNode(result)^.child1^.parent:=result;
      end
      else if lcnt=2 then
      begin
        PRGNode(result)^.child1:=CloneNode(GetChild(anode,0));
        PRGNode(result)^.child1^.parent:=result;

        PRGNode(result)^.child2:=CloneNode(GetChild(anode,1));
        PRGNode(result)^.child2^.parent:=result;
      end
      else if lcnt>2 then
{$ENDIF}
      begin
        PRGNode(result)^.capacity:=lcnt;
        GetMem(PRGNode(result)^.child,lcnt*SizeOf(TRGNode));

        for i:=0 to lcnt-1 do
        begin
          PRGNode(result)^.child^[i]:=CloneNode(GetChild(anode,i));
          PRGNode(result)^.child^[i]^.parent:=result;
        end;
      end;
    end;
  end
  else
    result:=nil;
end;
{%ENDREGION Node}

{%REGION Add}
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

function AddQWord(aparent:pointer; aname:PWideChar; aval:QWord):pointer;
begin
  result:=AddNode(aparent, aname, rgQWord, nil);
  if result<>nil then PRGNode(result)^.asQWord:=aval;
end;

function AddBinary(aparent:pointer; aname:PWideChar; aval:UInt32):pointer;
begin
  result:=AddNode(aparent, aname, rgBinary, nil);
  if result<>nil then PRGNode(result)^.len:=aval;
end;

function AddVector(aparent:pointer; aname:PWideChar; var aval; atype:integer):pointer;
begin
  if atype in setVector then
  begin
    result:=AddNode(aparent, aname, atype, nil);
    AsVector(result, aval);
  end
  else
    result:=nil;
end;

function AddCustom(aparent:pointer; aname:PWideChar; aval:PWideChar; atype:PWideChar):pointer;
begin
  result:=AddNode(aparent, aname, rgUnknown, aval);
  if result<>nil then PRGNode(result)^.CustomType:=CopyWide(atype);
end;
{%ENDREGION Add}

{%REGION Set Data}
function AsBool(anode:pointer; aval:ByteBool):ByteBool;
begin
  if GetNodeType(anode)=rgBool then
    PRGNode(anode)^.asBoolean:=aval;

  result:=aval;
end;

function AsInteger(anode:pointer; aval:Int32):Int32;
begin
  if GetNodeType(anode) in [rgInteger,rgUnsigned] then
    PRGNode(anode)^.asInteger:=aval;

  result:=aval;
end;

function AsUnsigned(anode:pointer; aval:UInt32):UInt32;
begin
  if GetNodeType(anode) in [rgInteger,rgUnsigned] then
    PRGNode(anode)^.asUnsigned:=aval;

  result:=aval;
end;

function AsFloat(anode:pointer; aval:single):single;
begin
  if GetNodeType(anode)=rgFloat then
    PRGNode(anode)^.asFloat:=aval;

  result:=aval;
end;

function AsDouble(anode:pointer; aval:double):double;
begin
  if GetNodeType(anode)=rgDouble then
    PRGNode(anode)^.asDouble:=aval;

  result:=aval;
end;

function AsInteger64(anode:pointer; aval:Int64):Int64;
begin
  if GetNodeType(anode)=rgInteger64 then
    PRGNode(anode)^.asInteger64:=aval;

  result:=aval;
end;

function AsString(anode:pointer; aval:PWideChar):PWideChar;
begin
  if GetNodeType(anode) in [rgString,rgTranslate,rgNote] then
    SetStringValue(anode,aval);

  result:=aval;
end;

function AsTranslate(anode:pointer; aval:PWideChar):PWideChar;
begin
  if GetNodeType(anode) in [rgString,rgTranslate,rgNote] then
    SetStringValue(anode,aval);

  result:=aval;
end;

function AsNote(anode:pointer; aval:PWideChar):PWideChar;
begin
  if GetNodeType(anode) in [rgString,rgTranslate,rgNote] then
    SetStringValue(anode,aval);

  result:=aval;
end;

function AsVector(anode:pointer; var aval):PVector;
var
  ltype:integer;
begin
  if (anode<>nil) then
  begin
    ltype:=GetNodeType(anode);
// AddNode makes FillChar already. next actions works with right type anyway
//    FillChar(PRGNode(anode)^.X,SizeOf(TVector4),0);
    if ltype=rgVector2 then
    begin
      PRGNode(anode)^.X:=TVector2(aval).X;
      PRGNode(anode)^.Y:=TVector2(aval).Y;
    end
    else if ltype=rgVector3 then
    begin
      PRGNode(anode)^.X:=TVector3(aval).X;
      PRGNode(anode)^.Y:=TVector3(aval).Y;
      PRGNode(anode)^.Z:=TVector3(aval).Z;
    end
    else if ltype=rgVector4 then
    begin
      PRGNode(anode)^.X:=TVector4(aval).X;
      PRGNode(anode)^.Y:=TVector4(aval).Y;
      PRGNode(anode)^.Z:=TVector4(aval).Z;
      PRGNode(anode)^.W:=TVector4(aval).W;
    end;
    result:=@PRGNode(anode)^.X;
  end
  else
    result:=nil;
end;

function AsQWord(anode:pointer; aval:QWord):QWord;
begin
  if GetNodeType(anode)=rgQWord then
    PRGNode(anode)^.asQWord:=aval;

  result:=aval;
end;
{%ENDREGION Set Data}

{%REGION Get Data}
function AsBool(anode:pointer):ByteBool;
begin
  if GetNodeType(anode)=rgBool then
    result:=PRGNode(anode)^.asBoolean
  else
    result:=false;
end;

function AsInteger(anode:pointer):Int32;
begin
  if GetNodeType(anode) in [rgInteger,rgUnsigned] then
    result:=PRGNode(anode)^.asInteger
  else
    result:=0;
end;

function AsUnsigned(anode:pointer):UInt32;
begin
  if GetNodeType(anode) in [rgInteger,rgUnsigned] then
    result:=PRGNode(anode)^.asUnsigned
  else
    result:=0;
end;

function AsFloat(anode:pointer):single;
begin
  if GetNodeType(anode)=rgFloat then
    result:=PRGNode(anode)^.asFloat
  else
    result:=0;
end;

function AsDouble(anode:pointer):double;
begin
  if GetNodeType(anode)=rgDouble then
    result:=PRGNode(anode)^.asDouble
  else
    result:=0;
end;

function AsInteger64(anode:pointer):Int64;
begin
  if GetNodeType(anode)=rgInteger64 then
    result:=PRGNode(anode)^.asInteger64
  else
    result:=0;
end;

function AsString(anode:pointer):PWideChar;
begin
  if GetNodeType(anode) in [rgString,rgTranslate,rgNote] then
    result:=GetStringValue(anode)
  else
    result:=nil;
end;

function AsTranslate(anode:pointer):PWideChar;
begin
  if GetNodeType(anode) in [rgString,rgTranslate,rgNote] then
    result:=GetStringValue(anode)
  else
    result:=nil;
end;

function AsNote(anode:pointer):PWideChar;
begin
  if GetNodeType(anode) in [rgString,rgTranslate,rgNote] then
    result:=GetStringValue(anode)
  else
    result:=nil;
end;

function AsVector(anode:pointer):PVector;
begin
  if GetNodeType(anode) in [rgVector2,rgVector3,rgVector4] then
    result:=@PRGNode(anode)^.X
  else
    result:=nil;
end;

function AsQWord(anode:pointer):QWord;
begin
  if GetNodeType(anode)=rgQWord then
    result:=PRGNode(anode)^.asQWord
  else
    result:=0;
end;
{%ENDREGION Get Data}

end.
