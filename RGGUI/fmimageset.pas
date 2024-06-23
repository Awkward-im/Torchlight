{TODO: Buttons: proportional, inverse background (OnPaintBackground event)}
{TODO: paint border for sprite on image (need to recalc coords)}
unit fmImageset;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Menus, Imaging, ImagingDds, ImagingTypes, ImagingComponents, rgctrl;

type
  TOnImagesetInfo = procedure (const afile:string; ax,ay, awidth, aheight:integer) of object;

type

  { TFormImageset }

  TFormImageset = class(TForm)
    imgSprite: TImage;
    imgTexture: TImage;
    lbImages: TListBox;
    miExtract: TMenuItem;
    pnlLeft: TPanel;
    mnuImgSet: TPopupMenu;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure lbImagesClick(Sender: TObject);
    procedure lbImagesKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure miExtractClick(Sender: TObject);
  private
    picfile:string;
    FFileName:string;
    FImage:TImageData;
    FSprite:integer;
    FCoords:array of record
      XPos,
      YPos,
      Width,
      Height: integer;
    end;
    FOnImagesetInfo:TOnImagesetInfo;
    procedure FillListDAT(astr: PWideChar);
    procedure FillListXML(const astr: AnsiString);

  public
    procedure FillList(const actrl: TRGController; adata: PByte; asize: integer);

    property OnImagesetInfo:TOnImagesetInfo read FOnImagesetInfo write FOnImagesetInfo;
  end;

var
  FormImageset: TFormImageset;

implementation

{$R *.lfm}

uses
  LCLType,
  dom,xmlreader,xmlread,
  rgglobal, rgio.Text, rgNode;

resourcestring
  rsSaveSprite = 'Save sprite';

procedure TFormImageset.lbImagesClick(Sender: TObject);
var
  lsprite:TImageData;
begin
  if lbImages.ItemIndex>=0 then
  begin
    FSprite:=lbImages.ItemIndex;
    if FOnImagesetInfo<>nil then FOnImagesetInfo(picfile,
      FCoords[FSprite].XPos,FCoords[FSprite].YPos,
      FCoords[FSprite].Width,FCoords[FSprite].Height);
    // Here something to show
    NewImage(FCoords[FSprite].Width,FCoords[FSprite].Height,
            FImage.Format,lsprite);
    CopyRect(FImage,
      FCoords[FSprite].XPos ,FCoords[FSprite].YPos,
      FCoords[FSprite].Width,FCoords[FSprite].Height,
      lsprite,0,0);
    ConvertDataToBitmap(lsprite,imgSprite.Picture.Bitmap);
    FreeImage(lsprite);
  end;
end;

procedure TFormImageset.lbImagesKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Shift=[ssCtrl] then
  begin
    if (Key=VK_A) then lbImages.SelectAll;
    if (Key=VK_S) then miExtractClick(Sender);
    Key:=0;
  end;
end;

procedure TFormImageset.miExtractClick(Sender: TObject);
var
  ldlg:TSaveDialog;
  ldir:TSelectDirectoryDialog;
  lsprite:TImageData;
  lpic:TPicture;
  lpath:string;
  i:integer;
begin
  if lbImages.SelCount=1 then
  begin
    ldlg:=TSaveDialog.Create(nil);
    ldlg.Title   :=rsSaveSprite;
    ldlg.FileName:=lbImages.Items[lbImages.ItemIndex]+'.png';
    ldlg.Options :=ldlg.Options+[ofOverwritePrompt];
    if ldlg.Execute then
    begin
      if ExtractFileExt(ldlg.FileName)='' then
        ldlg.FileName:=ldlg.FileName+'.png';
      imgSprite.Picture.SaveToFile(ldlg.FileName,'.png');
    end;
    ldlg.Free;
  end
  else if lbImages.SelCount>1 then
  begin
    ldir:=TSelectDirectoryDialog.Create(nil);
    if ldir.Execute then
      lpath:=ldir.FileName
    else
      lpath:=ExtractFilePath(ParamStr(0))+FFileName;
    ldir.Free;
    ForceDirectories(lpath);
    lpic:=TPicture.Create;
    for i:=0 to lbImages.Items.Count-1 do
    begin
      if lbImages.Selected[i] then
      begin
        NewImage(FCoords[i].Width,FCoords[i].Height,
                FImage.Format,lsprite);
        CopyRect(FImage,
          FCoords[i].XPos ,FCoords[i].YPos,
          FCoords[i].Width,FCoords[i].Height,
          lsprite,0,0);
//        SaveImageToFile(lbImages.Items[i]+'.dds',lsprite);
        ConvertDataToBitmap(lsprite,lpic.Bitmap);
        lpic.SaveToFile(lpath+'\'+lbImages.Items[i]+'.png','.png');
        FreeImage(lsprite);
      end;
    end;
    lpic.Free;
  end;
end;

procedure TFormImageset.FormDestroy(Sender: TObject);
begin
  FreeImage(FImage);
end;

procedure TFormImageset.FormCreate(Sender: TObject);
begin
//  InitImage(FImage);
end;

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
procedure TFormImageset.FillListXML(const astr:AnsiString);
var
  lpic:TDomNode;
  Doc: TXMLDocument;
  Child: TDOMNode;
  i:integer;
begin
  ReadXMLText(Doc,astr);
  try
    lpic:=Doc.DocumentElement.Attributes.GetNamedItem('Name');
    if lpic<>nil then FFileName:=lpic.NodeValue;

    lpic:=Doc.DocumentElement.Attributes.GetNamedItem('Imagefile');
    if lpic=nil then exit;

    picfile:=lpic.NodeValue;
    if Doc.DocumentElement.ChildNodes.Count>0 then
    begin
      Child:=Doc.DocumentElement.FirstChild;
      if Child=nil then exit;

      SetLength(FCoords,Doc.DocumentElement.ChildNodes.Count);
      i:=0;
      while Assigned(Child) do
      begin
        lbImages.Items.Add(Child.Attributes.Item[0].NodeValue);
        Val(Child.Attributes.Item[1].NodeValue,FCoords[i].XPos);
        Val(Child.Attributes.Item[2].NodeValue,FCoords[i].YPos);
        Val(Child.Attributes.Item[3].NodeValue,FCoords[i].Width);
        Val(Child.Attributes.Item[4].NodeValue,FCoords[i].Height);
        Child:=Child.NextSibling;
        inc(i);
      end;
    end;

  finally
    Doc.Free;
  end;
end;

procedure TFormImageset.FillListDAT(astr:PWideChar);
var
  lnode,lchild,larg:pointer;
  lname,pc:PWideChar;
  lcnt,i,j:integer;
  lx,ly,lwidth,lheight:integer;
begin
  if WideToNode(astr,0,lnode)=0 then
  begin
    FFileName:=WideToStr(GetNodeName(lnode));
    // more than needs really
    SetLength(FCoords,GetChildCount(lnode));
    lcnt:=0;
    for i:=0 to GetChildCount(lnode)-1 do
    begin
      lchild:=GetChild(lnode,i);
      case GetNodeType(lchild) of
        rgString: if CompareWide(GetNodeName(lchild),'FILE')=0 then
          picfile:=WideToStr(AsString(lchild));
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
            lbImages.Items.Add(lname);
            FCoords[lcnt].XPos  :=lx;
            FCoords[lcnt].YPos  :=ly;
            FCoords[lcnt].Width :=lwidth;
            FCoords[lcnt].Height:=lheight;
            inc(lcnt)
          end;
        end;
      else
      end;
    end;
    DeleteNode(lnode);
  end;
end;

procedure TFormImageset.FillList(const actrl:TRGController; adata:PByte; asize:integer);
var
  ls:string;
  lpc:PAnsiChar;
  pc:PWideChar;
  lbuf:PByte;
  lfile,lsize:integer;
begin
  picfile:='';
  FFileName:='';
  lbImages.Items.Clear;
  FreeImage(FImage);
  InitImage(FImage);

  lpc:=PAnsiChar(adata);
  if (PDword(adata)^ and $00FFFFFF)=SIGN_UTF8 then
  begin
    inc(lpc,3);
    dec(asize,3);
  end;
  if lpc^='<' then
  begin
    SetString(ls,lpc,asize);
    FillListXML(ls);
  end;

  pc:=PWideChar(adata);
  if ORD(pc^)=SIGN_UNICODE then
  begin
    inc(pc);
    dec(asize,2);
  end;
  if pc^='[' then
    FillListDAT(pc{,asize div 2});

  if FFileName='' then FFileName:='imagesets';

  lfile:=actrl.SearchFile(picfile);
  if lfile>=0 then
  begin
    lbuf:=nil;
    lsize:=actrl.GetSource(lfile,lbuf);
    LoadImageFromMemory(lbuf,lsize,FImage);
    FreeMem(lbuf);
    ConvertDataToBitmap(FImage,imgTexture.Picture.Bitmap);
  end;
end;

end.

