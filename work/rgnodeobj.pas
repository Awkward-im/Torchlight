{%TODO group and value are separate. then value can be save directly and group only by pointers}
unit RGNodeObj;

interface

uses
  rgglobal;

type
  PRGNode = ^TRGNode;
  TRGNode = object
  private
    type
      TRGValue = record
        name  : PWideChar;
        parent: PRGNode; // really needs just for deleting
        case nodetype:integer of
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

  private
    type
      PARGNode = ^TARGNode;
      TARGNode = array [0..MAXINT div SizeOf(pointer)-1] of PRGNode;
  private
    name    : PWideChar;
    parent  : PRGNode; // really needs just for deleting
    values  : array of TRGValue;
    nodes   : array of PRGNode;
    count   : word;
    capacity: word;

  private
    procedure DeleteNodeInt(anode:PRGNode);

    function GetChild(idx:integer):pointer;
    
    procedure SetBool     (aval:ByteBool );
    procedure SetInteger  (aval:Int32    );
    procedure SetUnsigned (aval:UInt32   );
    procedure SetFloat    (aval:single   );
    procedure SetDouble   (aval:double   );
    procedure SetInteger64(aval:Int64    );
    procedure SetString   (aval:PWideChar);

    function GetBool     ():ByteBool;
    function GetInteger  ():Int32;
    function GetUnsigned ():UInt32;
    function GetFloat    ():single;
    function GetDouble   ():double;
    function GetInteger64():Int64;
    function GetString   ():PWideChar;
  public
    procedure Free();

    function GetCustomType():PWideChar;
    function ChangeNode   (aval :PWideChar):ByteBool;
    function AddNode  (aname:PWideChar; atype:integer; atext:PWideChar):pointer;
 
    function Find(apath:PWideChar):pointer;
    function ChildCount():integer;
    function GroupCount(aname:PWideChar=nil):integer;

    function AddGroup    (aname:PWideChar):pointer;
    function AddBool     (aname:PWideChar; aval:ByteBool ):pointer;
    function AddInteger  (aname:PWideChar; aval:Int32    ):pointer;
    function AddFloat    (aname:PWideChar; aval:single   ):pointer;
    function AddDouble   (aname:PWideChar; aval:double   ):pointer;
    function AddInteger64(aname:PWideChar; aval:Int64    ):pointer;
    function AddUnsigned (aname:PWideChar; aval:UInt32   ):pointer;
    function AddString   (aname:PWideChar; aval:PWideChar):pointer;
    function AddTranslate(aname:PWideChar; aval:PWideChar):pointer;
    function AddNote     (aname:PWideChar; aval:PWideChar):pointer;
    // user
{
    function AddBinary   (aname:PWideChar; aval:UInt32   ):pointer;
    function AddByte     (aname:PWideChar; aval:byte     ):pointer;
    function AddWord     (aname:PWideChar; aval:word     ):pointer;
    function AddCustom   (aname:PWideChar; aval:PWideChar; atype:PWideChar):pointer;
}
    property Childs[i:integer]:pointer read GetChild;

    property NodeName   :PWideChar read FName;
    property NodeType   :integer   read FNodetype;
    
    property AsBool     :ByteBool  read GetBool      write SetBool;
    property AsInteger  :Int32     read GetInteger   write SetInteger;
    property AsUnsigned :UInt32    read GetUnsigned  write SetUnsigned;
    property AsFloat    :single    read GetFloat     write SetFloat;
    property AsDouble   :double    read GetDouble    write SetDouble;
    property AsInteger64:Int64     read GetInteger64 write SetInteger64;
    property AsString   :PWideChar read GetString    write SetString;
    property AsTranslate:PWideChar read GetString    write SetString;
    property AsNote     :PWideChar read GetString    write SetString;
{
    property AsCustom   :PWideChar read GetCustom    write SetCustom;
    property AsByte     :Byte      read GetByte      write SetByte;
    property AsWord     :Word      read GetWord      write SetWord;
    property AsBinary   :integer   read GetBinary    write SetBinary;
}
  end;


function CreateTree(aname:PWideChar):pointer;


implementation

//===== Nodes =====

function TRGNode.ChildCount():integer;
begin
  if FNodetype=rgGroup then
    result:=value.count
  else
    result:=0;
end;

function TRGNode.GroupCount(aname:PWideChar=nil):integer;
var
  lp:PRGNode;
  i:integer;
begin
  result:=0;
  if FNodetype=rgGroup then
  begin
    for i:=0 to value.count-1 do
    begin
      lp:=value.child^[i];
      if (lp^.FNodetype=rgGroup) and
         ((aname=nil) or (CompareWide(lp^.FName,aname)=0)) then
        inc(result);
    end;
  end;
end;

function TRGNode.GetChild(idx:integer):pointer;
begin
  if (FNodetype=rgGroup) and
     (idx>=0) and (idx<value.count) then
    result:=value.child^[idx]
  else
    result:=nil
end;

function TRGNode.GetCustomType():PWideChar;
begin
  if FNodetype<>rgUnknown then
    result:=nil
  else
    result:=value.CustomType;
end;

procedure TRGNode.DeleteNodeInt(anode:PRGNode);
var
  i:integer;
begin
  if anode^.FName<>nil then FreeMem(anode^.FName);
  case anode^.FNodetype of
    rgGroup: begin
      for i:=0 to anode^.value.count-1 do
        DeleteNodeInt(anode^.value.child^[i]);
      FreeMem(anode^.value.child);
    end;

    rgString,
    rgTranslate,
    rgUnknown,
    rgNote     : begin
      if anode^.value.asString<>nil then FreeMem(anode^.value.asString);
      if anode^.FNodetype=rgUnknown then
        if anode^.value.CustomType<>nil then FreeMem(anode^.value.customType);
    end;
  end;

  FreeMem(anode);
end;

procedure TRGNode.Free();
var
  lnode:PRGNode;
  lchilds:PARGNode;
  i:integer;
begin

  lnode:=parent;
  if lnode<>nil then
  begin
    lchilds:=lnode^.value.child;
    for i:=0 to lnode^.value.count-1 do
      if lchilds^[i]=@self then
      begin
        dec(lnode^.value.count);
        if i<lnode^.value.count then
          move(lchilds^[i+1],lchilds^[i],(lnode^.value.count-i)*SizeOf(PRGNode));
        break;
      end;
  end;

  DeleteNodeInt(@self);
end;

//----- Adding -----

function TRGNode.ChangeNode(aval:PWideChar):ByteBool;
begin
  result:=true;

  case FNodetype of
    rgInteger  : Val(aval,value.asInteger);
    rgFloat    : Val(aval,value.asFloat);
    rgDouble   : Val(aval,value.asDouble);
    rgInteger64: Val(aval,value.asInteger64);
    rgUnsigned : Val(aval,value.asUnsigned);
    rgString,
    rgTranslate,
    rgUnknown,
    rgNote     : begin
      if value.asString<>nil then FreeMem(value.asString);
      value.asString:=CopyWide(aval);
    end;
    rgBool     : begin
     if (aval<>nil) and (
        ((aval[0]='1') and (aval[1]=#0)) or
         (aval[0] in ['T','t']) and
         (aval[1] in ['R','r']) and
         (aval[2] in ['U','u']) and
         (aval[3] in ['E','e']) and
         (aval[4]=#0)
        ) then value.asBoolean:=true
        else   value.asBoolean:=false;
    end;

    // user
    rgByte     : Val(aval,value.asByte);
    rgWord     : Val(aval,value.asWord);
    rgBinary   : Val(aval,value.len);
  else
    result:=false;
  end;
end;

function TRGNode.AddNode(aname:PWideChar; atype:integer; atext:PWideChar):pointer;
begin
  result:=nil;
  if FNodetype<>rgGroup then exit;

  GetMem(result,SizeOf(TRGNode));

  FillChar(PRGNode(result)^,SizeOf(TRGNode),#0);
  PRGNode(result)^.FName    :=CopyWide(aname);
  PRGNode(result)^.FNodetype:=atype;
  if (atext<>nil) and (atex^<>#0) then
    PRGNode(result)^.ChangeNode(atext);

  PRGNode(result)^.parent:=@self;

  if value.count=value.capacity then
  begin
    inc(value.capacity,4);
    ReallocMem(value.child,value.capacity*SizeOf(PRGNode));
  end;
  value.child^[value.count]:=result;
  inc(value.count);

end;

function TRGNode.AddGroup(aname:PWideChar):pointer;
begin
  result:=AddNode(aname, rgGroup, nil);
end;

function TRGNode.AddString(aname:PWideChar; aval:PWideChar):pointer;
begin
  result:=AddNode(aname, rgString, aval);
end;

function TRGNode.AddTranslate(aname:PWideChar; aval:PWideChar):pointer;
begin
  result:=AddNode(aname, rgTranslate, aval);
end;

function TRGNode.AddNote(aname:PWideChar; aval:PWideChar):pointer;
begin
  result:=AddNode(aname, rgNote, aval);
end;

function TRGNode.AddBool(aname:PWideChar; aval:ByteBool):pointer;
begin
  result:=AddNode(aname, rgBool, nil);
  if result<>nil then PRGNode(result)^.asBool:=aval;
end;

function TRGNode.AddInteger(aname:PWideChar; aval:Int32):pointer;
begin
  result:=AddNode(aname, rgInteger, nil);
  if result<>nil then PRGNode(result)^.asInteger:=aval;
end;

function TRGNode.AddFloat(aname:PWideChar; aval:single):pointer;
begin
  result:=AddNode(aname, rgFloat, nil);
  if result<>nil then PRGNode(result)^.asFloat:=aval;
end;

function TRGNode.AddDouble(aname:PWideChar; aval:double):pointer;
begin
  result:=AddNode(aname, rgDouble, nil);
  if result<>nil then PRGNode(result)^.asDouble:=aval;
end;

function TRGNode.AddInteger64(aname:PWideChar; aval:Int64):pointer;
begin
  result:=AddNode(aname, rgInteger64, nil);
  if result<>nil then PRGNode(result)^.asInteger64:=aval;
end;

function TRGNode.AddUnsigned(aname:PWideChar; aval:UInt32):pointer;
begin
  result:=AddNode(aname, rgUnsigned, nil);
  if result<>nil then PRGNode(result)^.asUnsigned:=aval;
end;

// User types
{
function TRGNode.AddByte(aname:PWideChar; aval:byte):pointer;
begin
  result:=AddNode(aname, rgByte, nil);
  if result<>nil then PRGNode(result)^.asByte:=aval;
end;

function TRGNode.AddWord(aname:PWideChar; aval:word):pointer;
begin
  result:=AddNode(aname, rgWord, nil);
  if result<>nil then PRGNode(result)^.asWord:=aval;
end;

function TRGNode.AddBinary(aname:PWideChar; aval:UInt32):pointer;
begin
  result:=AddNode(aname, rgBinary, nil);
  if result<>nil then PRGNode(result)^.len:=aval;
end;

function TRGNode.AddCustom(aname:PWideChar; aval:PWideChar; atype:PWideChar):pointer;
begin
  result:=AddNode(aname, rgUnknown, aval);
  if result<>nil then PRGNode(result)^.CustomType:=CopyWide(atype);
end;
}
//----- Write data -----

procedure TRGNode.SetBool(aval:ByteBool);
begin
  if FNodetype=rgBool then
    value.asBoolean:=aval;
end;

procedure TRGNode.SetInteger(aval:Int32);
begin
  if FNodetype in [rgInteger,rgUnsigned] then
    value.asInteger:=aval;
end;

procedure TRGNode.SetUnsigned(aval:UInt32);
begin
  if FNodetype in [rgInteger,rgUnsigned] then
    value.asUnsigned:=aval;
end;

procedure TRGNode.SetFloat(aval:single);
begin
  if FNodetype=rgFloat then
    value.asFloat:=aval;
end;

procedure TRGNode.SetDouble(aval:double);
begin
  if FNodetype=rgDouble then
    value.asDouble:=aval;
end;

procedure TRGNode.SetInteger64(aval:Int64);
begin
  if FNodetype=rgInteger64 then
    value.asInteger64:=aval;
end;

procedure TRGNode.SetString(aval:PWideChar);
begin
  if FNodetype in [rgString,rgTranslate,rgNote] then
  begin
    FreeMem(value.asString);
    value.asString:=CopyWide(aval);
  end;
end;

//----- Read data -----

function TRGNode.GetBool():ByteBool;
begin
  if FNodetype=rgBool then
    result:=value.asBoolean
  else
    result:=false;
end;

function TRGNode.GetInteger():Int32;
begin
  if FNodetype in [rgInteger,rgUnsigned] then
    result:=value.asInteger
  else
    result:=0;
end;

function TRGNode.GetUnsigned():UInt32;
begin
  if FNodetype in [rgInteger,rgUnsigned] then
    result:=value.asUnsigned
  else
    result:=0;
end;

function TRGNode.GetFloat():single;
begin
  if FNodetype=rgFloat then
    result:=value.asFloat
  else
    result:=0;
end;

function TRGNode.GetDouble():double;
begin
  if FNodetype=rgDouble then
    result:=value.asDouble
  else
    result:=0;
end;

function TRGNode.GetInteger64():Int64;
begin
  if FNodetype=rgInteger64 then
    result:=value.asInteger64
  else
    result:=0;
end;

function TRGNode.GetString():PWideChar;
begin
  if FNodetype in [rgString,rgTranslate,rgNote] then
    result:=value.asString
  else
    result:=nil;
end;

//----- Search -----

function TRGNode.Find(apath:PWideChar):pointer;
var
  lname:array [0..127] of WideChar;
  lnode,lcnode:PRGNode;
  p1,p2:PWideChar;
  i:integer;
begin
  result:=nil;
  if (apath=nil) or (apath^=#0) then exit;
  if FNodetype<>rgGroup then exit;

  if (CharPosWide('\',apath)=nil) and (CharPosWide('/',apath)=nil) then
  begin
    for i:=0 to value.count-1 do
    begin
      lcnode:=value.child^[i];
      if CompareWide(lcnode^.FName,apath)=0 then
        exit(lcnode);
    end;
  end

  else
  begin
    lnode:=@self;
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
      if lnode^.FNodetype<>rgGroup then exit;
      for i:=0 to lnode^.value.count-1 do
      begin
        lcnode:=lnode^.value.child^[i];
        if (p2^=#0) xor (lcnode^.FNodetype=rgGroup) then
        begin
          if CompareWide(lcnode^.FName,lname)=0 then
          begin
            result:=lcnode;
            break;
          end;
        end
      end;
      if result=nil then exit;

      // 3 - if not "FName" then next cycle
      if p2^<>#0 then
      begin
        inc(p2);
        lnode:=result;
      end;
    end;
  end;
end;


function CreateTree(aname:PWideChar):pointer;
begin
  GetMem(result,SizeOf(TRGNode));

  FillChar(PRGNode(result)^,SizeOf(TRGNode),#0);
  PRGNode(result)^.FName    :=CopyWide(aname);
  PRGNode(result)^.FNodetype:=rgGroup;
end;

end.
