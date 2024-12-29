{
  !! WARGING !! rect is X,Y,Width,Height, NOT right, bottom !!
}
unit RGImageset;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Graphics,
  Imaging, ImagingDds, ImagingTypes, ImagingComponents,
  rgctrl;


type
  TRGImageset = object
  private
    FOutputPath  :string;
    FImagesetName:string;
    FImageName   :string;
    FImage:TImageData;
    FItems:array of record
      Name  :string;
      XPos,
      YPos,
      Width,
      Height: integer;
    end;

    procedure FillListDAT(astr: PWideChar);
    procedure FillListXML(const astr: AnsiString);

  public
    procedure Init;
    procedure Free;
    // source Imageset
    function ParseFromFile  (const aname:string       ):boolean;     // disk file
    function ParseFromMemory(abuf:PByte; asize:integer):boolean;     // memory buffer
    // input picture
    function UseImageset                         :boolean;           // file from imageset info
    function UseImagePicture(apic:TPicture      ):boolean;           // TPicture class
    function UseImageFile   (const aname:string ):boolean;           // disk file
    function UseImageData   (adata:TImageData   ):boolean;           // from Imaging library
    function UseController  (actrl:TRGController):boolean;           // game archive/PAK
    function UseImageMemory (abuf:PByte; asize:integer):boolean;     // memory buffer
    // output path
    procedure OutputPath(const apath:string);
    // info
    function GetCount():integer;
    function NameByIndex(aidx:integer):string;
    function IndexByName(const aname:string):integer;
    function GetBounds(idx:integer):TRect;

    procedure GetImage(apic:TPicture);
    // single sprite
    function GetSprite(const aname:string ; astrm:TStream):integer;  // by name , to stream
    function GetSprite(      idx  :integer; astrm:TStream):integer;  // by index, to stream
    function GetSprite(const aname:string ; var buf:PByte):integer;  // by name , to memory buffer
    function GetSprite(      idx  :integer; var buf:PByte):integer;  // by index, to memory buffer
    function GetSprite(const aname:string ; apic:TPicture):boolean;  // by name , to TPicture
    function GetSprite(      idx  :integer; apic:TPicture):boolean;  // by index, to TPicture
    function GetSprite(const aname:string                ):boolean;  // by name , to disk file
    function GetSprite(      idx  :integer               ):boolean;  // by index, to disk file
    // list of sprites to unpack. unrealized yet
    function GetSprite(const anames:array of string      ):boolean;  // array of names
    function GetSprite(anames:TStrings                   ):boolean;  // StringList of names
    // extract to disk
    function ExtractRect(const aname:string; arect:TRect ):boolean;
    function Extract:integer;

//    property Image:TImageData read FImage;
    property ImageFile:string  read FImageName;
    property Count:integer read GetCount;
    property Name  [idx:integer ]:string  read NameByIndex;
    property Index [aname:string]:integer read IndexByName;
    property Bounds[idx:integer ]:TRect   read GetBounds;
  end;


implementation

uses
  LCLType,
  dom,xmlreader,xmlread,
  rgglobal, rgio.Text, rgstream, rgNode;

procedure TRGImageset.GetImage(apic:TPicture);
begin
//  if UseImageset then
    ConvertDataToBitmap(FImage,apic.Bitmap);
end;

{%REGION Extract}
function TRGImageset.ExtractRect(const aname:string; arect:TRect):boolean;
var
  lpic:TPicture;
  lsprite:TImageData;
  ls:string;
begin
  result:=true;

  lpic:=TPicture.Create;
  NewImage(arect.Right,arect.Bottom,
          FImage.Format,lsprite);
  CopyRect(FImage,
    arect.Left ,arect.Top,
    arect.Right,arect.Bottom,
    lsprite,0,0);
  ConvertDataToBitmap(lsprite,lpic.Bitmap);
  ls:=FOutputPath+FImagesetName;
  if not DirectoryExists(ls) then
    ForceDirectories(ls);
//        SaveImageToFile(ls+'\'+aname+'.dds',lsprite);
  lpic.SaveToFile(ls+'\'+aname+'.png','.png');
  FreeImage(lsprite);
  lpic.Free;
end;

function TRGImageset.Extract:integer;
var
  i:integer;
begin
  result:=0;

  ForceDirectories(FOutputPath+FImagesetName);

  for i:=0 to High(FItems) do
  begin
    if ExtractRect(Fitems[i].Name, Rect(
        FItems[i].XPos ,FItems[i].YPos,
        FItems[i].Width,FItems[i].Height)) then inc(result);
  end;
end;
{%ENDREGION Extract}

procedure TRGImageset.Init;
begin
  FOutputPath:=ExtractPath(ParamStr(0));
end;

procedure TRGImageset.Free;
begin
  FreeImage(FImage);
end;

procedure TRGImageset.OutputPath(const apath:string);
begin
  FOutputPath:=apath;
  if not (apath[Length(apath)] in ['\','/']) then
    FOutputPath:=FOutputPath+'/';
end;

{%REGION Imageset}
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

//  Name, XPos, YPos, Width, Height
procedure TRGImageset.FillListXML(const astr:AnsiString);
var
  lpic:TDomNode;
  Doc: TXMLDocument;
  Child: TDOMNode;
  i:integer;
begin
  ReadXMLText(Doc,astr);
  try
    lpic:=Doc.DocumentElement.Attributes.GetNamedItem('Name');
    if lpic<>nil then FImagesetName:=lpic.NodeValue;

    lpic:=Doc.DocumentElement.Attributes.GetNamedItem('Imagefile');
    if lpic=nil then exit;

    FImageName:=lpic.NodeValue;
    if Doc.DocumentElement.ChildNodes.Count>0 then
    begin
      Child:=Doc.DocumentElement.FirstChild;
      if Child=nil then exit;

      SetLength(FItems,Doc.DocumentElement.ChildNodes.Count);
      i:=0;
      while Assigned(Child) do
      begin
        FItems[i].Name:=Child.Attributes.Item[0].NodeValue;
        Val(Child.Attributes.Item[1].NodeValue,FItems[i].XPos);
        Val(Child.Attributes.Item[2].NodeValue,FItems[i].YPos);
        Val(Child.Attributes.Item[3].NodeValue,FItems[i].Width);
        Val(Child.Attributes.Item[4].NodeValue,FItems[i].Height);
        Child:=Child.NextSibling;
        inc(i);
      end;
    end;

  finally
    Doc.Free;
  end;
end;

procedure TRGImageset.FillListDAT(astr:PWideChar);
var
  lnode,lchild,larg:pointer;
  lname,pc:PWideChar;
  lcnt,i,j:integer;
  lx,ly,lwidth,lheight:integer;
begin
  if WideToNode(astr,0,lnode)=0 then
  begin
    FImagesetName:=WideToStr(GetNodeName(lnode));
    // more than needs really
    SetLength(FItems,GetChildCount(lnode));
    lcnt:=0;
    for i:=0 to GetChildCount(lnode)-1 do
    begin
      lchild:=GetChild(lnode,i);
      case GetNodeType(lchild) of
        rgString: if CompareWide(GetNodeName(lchild),'FILE')=0 then
          FImageName:=WideToStr(AsString(lchild));
        rgGroup: begin
          lname  :=nil;
          lx     :=0;
          ly     :=0;
          lwidth :=0;
          lheight:=0;
          for j:=0 to GetChildCount(lchild)-1 do
          begin
            larg:=GetChild(lchild,j);
            pc:=GetNodeName(larg);
            if      CompareWide(pc,'NAME'  )=0 then lname  :=AsString (larg)
            else if CompareWide(pc,'X'     )=0 then lx     :=AsInteger(larg)
            else if CompareWide(pc,'Y'     )=0 then ly     :=AsInteger(larg)
            else if CompareWide(pc,'WIDTH' )=0 then lwidth :=AsInteger(larg)
            else if CompareWide(pc,'HEIGHT')=0 then lheight:=AsInteger(larg);
          end;
          if (lname<>nil) and (lwidth>0) and (lheight>0) then
          begin
            FItems[lcnt].Name  :=FastWideToStr(lname);
            FItems[lcnt].XPos  :=lx;
            FItems[lcnt].YPos  :=ly;
            FItems[lcnt].Width :=lwidth;
            FItems[lcnt].Height:=lheight;
            inc(lcnt)
          end;
        end;
      else
      end;
    end;
    DeleteNode(lnode);
  end;
end;

function TRGImageset.ParseFromMemory(abuf:PByte; asize:integer):boolean;
var
  lpc:PAnsiChar;
  pc:PWideChar;
  ls:string;
begin
  result:=false;

  FImageName   :='';
  FImagesetName:='';

  FreeImage(FImage);

  lpc:=PAnsiChar(abuf);
  if (PDword(abuf)^ and $00FFFFFF)=SIGN_UTF8 then inc(lpc,3);
  if lpc^='<' then
  begin
    SetString(ls,lpc,asize);
    FillListXML(ls);
    result:=true;
  end
  else
  begin
    pc:=PWideChar(abuf);
    if ORD(pc^)=SIGN_UNICODE then inc(pc);
    if pc^='[' then
    begin
      FillListDAT(pc);
      result:=true;
    end;
  end;

  if FImagesetName='' then FImagesetName:='imagesets';

  UseImageFile(FImageName);
end;

function TRGImageset.ParseFromFile(const aname:string):boolean;
var
  f:File of byte;
  lbuf:PByte;
  lsize:integer;
begin
  result:=false;

  AssignFile(f,aname);
  Reset(f);
  if IOResult=0 then
  begin
    lsize:=FileSize(f);
    if lsize>0 then
    begin
      GetMem(lbuf,lsize+2);
      BlockRead(f,lbuf^,lsize);
      result:=ParseFromMemory(lbuf,lsize);
      lbuf[lsize  ]:=0;
      lbuf[lsize+1]:=0;
      FreeMem(lbuf);
    end;
    CloseFile(f);
  end;
end;
{%ENDREGION Imageset}

{%REGION Image}
function TRGImageset.UseImagePicture(apic:TPicture):boolean;
begin
  FreeImage(FImage);
  ConvertBitmapToData(apic.Bitmap,FImage);
  result:=UseImageSet();
end;

{$I-}
function TRGImageset.UseImageFile(const aname:string):boolean;
var
  f:file of byte;
  lbuf:PByte;
  lsize:integer;
begin
  result:=false;
  AssignFile(f,aname);
  Reset(f);
  if IOResult<>0 then
  begin
    AssignFile(f,ExtractName(aname));
    Reset(f);
  end;
  if IOResult=0 then
  begin
    lsize:=FileSize(f);
    GetMem(lbuf,lsize);
    BlockRead(f,lbuf^,lsize);
    CloseFile(f);
    result:=UseImageMemory(lbuf,lsize);
    FreeMem(lbuf);
  end;
end;

function TRGImageset.UseImageMemory(abuf:PByte; asize:integer):boolean;
var
  lstr:TMemoryStream;
  lpic:TPicture;
begin
  if (abuf[0]=ORD('D')) and
     (abuf[1]=ORD('D')) and
     (abuf[2]=ORD('S')) then
  begin
    FreeImage(FImage);
    LoadImageFromMemory(abuf,asize,FImage);
  end
  // Use LCL code to load non-DDS formats
  else
  begin
    lstr:=TMemoryStream.Create();
    lpic:=TPicture.Create;
    try
      // PUData cleared in ClearInfo() and/or FormClose;
      lstr.SetBuffer(abuf);
      lpic.LoadFromStream(lstr);
      FreeImage(FImage);
      ConvertBitmapToData(lpic.Bitmap,FImage);
    finally
      lstr.Free;
      lpic.Free;
    end;
  end;
  result:=UseImageset();
end;

function TRGImageset.UseImageset:boolean;
begin
  result:=(FImage.Width>0) and (FImage.Height>0) and (FImage.Bits<>nil);
end;

function TRGImageset.UseImageData(adata:TImageData):boolean;
begin
  FreeImage(FImage);
  result:=CloneImage(adata, FImage);
end;

function TRGImageset.UseController(actrl:TRGController):boolean;
var
  lbuf:PByte;
  lfile,lsize:integer;
begin
  result:=false;
  lfile:=actrl.SearchFile(FImageName);
  if lfile>=0 then
  begin
    lbuf:=nil;
    lsize:=actrl.GetSource(lfile,lbuf);
    result:=UseImageMemory(lbuf,lsize);
    FreeMem(lbuf);
  end
end;
{%ENDREGION Image}

{%REGION Info}
function TRGImageset.GetCount():integer;
begin
  result:=Length(FItems);
end;

function TRGImageset.NameByIndex(aidx:integer):string;
begin
  if (aidx>=0) and (aidx<Length(FItems)) then
    result:=FItems[aidx].Name
  else
    result:='';
end;

function TRGImageset.IndexByName(const aname:string):integer;
var
  i:integer;
begin
  if aname<>'' then
    for i:=0 to High(FItems) do
      if FItems[i].Name=aname then exit(i);

  result:=-1;
end;

function TRGImageset.GetBounds(idx:integer):TRect;
begin
  if (idx>=0) and (idx<Length(FItems)) then
    result:=Rect(
        FItems[idx].XPos ,FItems[idx].YPos,
        FItems[idx].Width,FItems[idx].Height)
  else
    result:=Rect(0,0,0,0);
end;
{%ENDREGION Info}

{%REGION Sprite}
function TRGImageset.GetSprite(idx:integer; apic:TPicture):boolean;
var
  lsprite:TImageData;
begin
  if (idx>=0) and (idx<Length(FItems)) then
  begin
    NewImage(FItems[idx].Width,FItems[idx].Height,
            FImage.Format,lsprite);
    CopyRect(FImage,
      FItems[idx].XPos ,FItems[idx].YPos,
      FItems[idx].Width,FItems[idx].Height,
      lsprite,0,0);
    ConvertDataToBitmap(lsprite,apic.Bitmap);
    FreeImage(lsprite);

    exit(true);
  end;
  result:=false;
end;

function TRGImageset.GetSprite(const aname:string; apic:TPicture):boolean;
begin
  result:=GetSprite(IndexByName(aname),apic);
end;

function TRGImageset.GetSprite(idx:integer; astrm:TStream):integer;
var
  lpic:TPicture;
  lpos:integer;
begin
  result:=0;

  lpic:=TPicture.Create;

  if GetSPrite(idx,lpic) then
  begin
    lpos:=astrm.Position;
    lpic.SaveToStreamWithFileExt(astrm,'.png');
    result:=astrm.Position-lpos;
  end;

  lpic.Free;
end;

function TRGImageset.GetSprite(const aname:string; astrm:TStream):integer;
begin
  result:=GetSprite(IndexByName(aname),astrm);
end;

function TRGImageset.GetSprite(idx:integer; var buf:PByte):integer;
var
  lstrm:TMemoryStream;
begin
  lstrm:=TMemoryStream.Create;
  result:=GetSprite(idx,lstrm);
  if result>0 then
  begin
    if buf<>nil then FreeMem(buf);
    lstrm.CutBuffer(buf);
  end;
  lstrm.Free;
end;

function TRGImageset.GetSprite(const aname:string; var buf:PByte):integer;
begin
  result:=GetSprite(IndexByName(aname),buf);
end;

function TRGImageset.GetSprite(idx:integer):boolean;
begin
  if (idx<0) or (idx>=Length(FItems)) then exit(false);

  result:=ExtractRect(Fitems[idx].Name, Rect(
     FItems[idx].XPos ,FItems[idx].YPos,
     FItems[idx].Width,FItems[idx].Height))
end;

function TRGImageset.GetSprite(const aname:string):boolean;
begin
  result:=GetSprite(IndexByName(aname));
end;

function TRGImageset.GetSprite(const anames:array of string):boolean;
begin
  result:=false;
end;

function TRGImageset.GetSprite(anames:TStrings):boolean;
begin
  result:=false;
end;
{%ENDREGION Sprite}

end.
