{
  !! WARGING !! rect is X,Y,Width,Height, NOT right, bottom !!
}
{NOTE: texture file have path, but imageset is not}
{TODO: load all imagesets in dir}
{TODO: save imageset dirs too}
{TODO: ParseFromMemory: don't call UseImageFile directly}
{TODO: Save as DAT/XML}
unit RGImageset;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  Imaging, ImagingDds, ImagingNetworkGraphics, ImagingTypes
  ,rgctrl;


type
  TImagesetFile = record
    Name :string;
    Sheet:string;
    Image:TImageData;
  end;

  TImagesetItem = record
    Name  :string;
    XPos,
    YPos,
    Width,
    Height: integer;
    ISFile: integer;
  end;

type

  { TRGImageset }

  TRGImageset = object
  private
    FOutputPath  :string;

    procedure SetOutputPath(const apath:string);
    procedure CheckImageset();
    procedure CheckItem(alen: integer);
    function FillListDAT(astr: PWideChar): boolean;
    function FillListXML(const astr: AnsiString): boolean;

  public
    Imagesets:array of TImagesetFile;
    Items    :array of TImagesetItem;
    ItemCount    :integer;
    ImagesetCount:integer;

    procedure Init;
    procedure Free;
    // source Imageset
    function ParseFromFile  (const aname:string       ):boolean;      // disk file
    function ParseFromMemory(abuf:PByte; asize:integer):boolean;      // memory buffer
    // input picture
    function UseImageset   (                           ais: integer=-1): boolean;  // file from imageset info
    function UseImageFile  (const aname:string       ; ais: integer=-1): boolean;  // disk file
    function UseImageData  (adata:TImageData         ; ais: integer=-1): boolean;  // from Imaging library
    function UseController (actrl:TRGController      ; ais: integer=-1): boolean;  // game archive/PAK
    function UseImageMemory(abuf:PByte; asize:integer; ais: integer=-1): boolean;  // memory buffer
    // sprite info
    function ItemByName(const aname:string):integer;
    function ItemBounds(idx:integer):TRect;

    // single sprite
    function GetSprite(const aname:string ; var asprite:TImageData):boolean;
    function GetSprite(      idx  :integer; var asprite:TImageData):boolean;
    function GetSprite(const aname:string ; astrm:TStream):integer;
    function GetSprite(      idx  :integer; astrm:TStream):integer;
    function GetSprite(const aname:string ; var buf:PByte):integer;
    function GetSprite(      idx  :integer; var buf:PByte):integer;
    // extract to disk
    function ExtractSprite(const aname :string         ):boolean;
    function ExtractSprite(      idx   :integer        ):boolean;
    function ExtractSprite(const anames:array of string):integer;
    function ExtractSprite(      anames:TStrings       ):integer;

    function ExtractAll(aimgset: integer=-1): integer;

    property OutputPath:string read FOutputPath write SetOutputPath;
  end;


implementation

uses
  dom,xmlread,
  rgglobal, rgio.Text, rgstream, rgNode;

{%REGION Extract}
{
function TRGImageset.ExtractRect(const aname:string; arect:TRect):boolean;
var
  lsprite:TImageData;
  ls:string;
begin
  result:=true;

  NewImage(arect.Right,arect.Bottom,
          Image.Format,lsprite);
  CopyRect(Image,
    arect.Left ,arect.Top,
    arect.Right,arect.Bottom,
    lsprite,0,0);

  ls:=FOutputPath+FImagesetName;
  if not DirectoryExists(ls) then
    ForceDirectories(ls);
  SaveImageToFile(ls+'\'+aname+'.png',lsprite);
  FreeImage(lsprite);
end;
}
function TRGImageset.ExtractAll(aimgset:integer=-1):integer;
var
  i,j,llow,lhi:integer;
begin
  result:=0;

  if aimgset<0 then
  begin
    llow:=0;
    lhi :=ImagesetCount-1;
  end
  else
  begin
    llow:=aimgset;
    lhi :=aimgset;
  end;
  for i:=llow to lhi do
  begin
    ForceDirectories(FOutputPath+Imagesets[i].Name);

    for j:=0 to ItemCount-1 do
    begin
      with Items[j] do
        if ISFile=i then
        begin
          if ExtractSprite(j) then inc(result);
//          if ExtractRect(Name, Rect(XPos, YPos, Width, Height)) then inc(result);
        end;
    end;
  end;
end;

function TRGImageset.ExtractSprite(idx:integer):boolean;
var
  lsprite:TImageData;
  ls:string;
begin
  if (idx<0) or (idx>=ItemCount) then exit(false);

  with Items[idx] do
  begin
    NewImage(Width,Height,
             Imagesets[ISFile].Image.Format,lsprite);
    CopyRect(Imagesets[ISFile].Image,
      XPos, YPos, Width, Height,
      lsprite,0,0);

    ls:=FOutputPath+Imagesets[ISFile].Name;
    if not DirectoryExists(ls) then
      ForceDirectories(ls);
    SaveImageToFile(ls+'\'+Name+'.png',lsprite);
  end;
  FreeImage(lsprite);
end;

function TRGImageset.ExtractSprite(const aname:string):boolean;
begin
  result:=ExtractSprite(ItemByName(aname));
end;

function TRGImageset.ExtractSprite(const anames:array of string):integer;
var
  i:integer;
begin
  result:=0;
  for i:=0 to High(anames) do
    if ExtractSprite(anames[i]) then inc(result);
end;

function TRGImageset.ExtractSprite(anames:TStrings):integer;
var
  i:integer;
begin
  result:=0;
  for i:=0 to anames.Count-1 do
    if ExtractSprite(anames[i]) then inc(result);
end;
{%ENDREGION Extract}

procedure TRGImageset.Init;
begin
  FOutputPath:=ExtractPath(ParamStr(0));
end;

procedure TRGImageset.Free;
var
  i:integer;
begin
  for i:=0 to ImagesetCount-1 do
    FreeImage(Imagesets[i].Image);
  SetLength(Imagesets,0);
  SetLength(Items    ,0);
  ImagesetCount:=0;
  ItemCount    :=0;
end;

procedure TRGImageset.SetOutputPath(const apath:string);
begin
  FOutputPath:=apath;
  if not (apath[Length(apath)] in ['\','/']) then
    FOutputPath:=FOutputPath+'/';
end;

{%REGION Imageset}
procedure TRGImageset.CheckImageset();
begin
  inc(ImagesetCount);
  if ImagesetCount>=Length(Imagesets) then
    SetLength(Imagesets,Length(Imagesets)+8);
end;

procedure TRGImageset.CheckItem(alen:integer);
begin
  if (ItemCount+alen)>=Length(Items) then
    SetLength(Items,Align(Length(Items)+alen,16));
end;

function ReadXMLText(out ADoc: TXMLDocument; const astr:AnsiString):boolean;
var
  lin:TXMLInputSource;
  adom:TDOMParser;
begin
  result:=false;
  lin  := TXMLInputSource.Create(astr);
  adom := TDOMParser.Create;
  try
    adom.Parse(lin, ADoc);
  finally
    adom.Free;
    lin.Free;
  end;
  result:=true;
end;

//  Name, XPos, YPos, Width, Height
function TRGImageset.FillListXML(const astr:AnsiString):boolean;
var
  lpic:TDomNode;
  Doc: TXMLDocument;
  Child: TDOMNode;
begin
  result:=ReadXMLText(Doc,astr);
  if result then
  begin
    CheckImageset();
    try
      lpic:=Doc.DocumentElement.Attributes.GetNamedItem('Name');
      if lpic<>nil then Imagesets[ImagesetCount-1].Name:=AnsiString(lpic.NodeValue);

      lpic:=Doc.DocumentElement.Attributes.GetNamedItem('Imagefile');
      if lpic=nil then exit;

      Imagesets[ImagesetCount-1].Sheet:=AnsiString(lpic.NodeValue);
      if Doc.DocumentElement.ChildNodes.Count>0 then
      begin
        Child:=Doc.DocumentElement.FirstChild;
        if Child=nil then exit;

        CheckItem(Doc.DocumentElement.ChildNodes.Count);

        while Assigned(Child) do
        begin
          if CompareWideI(PWideChar(Child.NodeName),'Image')=0 then
          begin
            Items[ItemCount].Name:=AnsiString(Child.Attributes.Item[0].NodeValue);
            Items[ItemCount].ISFile:=ImagesetCount-1;
            Val(Child.Attributes.Item[1].NodeValue,Items[ItemCount].XPos);
            Val(Child.Attributes.Item[2].NodeValue,Items[ItemCount].YPos);
            Val(Child.Attributes.Item[3].NodeValue,Items[ItemCount].Width);
            Val(Child.Attributes.Item[4].NodeValue,Items[ItemCount].Height);
            inc(ItemCount);
          end;
          Child:=Child.NextSibling;
        end;
      end;

    finally
      Doc.Free;
    end;
  end;
end;

function TRGImageset.FillListDAT(astr:PWideChar):boolean;
var
  lnode,lchild,larg:pointer;
  lname,pc:PWideChar;
  i,j:integer;
  lx,ly,lwidth,lheight:integer;
begin
  result:=WideToNode(astr,0,lnode)=0;
  if result then
  begin
    CheckImageset();
    Imagesets[ImagesetCount-1].Name:=WideToStr(GetNodeName(lnode));
    // more than needs really
    CheckItem(GetChildCount(lnode));

    for i:=0 to GetChildCount(lnode)-1 do
    begin
      lchild:=GetChild(lnode,i);
      case GetNodeType(lchild) of
        rgString: if CompareWide(GetNodeName(lchild),'FILE')=0 then
          Imagesets[ImagesetCount-1].Sheet:=WideToStr(AsString(lchild));
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
            Items[ItemCount].Name  :=FastWideToStr(lname);
            Items[ItemCount].ISFile:=ImagesetCount-1;
            Items[ItemCount].XPos  :=lx;
            Items[ItemCount].YPos  :=ly;
            Items[ItemCount].Width :=lwidth;
            Items[ItemCount].Height:=lheight;
            inc(ItemCount);
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
{
  FImageName   :='';
  FImagesetName:='';

  FreeImage(Image);
}
  lpc:=PAnsiChar(abuf);
  if (PDword(abuf)^ and $00FFFFFF)=SIGN_UTF8 then inc(lpc,3);
  if lpc^='<' then
  begin
    SetString(ls,lpc,asize);
    result:=FillListXML(ls);
  end
  else
  begin
    pc:=PWideChar(abuf);
    if ORD(pc^)=SIGN_UNICODE then inc(pc);
    if pc^='[' then
    begin
      result:=FillListDAT(pc);
    end;
  end;

  if result then
  begin
    if Imagesets[ImagesetCount-1].Name='' then
       Imagesets[ImagesetCount-1].Name:='imagesets';

    UseImageFile(Imagesets[ImagesetCount-1].Sheet);
  end;
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
      lbuf[lsize  ]:=0;
      lbuf[lsize+1]:=0;
      result:=ParseFromMemory(lbuf,lsize);
      FreeMem(lbuf);
    end;
    CloseFile(f);
  end;
end;
{%ENDREGION Imageset}

{%REGION Image}
{$I-}
function TRGImageset.UseImageFile(const aname:string; ais:integer=-1):boolean;
var
  f:file of byte;
  lbuf:PByte;
  lext,lname:string;
  lsize:integer;
begin
  result:=false;
  AssignFile(f,aname);
  Reset(f);
  lname:='';
  if IOResult<>0 then
  begin
    lname:=ExtractName(aname);
    AssignFile(f,lname);
    Reset(f);
    if IOResult<>0 then
    begin
      lext:=ExtractExt(aname);
           if lext='.DDS' then lext:='.PNG'
      else if lext='.PNG' then lext:='.DDS'
      else exit;
      AssignFile(f,ChangeFileExt(aname,lext));
      Reset(f);
      if IOResult<>0 then
      begin
        AssignFile(f,ChangeFileExt(lname,lext));
        Reset(f);
      end;
    end;
  end;
  if IOResult=0 then
  begin
    lsize:=FileSize(f);
    GetMem(lbuf,lsize);
    BlockRead(f,lbuf^,lsize);
    CloseFile(f);
    result:=UseImageMemory(lbuf,lsize,ais);
    FreeMem(lbuf);
  end;
end;

function TRGImageset.UseImageMemory(abuf:PByte; asize:integer; ais:integer=-1):boolean;
begin
  if ais<0 then ais:=ImagesetCount-1; if ais<0 then exit;
  FreeImage(Imagesets[ais].Image);
  LoadImageFromMemory(abuf,asize,Imagesets[ais].Image);
  result:=UseImageset();
end;

function TRGImageset.UseImageset(ais:integer=-1):boolean;
begin
  if ais<0 then ais:=ImagesetCount-1; if ais<0 then exit;
  with Imagesets[ais].Image do
    result:=(Width>0) and (Height>0) and (Bits<>nil);
end;

function TRGImageset.UseImageData(adata:TImageData; ais:integer=-1):boolean;
begin
  if ais<0 then ais:=ImagesetCount-1; if ais<0 then exit;
  FreeImage(Imagesets[ais].Image);
  result:=CloneImage(adata, Imagesets[ais].Image);
end;

function TRGImageset.UseController(actrl:TRGController; ais:integer=-1):boolean;
var
  lbuf:PByte;
  lfile,lsize:integer;
begin
  result:=false;
  if ais<0 then ais:=ImagesetCount-1; if ais<0 then exit;
  lfile:=actrl.SearchFile(Imagesets[ais].Sheet);
  if lfile>=0 then
  begin
    lbuf:=nil;
    lsize:=actrl.GetSource(lfile,lbuf);
    result:=UseImageMemory(lbuf,lsize,ais);
    FreeMem(lbuf);
  end
end;
{%ENDREGION Image}

{%REGION Info}
function TRGImageset.ItemByName(const aname:string):integer;
var
  i:integer;
begin
  if aname<>'' then
    for i:=0 to ItemCount-1 do
      if Items[i].Name=aname then exit(i);

  result:=-1;
end;

function TRGImageset.ItemBounds(idx:integer):TRect;
begin
  if (idx>=0) and (idx<ItemCount) then
    result:=Rect(
        Items[idx].XPos ,Items[idx].YPos,
        Items[idx].Width,Items[idx].Height)
  else
    result:=Rect(0,0,0,0);
end;
{%ENDREGION Info}

{%REGION Sprite}
function TRGImageset.GetSprite(idx:integer; var asprite:TImageData):boolean;
begin
  if (idx>=0) and (idx<ItemCount) then
  begin
    with Items[idx] do
    begin
      NewImage(Width,Height,
               Imagesets[ISFile].Image.Format,asprite);
      CopyRect(Imagesets[ISFile].Image,
        XPos, YPos, Width, Height,
        asprite,0,0);
    end;

    result:=true;
  end
  else
    result:=false;
end;

function TRGImageset.GetSprite(const aname:string; var asprite:TImageData):boolean;
begin
  result:=GetSprite(ItemByName(aname),asprite);
end;

function TRGImageset.GetSprite(idx:integer; astrm:TStream):integer;
var
  lsprite:TImageData;
  lpos:integer;
begin
  result:=0;

  if GetSPrite(idx,lsprite) then
  begin
    lpos:=astrm.Position;
    SaveImageToStream('.png',astrm,lsprite);
    result:=astrm.Position-lpos;
  end;

  FreeImage(lsprite);
end;

function TRGImageset.GetSprite(const aname:string; astrm:TStream):integer;
begin
  result:=GetSprite(ItemByName(aname),astrm);
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
  result:=GetSprite(ItemByName(aname),buf);
end;

{%ENDREGION Sprite}

end.
