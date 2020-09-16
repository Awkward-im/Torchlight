unit rgglobal;

interface

uses
  Classes,
  TL2DatNode;

//--- Constants

const
  verTL1 = 1;
  verTL2 = 2;
  verHob = 3;

//--- Variables

var
  hashlog:TStringList;

var
  curfname:string;

var
  objInfo:PTL2Node;

type
  TDict = array of record
    name:String;
    hash:dword;
  end;
var
  cdict,dict:TDict;

//--- Functions

function CompareWide(s1,s2:PWideChar):boolean;
procedure LoadDict;
procedure LoadDictCustom(var adict:TDict; const fname:string);

procedure LoadObjectInfo;


//----- Implementation

implementation

uses
  SysUtils;

const
  dictname = 'dictionary.txt';
  objname  = 'objects.dat';


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

procedure LoadDictCustom(var adict:TDict; const fname:string);
var
  sl:TStringList;
  ls:UTF8String;
  lns:string[31];
  lcnt,tmpi,i,p:integer;
begin
  // 1 - Load tags

  sl:=TStringList.Create;
//  sl.DefaultEncoding:=TEncoding.UTF8;

  try
    try
      sl.LoadFromFile(fname{,TEncoding.UTF8});
      SetLength(adict,sl.Count);
      lcnt:=0;
      for i:=0 to sl.Count-1 do
      begin
        ls:=sl[i];
        for p:=1 to Length(ls) do
        begin
          if ls[p]<>':' then
            lns[p]:=ls[p]
          else
          begin
            SetLength(lns,p-1);
            if lns[1]='-' then
            begin
              val(lns,tmpi);
              adict[lcnt].hash:=dword(tmpi);
            end
            else
              val(lns,adict[lcnt].hash);
            adict[lcnt].name:=Copy(ls,p+1);
            inc(lcnt);
            break;
          end;
        end;
      end;
      SetLength(adict,lcnt);

    except
      if IsConsole then
      begin
        writeln('Can''t load '+fname);
        if ls<>'' then  writeln('Possible problem with ',ls);
      end;
      adict:=nil;
    end;
  finally
    sl.Free;
  end;
end;

procedure LoadDict;
begin
  LoadDictCustom(dict, dictname);
end;

procedure LoadObjectInfo;
begin
  objInfo:=ParseDatFile(objname);
  if (objInfo=nil) and IsConsole then
    writeln('Can''t load '+objname);
end;

initialization

  dict:=nil;
  cdict:=nil;
  objInfo:=nil;

finalization

  SetLength(dict,0);
  SetLength(cdict,0);
  DeleteNode(objInfo);

end.
