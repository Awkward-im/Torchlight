{
  !! WARGING !! rect is X,Y,Width,Height, NOT right, bottom !!
}
{NOTE: texture file have path, but imageset is not}
{TODO: calc really required items array increment when "deleted" exists}
{TODO: Build: transform absolute path to MEDIA-relative (how?)}
{TODO: RootDir for sheet pathed file search}
{TODO: save imageset dirs too}
unit RGImageSet;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  Imaging, ImagingDds, ImagingNetworkGraphics, ImagingTypes
  ,RGGlobal,RGCtrl;


type
  PImagesetFile = ^TImagesetFile;
  TImagesetFile = record
    Name    :string;      // Imageset name
    Sheet   :string;      // Image name (with relative path usually)
    Image   :TImageData;  // Image data, filled by Use* function
                          // like FImageset.UseImageFile(FImageset.Imagesets[FActiveImageset].Sheet)
    Width   :integer;     // Image width  (can be not real)
    Height  :integer;     // Image height (can be not real)
    id      :integer;     // for case when deleting imageset
    modified:boolean;
  end;

  PImagesetItem = ^TImagesetItem;
  TImagesetItem = record
    Name  :string;
    XPos,
    YPos,
    Width,
    Height:integer;
    ISFile:integer;
  end;

type

  { TRGImageset }

  TRGImageset = object
  private
    FRootPath  :string;
    FOutputPath:string;
    lastid     :integer;
    FDeleted   :integer;
    FDeletedCnt:integer;

    procedure SetPath(aidx:integer; const apath:string);
    procedure CheckItem(alen:integer);
    function  ParseDAT(abuf:PByte; asize:integer):boolean;
    function  ParseXML(abuf:PByte; asize:integer):boolean;

  public
    Imagesets:array of TImagesetFile;
    Items    :array of TImagesetItem;
    ItemCount    :integer;
    ImagesetCount:integer;

    procedure Init;
    procedure Free;
    // source Imageset
    function  ParseFromFile  (const aname:string       ):boolean;      // disk file
    function  ParseFromMemory(abuf:PByte; asize:integer):boolean;      // memory buffer
    function  BuildImageset  (ais:integer; out bin:pByte; aver:integer=verTL2):integer;
    procedure CloseImageset(const aname:string);
    procedure CloseImageset(aidx:integer);
    function  ISbyID(aid:integer):integer;
    function  ISbyName(const aname:string):integer;

    // modify
    function  NewImageset(const aname:string):integer;
    function  NewItem(ais:integer):integer;
    procedure DeleteItem(aidx:integer);
    procedure AutoSplit(ais:integer; apad:integer=0);

    // input picture
    function UseImageset   (                           ais: integer=-1): boolean;  // file from imageset info
    function UseImageFile  (const aname:string       ; ais: integer=-1): boolean;  // disk file
    function UseImageData  (adata:TImageData         ; ais: integer=-1): boolean;  // from Imaging library
    function UseController (const actrl:TRGController; ais: integer=-1): boolean;  // game archive/PAK
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
    function ExtractSprite(anames:TStrings             ):integer;
    function ExtractSprite(const anames:array of string):integer;

    function ExtractSprite(const aname:string; const aoutname:string=''):boolean;
    function ExtractSprite(idx:integer;        const aoutname:string=''):boolean;

    function ExtractAll(aimgset:integer=-1):integer;

    property OutputPath:string index 0 read FOutputPath write SetPath;
    property RootPath  :string index 1 read FRootPath   write SetPath;
  end;


implementation

uses
  DOM, XMLRead,
  RGStream,
  RGIO.Text,
  RGIO.Dat,
  RGNode;


procedure TRGImageset.Init;
begin
  FOutputPath:=ExtractPath(ParamStr(0));
  FRootPath  :='';
  lastid     :=0;
  FDeleted   :=-1;
  FDeletedCnt:=0;
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

procedure TRGImageset.CloseImageset(const aname:string);
var
  i:integer;
begin
  for i:=0 to ImagesetCount-1 do
    if Imagesets[i].Name=aname then
    begin
      CloseImageset(i);
      exit;
    end;
end;

procedure TRGImageset.CloseImageset(aidx:integer);
var
  lid,i,litem,lcnt:integer;
begin
  if (aidx>=0) and (aidx<ImagesetCount) then
  begin
    lid:=Imagesets[aidx].id;
    lcnt:=0;
    for i:=0 to ItemCount-1 do
      if Items[i].ISFile=lid then
      begin
        DeleteItem(i);
{
        litem:=i;
        lcnt:=0;
        while (litem<ItemCount) and (Items[litem].ISFile=lid) do
        begin
          inc(lcnt);
          inc(litem);
        end;
        Delete(Items,i,lcnt);
        dec(ItemCount,lcnt);
        break;
}
      end;

    FreeImage(Imagesets[aidx].Image);
    Delete(Imagesets,aidx,1);
    dec(ImagesetCount);
  end;
end;

procedure TRGImageset.SetPath(aidx:integer; const apath:string);
var
  ls:string;
begin
  if not (apath[Length(apath)] in ['\','/']) then
    ls:=apath+'/'
  else
    ls:=apath;

  if aidx=0 then FOutputPath:=ls
  else           FRootPath  :=ls;
end;

{%REGION Imageset}
function TRGImageset.NewImageset(const aname:string):integer;
var
  i:integer;
begin
  //!! maybe return existing? or ignore and create new? renamed?
  for i:=0 to ImagesetCount-1 do
    if Imagesets[i].Name=aname then exit(-1);

  result:=ImagesetCount;
  inc(ImagesetCount);
  if ImagesetCount>=Length(Imagesets) then
    SetLength(Imagesets,Length(Imagesets)+8);

  FillChar(Imagesets[result],SizeOf(TImagesetFile),0);
  with Imagesets[result] do
  begin
    id:=lastid;
    inc(lastid);
    if aname='' then
      Name:='imagesets'
    else
      Name:=aname;
  end;
end;

procedure TRGImageset.CheckItem(alen:integer);
begin
  //!!!! for using with NewItem only
  dec(alen,FDeletedCnt);
  if alen<=0 then exit;

  if (ItemCount+alen)>=Length(Items) then
    SetLength(Items,Align(Length(Items)+alen,16));
end;

function TRGImageset.NewItem(ais:integer):integer;
begin
  if FDeleted>=0 then
  begin
    result:=FDeleted;
    FDeleted:=Items[result].XPos;
    dec(FDeletedCnt);
  end
  else
  begin
    CheckItem(1);
    result:=ItemCount;
    inc(ItemCount);
  end;

  with Items[result] do
  begin
    Name  :='new_item';
    ISFile:=ais;
    XPos  :=1;
    YPos  :=1;
    Width :=62;
    Height:=62;
  end;
end;

function ReadXMLText(out ADoc: TXMLDocument; abuf:PByte; asize:integer):boolean;
var
  lin:TXMLInputSource;
  adom:TDOMParser;

  lpc:PAnsiChar;
  ls:string;
begin
  result:=false;

  lpc:=PAnsiChar(abuf);
  if (PDword(abuf)^ and $00FFFFFF)=SIGN_UTF8 then
  begin
    inc(lpc,3);
    dec(asize,3);
  end;
  if lpc^<>'<' then exit;

  SetString(ls,lpc,asize);
  lin  := TXMLInputSource.Create(ls);
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
function TRGImageset.ParseXML(abuf:PByte; asize:integer):boolean;
var
  lname,lpic:TDomNode;
  Doc: TXMLDocument;
  Child: TDOMNode;
  ls:string;
  lidx,lid,lis:integer;
begin
  result:=ReadXMLText(Doc, abuf, asize);

  if result then
  begin
    try
      lpic:=Doc.DocumentElement.Attributes.GetNamedItem('Imagefile');
      if lpic=nil then exit;

      lname:=Doc.DocumentElement.Attributes.GetNamedItem('Name');
      // better to use imageset filename but it unknown for this code
      if lname=nil then
        ls:=ExtractNameOnly(AnsiString(lpic.NodeValue))
      else
        ls:=AnsiString(lname.NodeValue);

      lis:=NewImageset(ls);
      result:=lis>=0;

      if result then
      begin
        with Imagesets[lis] do
        begin
          lid:=id;
          Sheet:=AnsiString(lpic.NodeValue);

          lpic:=Doc.DocumentElement.Attributes.GetNamedItem('NativeHorzRes');
          if lpic<>nil then Val(lpic.NodeValue,Width) else Width:=1024;

          lpic:=Doc.DocumentElement.Attributes.GetNamedItem('NativeVertRes');
          if lpic<>nil then Val(lpic.NodeValue,Height) else Height:=768;
        end;
        
        if Doc.DocumentElement.ChildNodes.Count>0 then
        begin
          Child:=Doc.DocumentElement.FirstChild;

          CheckItem(Doc.DocumentElement.ChildNodes.Count);

          while Assigned(Child) do
          begin
            if CompareWideI(PWideChar(Child.NodeName),'Image')=0 then
            begin
              lidx:=NewItem(lid);
              with Items[lidx] do
              begin
                Name  :=AnsiString(Child.Attributes.Item[0].NodeValue);
//                ISFile:=lid;
                Val(Child.Attributes.Item[1].NodeValue,XPos);
                Val(Child.Attributes.Item[2].NodeValue,YPos);
                Val(Child.Attributes.Item[3].NodeValue,Width);
                Val(Child.Attributes.Item[4].NodeValue,Height);
              end;
//              inc(ItemCount);
            end;
            Child:=Child.NextSibling;
          end;
        end;
      end;

    finally
      Doc.Free;
    end;
  end;
end;

function TRGImageset.ParseDAT(abuf:PByte; asize:integer):boolean;
var
  lnode,lchild,larg:pointer;
  lname,pc:PWideChar;
  ls:string;
  i,j:integer;
  lidx,lis,lid,lx,ly,lwidth,lheight:integer;
begin
  pc:=PWideChar(abuf);
  if ORD(pc^)=SIGN_UNICODE then inc(pc);
  if pc^='[' then
    WideToNode(PWideChar(abuf),0,lnode)
  else
    lnode:=ParseDatMem(abuf);

  result:=lnode<>nil;
  
  if result then
  begin
    ls:=WideToStr(GetNodeName(lnode));
    lis:=NewImageset(ls);
    result:=lis>=0;
  end;
  if result then
  begin
    lid:=Imagesets[lis].id;
    // more than needs really
    CheckItem(GetChildCount(lnode));

    for i:=0 to GetChildCount(lnode)-1 do
    begin
      lchild:=GetChild(lnode,i);
      case GetNodeType(lchild) of
        rgString: if CompareWide(GetNodeName(lchild),'FILE')=0 then
          Imagesets[lis].Sheet:=WideToStr(AsString(lchild));

        rgInteger: if CompareWide(GetNodeName(lchild),'SIZE')=0 then
        begin
          Imagesets[lis].Width :=AsInteger(lchild);
          Imagesets[lis].Height:=Imagesets[lis].Width;
        end;

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
            lidx:=NewItem(lid);
            with Items[lidx] do
            begin
              Name  :=FastWideToStr(lname);
//              ISFile:=lid;
              XPos  :=lx;
              YPos  :=ly;
              Width :=lwidth;
              Height:=lheight;
            end;
//            inc(ItemCount);
          end;
        end;
      else
      end;
    end;
    DeleteNode(lnode);
  end;
end;

function TRGImageset.ParseFromMemory(abuf:PByte; asize:integer):boolean;
begin
  result:=ParseXML(abuf,asize);
  if not result then
    result:=ParseDAT(abuf,asize);
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

function TRGImageset.BuildImageset(ais:integer; out bin:pByte; aver:integer=verTL2):integer;
var
  ldata:string;
  lid,i,lcnt:integer;
begin
  result:=0;

  if (ais<0) or (ais>=ImagesetCount) then exit;

  lid:=Imagesets[ais].id;

  if ABS(aver) in [verTL1,verTL2] then
  begin
    with Imagesets[ais] do
    begin
      ldata:=
        '<?xml version="1.0" encoding="UTF-8"?>'#13#10+
        '<Imageset'+
        ' Name="'          +Name +
        '" Imagefile="'    +Sheet+
        '" NativeHorzRes="'+IntToStr(Width )+   // 1024 even for 512
        '" NativeVertRes="'+IntToStr(Height)+   // 768  even for 512
        '" AutoScaled="true">'#13#10; //??
    end;

    for i:=0 to ItemCount-1 do
    begin
      with Items[i] do
      begin
        if ISFile<>lid then continue;

        ldata:=ldata+
          '	<Image Name="'+Name+
          '" XPos="'  +IntToStr(XPos  )+
          '" YPos="'  +IntToStr(YPos  )+
          '" Width="' +IntToStr(Width )+
          '" Height="'+IntToStr(Height)+
          '" />'#13#10;
      end;
    end;
    ldata:=ldata+'</Imageset>'#13#10;
  end
  else
  begin
    lcnt:=0;
    for i:=0 to ItemCount-1 do
      if Items[i].ISFile=lid then inc(lcnt);

    if lcnt=0 then exit;

    with Imagesets[ais] do
    begin
      ldata:=
        '['+Name+']'#13#10+
        '  <STRING>FILE:' +Sheet+#13#10+
        '	<INTEGER>COUNT:'+IntToStr(lcnt )+#13#10+
        '	<INTEGER>SIZE:' +IntToStr(Width)+#13#10;
    end;

    lcnt:=0;
    for i:=0 to ItemCount-1 do
    begin
      with Items[i] do
      begin
        if ISFile<>lid then continue;

        ldata:=ldata+
        '  [IMAGE'+IntToStr(lcnt)+']'#13#10+
        '    <STRING>NAME:'   +Name            +#13#10+
        '    <INTEGER>X:'     +IntToStr(XPos  )+#13#10+
        '    <INTEGER>Y:'     +IntToStr(YPos  )+#13#10+
        '    <INTEGER>WIDTH:' +IntToStr(Width )+#13#10+
        '    <INTEGER>HEIGHT:'+IntToStr(Height)+#13#10+
        '  [/IMAGE'+IntToStr(lcnt)+']'#13#10;

        inc(lcnt);
      end;
    end;

    ldata:=ldata+'[/'+Imagesets[ais].Name+']'#13#10;
  end;

  result:=Length(ldata)+1;
  GetMem(bin,result);
  move(PAnsiChar(ldata)^,bin^,result);
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
  lres:boolean;
begin
  result:=false;
  lname:='';
  AssignFile(f,aname);
  Reset(f);
  lres:=IOResult()<>0;
  if lres and (FRootPath<>'') then
  begin
    AssignFile(f,FRootPath+aname);
    Reset(f);
    lres:=IOResult()<>0;
  end;
  if lres then
  begin
    lname:=ExtractName(aname);
    AssignFile(f,lname);
    Reset(f);
    lres:=IOResult()<>0;
    if lres then
    begin
      lext:=ExtractExt(aname);
           if lext='.DDS' then lext:='.PNG'
      else if lext='.PNG' then lext:='.DDS'
      else exit;
      AssignFile(f,ChangeFileExt(aname,lext));
      Reset(f);
      lres:=IOResult()<>0;
      if lres and (FRootPath<>'') then
      begin
        AssignFile(f,ChangeFileExt(FRootPath+aname,lext));
        Reset(f);
        lres:=IOResult()<>0;
      end;
      if lres then
      begin
        AssignFile(f,ChangeFileExt(lname,lext));
        Reset(f);
        lres:=IOResult()<>0;
      end;
    end;
  end;
  if not lres then
  begin
    lsize:=FileSize(f);
    if lsize>0 then
    begin
      GetMem(lbuf,lsize);
      BlockRead(f,lbuf^,lsize);
      result:=UseImageMemory(lbuf,lsize,ais);
      FreeMem(lbuf);
    end;
    CloseFile(f);
  end;
end;

function TRGImageset.UseImageMemory(abuf:PByte; asize:integer; ais:integer=-1):boolean;
begin
  if (ais<0) or (ais>=ImagesetCount) then ais:=ImagesetCount-1; if ais<0 then exit(false);
  FreeImage(Imagesets[ais].Image);
  LoadImageFromMemory(abuf,asize,Imagesets[ais].Image);
  result:=UseImageset(ais);
end;

function TRGImageset.UseImageset(ais:integer=-1):boolean;
var
  lis:PImagesetFile;
begin
  if (ais<0) or (ais>=ImagesetCount) then ais:=ImagesetCount-1; if ais<0 then exit(false);
  lis:=@Imagesets[ais];
  with lis^.Image do
    result:=(Width>0) and (Height>0) and (Bits<>nil);

  {if lis^.Width <>lis^.Image.Width  then }lis^.Width :=lis^.Image.Width;
  {if lis^.Height<>lis^.Image.Height then }lis^.Height:=lis^.Image.Height;
end;

function TRGImageset.UseImageData(adata:TImageData; ais:integer=-1):boolean;
var
  lis:PImagesetFile;
begin
  if (ais<0) or (ais>=ImagesetCount) then ais:=ImagesetCount-1; if ais<0 then exit(false);
  lis:=@Imagesets[ais];
  FreeImage(lis^.Image);
  result:=CloneImage(adata, lis^.Image);

  {if lis^.Width <>lis^.Image.Width  then }lis^.Width :=lis^.Image.Width;
  {if lis^.Height<>lis^.Image.Height then }lis^.Height:=lis^.Image.Height;
end;

function TRGImageset.UseController(const actrl:TRGController; ais:integer=-1):boolean;
var
  lbuf:PByte;
  lfile,lsize:integer;
begin
  if (ais<0) or (ais>=ImagesetCount) then ais:=ImagesetCount-1; if ais<0 then exit(false);
  lfile:=actrl.SearchFile(Imagesets[ais].Sheet);
  if lfile>=0 then
  begin
    lbuf:=nil;
    lsize:=actrl.GetSource(lfile,lbuf);
    result:=UseImageMemory(lbuf,lsize,ais);
    FreeMem(lbuf);
  end
  else
    result:=false;
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

function TRGImageset.ISbyID(aid:integer):integer;
var
  i:integer;
begin
  for i:=0 to ImagesetCount-1 do
    if Imagesets[i].id=aid then exit(i);

  result:=-1;
end;

function TRGImageset.ISbyName(const aname:string):integer;
var
  i:integer;
begin
  if aname<>'' then
    for i:=0 to ImagesetCount-1 do
      if Imagesets[i].Name=aname then exit(i);

  result:=-1;
end;

{%ENDREGION Info}

{%REGION Sprite}
function TRGImageset.GetSprite(idx:integer; var asprite:TImageData):boolean;
var
  lidx:integer;
begin
  if (idx>=0) and (idx<ItemCount) then
  begin
    with Items[idx] do
    begin
      lidx:=ISbyID(ISFile);
      NewImage(Width,Height,
               Imagesets[lidx].Image.Format,asprite);
      CopyRect(Imagesets[lidx].Image,
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

  if GetSprite(idx,lsprite) then
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

{%REGION Extract}
function TRGImageset.ExtractAll(aimgset:integer=-1):integer;
var
  lid,i,j,llow,lhi:integer;
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
    lid:=Imagesets[i].id;

    for j:=0 to ItemCount-1 do
    begin
      with Items[j] do
        if ISFile=lid then
        begin
          if ExtractSprite(j) then inc(result);
        end;
    end;
  end;
end;

function TRGImageset.ExtractSprite(idx:integer; const aoutname:string=''):boolean;
var
  lsprite:TImageData;
begin
  result:=GetSprite(idx,lsprite);
  if result then
  begin
    if aoutname='' then
    begin
      if (FOutputPath<>'') and (not DirectoryExists(FOutputPath)) then
        ForceDirectories(FOutputPath);
      SaveImageToFile(FOutputPath+Items[idx].Name+'.png',lsprite)
    end
    else
      SaveImageToFile(aoutname,lsprite);

    FreeImage(lsprite);
  end;
end;

function TRGImageset.ExtractSprite(const aname:string; const aoutname:string=''):boolean;
begin
  result:=ExtractSprite(ItemByName(aname), aoutname);
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

{%REGION Modify}
procedure TRGImageset.DeleteItem(aidx:integer);
begin
  if (aidx>=0) and (aidx<ItemCount) then
  begin
    with Items[aidx] do
    begin
      ISFile:=-1;
      XPos  :=FDeleted;
      Name  :='';
    end;
    FDeleted:=aidx;
    inc(FDeletedCnt);
  end;
end;

procedure TRGImageset.AutoSplit(ais:integer; apad:integer=0);
var
  lcnt,i,j,k:integer;
  lwidth,lheight:integer;
  lfound:boolean;
begin
(*
  result:=NewImageset(const aname:string);
  if not result then exit;

  //!!!!!!!!!!!!!!!!!!!!
  // !!! set IS fields first
*)
  with Imagesets[ais{ImagesetCount-1}] do
  begin
    lwidth :=Width  div 64;
    lheight:=Height div 64;
  end;

  lcnt:=ItemCount;
  CheckItem(lheight*lwidth);

  for i:=0 to lheight-1 do
    for j:=0 to lwidth-1 do
    begin
      // skip existing
      lfound:=false;
      for k:=0 to lcnt-1 do
        with Items[k] do
          if (ISFile=ais) and
             (XPos =j*64+apad) and (YPos  =i*64+apad) and
             (Width=64-2*apad) and (Height=64-2*apad) then
          begin
            lfound:=true;
            break;
          end;
        
      if not lfound then
      begin
        with Items[ItemCount] do
        begin
          Name  :='new '+IntToStr(j)+'x'+IntToStr(i);
          XPos  :=j*64+apad;
          YPos  :=i*64+apad;
          Width :=64-2*apad;
          Height:=64-2*apad;
          ISFile:=ais;
        end;
        inc(ItemCount);
      end;
    end;
end;

{%ENDREGION Modify}

end.
