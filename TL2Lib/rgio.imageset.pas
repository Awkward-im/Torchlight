unit RGIO.ImageSet;

interface

uses
  Classes,
  rgglobal;

function ParseImageSetMem   (abuf:pByte; asize:integer):pointer;
function ParseImageSetStream(astream:TStream; fname:PUnicodeChar=nil):pointer;
function ParseImageSetFile  (const afname:string ):pointer;

function BuildImageSetMem   (data:pointer; out   bin    :pByte     ; aver:integer=verTL2):integer;
function BuildImageSetStream(data:pointer;       astream:TStream   ; aver:integer=verTL2):integer;
function BuildImageSetFile  (data:pointer; const fname  :AnsiString; aver:integer=verTL2):integer;


implementation

uses
  SysUtils,
  dom,xmlread,
  rwmemory,

  dict,
  logging,
  rgdict,

  rgstream,
  rgio.dat,
  rgio.text,
  rgnode;


procedure ReadXMLText(out ADoc: TXMLDocument; const astr:AnsiString);
var
  lin:TXMLInputSource;
  adom:TDOMParser;
begin
  lin  := TXMLInputSource.Create(astr);
  adom := TDOMParser.Create;
  try
    adom.Parse(lin, ADoc);
  finally
    adom.Free;
    lin.Free;
  end;
end;

{
  XML: <?xml version="1.0" encoding="UTF-8"?> and AutoScaled="true"	ignoring in DAT
  DAT: <STRING>VIDEO_FILE: and <STRING>VIDEO_BLEND: ignore in XML
}
function ParseImageSetXML(const astr:AnsiString):pointer;
var
  lcount,limage:pointer;
  lpic:TDomNode;
  Doc: TXMLDocument;
  Child: TDOMNode;
  buf:array [0..31] of WideChar;
  i,lwidth,lheight:integer;
begin
  ReadXMLText(Doc,astr);
  result:=nil;
  try
    lpic:=Doc.DocumentElement.Attributes.GetNamedItem('Name');
    if lpic<>nil then
      result:=AddGroup(nil,PWideChar(lpic.NodeValue))
    else
      result:=AddGroup(nil,nil);

    lpic:=Doc.DocumentElement.Attributes.GetNamedItem('Imagefile');
    if lpic<>nil then
      AddString(result,'FILE',PWideChar(lpic.NodeValue))
    else
    begin
      DeleteNode(result);
      exit(nil);
    end;
    lpic:=Doc.DocumentElement.Attributes.GetNamedItem('NativeHorzRes');
    if lpic<>nil then
      Val(lpic.NodeValue,lwidth)
    else
      lwidth:=0;
    lpic:=Doc.DocumentElement.Attributes.GetNamedItem('NativeVertRes');
    if lpic<>nil then
      Val(lpic.NodeValue,lheight)
    else
      lheight:=0;
{    //!!!!
    if lheight>lwidth then
      AddInteger(result,'SIZE',lheight)
    else
}      AddInteger(result,'SIZE',lwidth);

    lcount:=AddInteger(result,'COUNT',0);
    if Doc.DocumentElement.ChildNodes.Count>0 then
    begin
      Child:=Doc.DocumentElement.FirstChild;
      if Child=nil then exit;

      i:=0;
      buf:='IMAGE';
      while Assigned(Child) do
      begin
        RGIntToStr(@buf[5],i);
        limage:=AddGroup(result,@buf);
        AddString (limage,'NAME'  ,           PWideChar(Child.Attributes.Item[0].NodeValue));
        AddInteger(limage,'X'     ,RGStrToInt(PWideChar(Child.Attributes.Item[1].NodeValue)));
        AddInteger(limage,'Y'     ,RGStrToInt(PWideChar(Child.Attributes.Item[2].NodeValue)));
        AddInteger(limage,'WIDTH' ,RGStrToInt(PWideChar(Child.Attributes.Item[3].NodeValue)));
        AddInteger(limage,'HEIGHT',RGStrToInt(PWideChar(Child.Attributes.Item[4].NodeValue)));
        Child:=Child.NextSibling;
        inc(i);
      end;
      if i>0 then AsInteger(lcount,i);
    end;

  finally
    Doc.Free;
  end;
end;

function ParseImageSetMem(abuf:pByte; asize:integer):pointer;
var
  pc:PWideChar;
  lpc:PAnsiChar;
  ls:string;
begin
  lpc:=PAnsiChar(abuf);
  if (PDword(abuf)^ and $00FFFFFF)=SIGN_UTF8 then inc(lpc,3);
  if lpc^='<' then
  begin
    SetString(ls,lpc,asize);
    result:=ParseImageSetXML(ls);
  end
  else
  begin
    pc:=PWideChar(abuf);
    if ORD(pc^)=SIGN_UNICODE then inc(pc);
    if pc^='[' then
      WideToNode(PWideChar(abuf),asize,result)
    else
      result:=ParseDatMem(abuf);
  end;
end;

function ParseImageSetStream(astream:TStream; fname:PUnicodeChar=nil):pointer;
var
  lbuf:PByte;
begin
  if (astream is TMemoryStream) then
  begin
    result:=ParseImageSetMem(TMemoryStream(astream).Memory,astream.Size);
  end
  else
  begin
    GetMem(lbuf,astream.Size);
    aStream.Read(lbuf^,astream.Size);
    result:=ParseImageSetMem(lbuf,astream.Size);
    FreeMem(lbuf);
  end;
end;

function ParseImageSetFile(const afname:string):pointer;
var
  f:file of byte;
  p:PWideChar;
  lbuf:PByte;
  lsize:integer;
begin
  result:=nil;
  Assign(f,afname);
  Reset(f);
  if IOResult=0 then
  begin
    lsize:=FileSize(f);
    if lsize>0 then
    begin
      GetMem(lbuf,lsize+2);
      BlockRead(f,lbuf^,lsize);
      lbuf[lsize  ]:=0;
      lbuf[lsize+1]:=0;
      RGLog.Reserve('Processing '+afname);
      result:=ParseImageSetMem(lbuf,lsize{PUnicodeChar(UnicodeString(afname))});
      if result<>nil then
      begin
        if GetNodeName(result)=nil then
        begin
          p:=FastStrToWide(UpCase(ExtractNameOnly(afname)));
          SetNodeName(result,p);
          FreeMem(p);
        end;
      end;
      FreeMem(lbuf);
    end;
    Close(f);
  end;
end;

function BuildImageSetMem(data:pointer; out bin:pByte; aver:integer=verTL2):integer;
var
  pp,p:pointer;
  ldata,ltmp:string;
  pc:PWideChar;
  i,j,x,y,w,h:integer;
begin
  if ABS(aver) in [verTL1,verTL2] then
  begin
    pp:=FindNode(data,'FILE'); ldata:=WideToStr(AsString(pp));
    pp:=FindNode(data,'SIZE'); ltmp :=IntToStr(AsInteger(pp));
    
    ldata:=
      '<?xml version="1.0" encoding="UTF-8"?>'+
      '<Imageset'+
      ' Name="'          +WideToStr(GetNodeName(data))+
      '" Imagefile="'    +ldata+
      '" NativeHorzRez="'+ltmp+ // 1024 even for 512
      '" NativeVertRez="'+ltmp+ // 768 even for 512
      '" AutoScaled="true">'#13#10; //??

    for i:=0 to GetChildCount(data)-1 do
    begin
      pp:=GetChild(data,i);
      if GetNodeType(pp)=rgGroup then
      begin
        x:=0;
        y:=0;
        w:=0;
        h:=0;
        ltmp:='';
        for j:=0 to GetChildCount(pp)-1 do
        begin
          p :=GetChild(pp,j);
          pc:=GetNodeName(p);
          if      CompareWide(pc,'NAME'  )=0 then ltmp:=WideToStr(AsString(p))
          else if CompareWide(pc,'X'     )=0 then x:=AsInteger(p)
          else if CompareWide(pc,'Y'     )=0 then y:=AsInteger(p)
          else if CompareWide(pc,'WIDTH' )=0 then w:=AsInteger(p)
          else if CompareWide(pc,'HEIGHT')=0 then h:=AsInteger(p);
        end;

        ldata:=ldata+
          '	<Image Name="'+ltmp+
          '" XPos="'  +IntToStr(x)+
          '" YPos="'  +IntToStr(y)+
          '" Width="' +IntToStr(w)+
          '" Height="'+IntToStr(h)+
          '" /?>'#13#10;
      end;
    end;
    ldata:=ldata+'</Imageset>'#13#10;
    result:=Length(ldata)+1;
    GetMem(bin,result);
    move(PAnsiChar(ldata)^,bin^,result);
  end
  else
  begin
    bin:=nil;
    NodeToWide(data,PWideChar(bin));
    result:=(Length(PWideChar(bin))+1)*SizeOf(WideChar);
  end;

end;

function BuildImageSetStream(data:pointer; astream:TStream; aver:integer=verTL2):integer;
var
  lp:PByte;
begin
  lp:=nil;
  result:=BuildImageSetMem(data,lp,aver);
  if result>0 then astream.Write(lp,result);
  FreeMem(lp);
end;

function BuildImageSetFile(data:pointer; const fname:AnsiString; aver:integer=verTL2):integer;
var
  ls:TMemoryStream;
begin
  ls:=TMemoryStream.Create;
  try
    result:=BuildImageSetStream(data,ls,aver);
    ls.SaveToFile(fname);
  finally
    ls.Free;
  end;
end;

end.
