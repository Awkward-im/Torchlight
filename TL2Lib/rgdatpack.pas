unit RGDatPack;

interface

uses rgglobal;

function DoBinFromMemory(      data :pointer   ; out bin:pByte; aver:byte=verTL2; dictidx:integer=-1):integer;
function DoBinFromFile  (const fname:AnsiString; out bin:pByte; aver:byte=verTL2; dictidx:integer=-1):integer;


implementation

uses
  classes,
  rgnode,
  rgdict;

procedure DoWriteBlock(st:TStream; data:pointer; var adict:TRGDict; aver:byte; var aidx:dword);
var
  lptr:pByte;
  i,cnt,sub,ltype:integer;
  lidx:dword;
begin
  // write name

  if aver=verTL1 then
  begin
    lidx:=adict.Add(aidx,GetNodeName(data));
    if lidx=aidx then inc(aidx);
    st.WriteDWord(lidx);
  end
  else
    st.WriteDWord(RGTags.Hash[GetNodeName(data)]);

  // write properties

  cnt:=GetChildCount(data);
  sub:=GetChildGroupCount(data);

  // count
  st.WriteDWord(cnt-sub);
  for i:=0 to cnt-1 do
  begin
    lptr:=GetChild(data,i);
    ltype:=GetNodeType(lptr);
    if ltype in [rgInteger..rgNote] then
    begin
      // name
      if aver=verTL1 then
      begin
        lidx:=adict.Add(aidx,GetNodeName(lptr));
        if lidx=aidx then inc(aidx);
        st.WriteDWord(lidx);
      end
      else
        st.WriteDWord(RGTags.Hash[GetNodeName(lptr)]);
      // type
      st.WriteDWord(ltype);
      // value
      case ltype of
        rgInteger  : st.WriteDWord(dword(AsInteger  (lptr)));
        rgFloat    : st.WriteDWord(dword(AsFloat    (lptr)));
        rgDouble   : st.WriteQWord(qword(AsDouble   (lptr)));
        rgUnsigned : st.WriteDWord(      AsUnsigned (lptr));
        rgInteger64: st.WriteQWord(qword(AsInteger64(lptr)));
        rgBool     : if AsBool(lptr) then st.WriteDWord(1) else st.WriteDWord(0);

        rgString   : begin
          lidx:=adict.Add(aidx,AsString(lptr));
          if lidx=aidx then inc(aidx);
          st.WriteDWord(lidx);
        end;
        rgNote     : begin
          lidx:=adict.Add(aidx,AsNote(lptr));
          if lidx=aidx then inc(aidx);
          st.WriteDWord(lidx);
        end;
        rgTranslate: begin
          lidx:=adict.Add(aidx,AsTranslate(lptr));
          if lidx=aidx then inc(aidx);
          st.WriteDWord(lidx);
        end;
      end;
    end;
  end;

  // write children

  st.WriteDWord(word(sub));
  if sub>0 then
    for i:=0 to cnt-1 do
    begin
      lptr:=GetChild(data,i);
      if GetNodeType(lptr)=rgGroup then
      begin
        DoWriteBlock(st,lptr,adict,aver,aidx);
        dec(sub);
        if sub=0 then break;
      end;
    end;

end;

function DoBinFromMemory(data:pointer; out bin:pByte; aver:byte=verTL2; dictidx:integer=-1):integer;
var
  st,stm:TMemoryStream;
  p:PWideChar;
  a:UTF8String;
  ldict:TRGDict;
  i,j:integer;
  lidx:dword;
begin
  result:=0;

  // write output
  st:=TMemoryStream.Create();

  case ABS(aver) of
    verTL1: st.WriteDWord(1);
    verTL2: st.WriteDWord(2);
    verHob,
    verRG : st.WriteByte(6);
  else
    st.Free;
    exit;
  end;

  // create text list
  ldict.Init;
  ldict.Options:=[check_text];

  // write block to temporal buffer
  stm:=TMemoryStream.Create();
  lidx:=dword(dictidx);
  DoWriteBlock(stm,data,ldict,aver,lidx);

  // write list
  a:=Default(UTF8String);
  st.WriteDword(ldict.Count);
  for i:=0 to ldict.Count-1 do
  begin
    st.WriteDWord(ldict.IdxHash[i]);
    p:=ldict.IdxTag[i];
    j:=Length(p);
    case ABS(aver) of
      verTL1: begin
        st.WriteDWord(j);
        st.Write(p^,j*SizeOf(WideChar));
      end;
      verTL2: begin
        st.WriteWord(j);
        st.Write(p^,j*SizeOf(WideChar));
      end;
      verHob,
      verRG : begin
        if Length(a)<(j*3) then SetLength(a,j*3);
        j:=UnicodeToUtf8(PChar(a),Length(a)+1,p,j);
        st.WriteWord(j);
        st.Write(PChar(a)^,j);
      end;
    end;
  end;
  ldict.Clear;

  // write data
  stm.Position:=0;
  st.CopyFrom(stm,stm.Size);
  stm.Free;

  result:=st.Size;
  GetMem(bin,result);
  move(st.Memory^,bin^,result);

  st.Free;
end;

function DoBinFromFile(const fname:AnsiString; out bin:pByte; aver:byte=verTL2; dictidx:integer=-1):integer;
var
  p:pByte;
begin
  p:=ParseDatFile(PChar(fname));
  if p<>nil then
  begin
    result:=DoBinFromMemory(p,bin,aver,dictidx);

    DeleteNode(p);
  end;
end;

end.
