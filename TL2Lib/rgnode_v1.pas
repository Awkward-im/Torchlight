{NOTE: don't do it (node extract harder, global structure needs) separate node -> array of nodes like rgfs. pointer -> index}
{TODO: make variant of node with arrays of nodes for non-cutting actions}
{TODO: Add code to keep up to 2 childs inside fields, not array}
{TODO: Add UTF8Text field with one-time conversion on request}
{TODO: Add QWord type}
{TODO: Keep all numeric as Int64}
{TODO: Rename As* method to Get*/Set*}
{TODO: make Vector2, Vector3 and Vector 4 values too}
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

function  CloneNode   (anode:pointer):pointer;
procedure DeleteNode  (anode:pointer);
function  CutNode     (anode:pointer):pointer;

function GetGroupCount(anode:pointer; aname:PWideChar=nil):integer;
function GetChildCount(anode:pointer):integer;
function GetChild     (anode:pointer; idx:integer):pointer;
function GetNodeType  (anode:pointer):integer;
function GetNodeName  (anode:pointer):PWideChar;
function GetNodeParent(anode:pointer):pointer;
function GetCustomType(anode:pointer):PWideChar;

function IsNodeName   (anode:pointer; ahash:dword    ):boolean;
function IsNodeName   (anode:pointer; aname:PWideChar):boolean;
function FindNode     (anode:pointer; apath:PWideChar):pointer;
function SetNodeValue (anode:pointer; aval :PWideChar; alen:integer=0):ByteBool;
function SetNodeName  (anode:pointer; aname:PWideChar):boolean;

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
function AsVector   (anode:pointer; var aval):integer;

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
  rgdict;

const
  CapacityStep = 10;

const
  setNumeric = [rgInteger, rgUnsigned , rgInteger64];
  setText    = [rgString , rgTranslate, rgNote];
  setVector  = [rgVector2, rgVector3  , rgVector4];

type
  PARGNode = ^TARGNode;
  PRGNode = ^TRGNode;
  TRGNode = record
    name  : PWideChar;
    parent: PRGNode; // really needs just for deleting
    hash  : dword;
    case nodetype:integer of
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
      rgVector2,
      rgVector3,
      rgVector4  : (
        X:Single;
        Y:Single;
        Z:Single;
        W:Single;
      );
      // user
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
  lhash:dword;
  i:integer;
begin
  result:=0;
  lhash:=0;
  if (anode<>nil) and (PRGNode(anode)^.nodetype=rgGroup) then
  begin
    if (aname<>nil) and (aname^<>#0) then lhash:=RGHash(aname);
    for i:=0 to PRGNode(anode)^.count-1 do
    begin
      lp:=PRGNode(anode)^.child^[i];
      if (lp^.nodetype=rgGroup) and
         ((aname=nil) or (lp^.hash=lhash)) then
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
  else if PRGNode(anode)^.name<>nil then
    result:=PRGNode(anode)^.name
  else
    result:=RGTags.Tag[PRGNode(anode)^.hash];
end;

function SetNodeName(anode:pointer; aname:PWideChar):boolean;
begin
  if anode=nil then
    result:=false
  else
  begin
    if PRGNode(anode)^.name<>nil then FreeMem(PRGNode(anode)^.name);
    PRGNode(anode)^.name:=nil;
    PRGNode(anode)^.hash:=0;

    if (aname<>nil) and (aname^<>#0) then
    begin
      if IsNumber(aname) then
        Val(aname,PRGNode(anode)^.hash)
      else
        PRGNode(anode)^.hash:=RGHash(aname);

      if not RGTags.Exists(PRGNode(anode)^.hash) then
        CopyWide(PRGNode(anode)^.name,aname)
      else
    end;
    result:=true;
  end;
end;

function GetCustomType(anode:pointer):PWideChar;
begin
  if (anode=nil) or (PRGNode(anode)^.nodetype<>rgUnknown) then
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
    while not (aval^ in ['+','-','.','0'..'9']) do inc(aval);
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

      case PRGNode(anode)^.nodetype of
        rgInteger  : Val(lp,PRGNode(anode)^.asInteger);
        rgFloat    : Val(lp,PRGNode(anode)^.asFloat);
        rgDouble   : Val(lp,PRGNode(anode)^.asDouble);
        rgInteger64: Val(lp,PRGNode(anode)^.asInteger64);
        rgUnsigned : Val(lp,PRGNode(anode)^.asUnsigned);
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
        rgByte     : Val(lp,PRGNode(anode)^.asByte);
        rgWord     : Val(lp,PRGNode(anode)^.asWord);
        rgBinary   : Val(lp,PRGNode(anode)^.len);
      else
        result:=false;
      end;
    end;
  end;
end;

function CutNode(anode:pointer):pointer;
var
  lnode:PRGNode;
  lchilds:PARGNode;
  i:integer;
begin
  result:=anode;
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
    PRGNode(anode)^.parent:=nil;
  end;
end;

procedure FreeNode(anode:pointer);
var
  i:integer;
begin
  if PRGNode(anode)^.name<>nil then FreeMem(PRGNode(anode)^.name);

  case PRGNode(anode)^.nodetype of
    rgGroup: begin
      for i:=0 to PRGNode(anode)^.count-1 do
        FreeNode(PRGNode(anode)^.child^[i]);
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

//----- Adding -----

function AddNode(aparent:pointer; anode:pointer):pointer;
begin
  result:=anode;
  if anode=nil then exit;

  if aparent<>nil then
  begin
    PRGNode(result)^.parent:=aparent;
    with PRGNode(aparent)^ do
    begin
      if count=capacity then
      begin
        inc(capacity,CapacityStep);
        ReallocMem(child,capacity*SizeOf(PRGNode));
      end;
      child^[count]:=result;
      inc(count);
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
  PRGNode(result)^.nodetype:=atype;
  if (atext<>nil) and (atext^<>#0) then SetNodeValue(result,atext,alen);
  if (aname<>nil) and (aname^<>#0) then SetNodeName (result,aname);

  AddNode(aparent, result);
end;

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

function AsVector(anode:pointer; var aval):integer;
begin
  if (anode<>nil) then
  begin
    if PRGNode(anode)^.nodetype=rgVector2 then
    begin
      PRGNode(anode)^.X:=TVector2(aval).X;
      PRGNode(anode)^.Y:=TVector2(aval).Y;
    end
    else if PRGNode(anode)^.nodetype=rgVector3 then
    begin
      PRGNode(anode)^.X:=TVector3(aval).X;
      PRGNode(anode)^.Y:=TVector3(aval).Y;
      PRGNode(anode)^.Z:=TVector3(aval).Z;
    end
    else if PRGNode(anode)^.nodetype=rgVector4 then
    begin
      PRGNode(anode)^.X:=TVector4(aval).X;
      PRGNode(anode)^.Y:=TVector4(aval).Y;
      PRGNode(anode)^.Z:=TVector4(aval).Z;
      PRGNode(anode)^.W:=TVector4(aval).W;
    end
  end;

  result:=PRGNode(anode)^.nodetype;
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

function AsVector(anode:pointer):PVector;
begin
  if (anode<>nil) and
     (PRGNode(anode)^.nodetype in [rgVector2,rgVector3,rgVector4]) then
    result:=@PRGNode(anode)^.X
  else
    result:=nil;
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
  if (anode=nil) then exit;
  if (apath=nil) or (apath^=#0) then exit(anode);
  if PRGNode(anode)^.nodetype<>rgGroup then exit;

  if (CharPosWide('\',apath)=nil) and (CharPosWide('/',apath)=nil) then
  begin
    lhash:=RGHash(apath);
    for i:=0 to PRGNode(anode)^.count-1 do
    begin
      lcnode:=PRGNode(anode)^.child^[i];
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
      if lnode^.nodetype<>rgGroup then exit;
      for i:=0 to lnode^.count-1 do
      begin
        lcnode:=lnode^.child^[i];
        if (apath^=#0) xor (lcnode^.nodetype=rgGroup) then
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

function CloneNode(anode:pointer):pointer;
var
  i:integer;
begin
  result:=nil;
  if PRGNode(anode)^.nodetype=rgUnknown then
  else
  begin
    GetMem(result,SizeOf(TRGNode));
    move(PByte(anode)^,PByte(result)^,SizeOf(TRGNode));

    PRGNode(result)^.Name  :=CopyWide(PRGNode(anode)^.Name);
    PRGNode(result)^.parent:=nil;

    case PRGNode(anode)^.nodetype of
      rgUnknown,
      rgString,
      rgTranslate,
      rgNote     : begin
        PRGNode(result)^.asString:=CopyWide(PRGNode(anode)^.asString);
        if PRGNode(anode)^.nodetype=rgUnknown then
          PRGNode(result)^.CustomType:=CopyWide(PRGNode(anode)^.CustomType);
      end;

      rgGroup: begin
        PRGNode(result)^.capacity:=PRGNode(result)^.count;
        GetMem(PRGNode(result)^.child,SizeOf(TRGNode)*PRGNode(result)^.count);
        for i:=0 to PRGNode(anode)^.count-1 do
        begin
          PRGNode(result)^.child^[i]:=CloneNode(PRGNode(anode)^.child^[i]);
          PRGNode(result)^.child^[i]^.parent:=result;
        end;
      end;
    else
    end;
  end;
end;

end.