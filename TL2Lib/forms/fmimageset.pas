{TODO: Preview Imageset as text (memo), select text line of sprite}
{TODO: edit imageset (name, sprite, text) and save}
unit fmImageset;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Menus, ComCtrls, ListFilterEdit, rglclimageset, rgctrl;

//!! WARGING !! rect is X,Y,Width,Height, NOT right, bottom !!
type
  TOnImagesetInfo = procedure (const afile:string; arect:TRect) of object;

type

  { TFormImageset }

  TFormImageset = class(TForm)
    cbDarkBg: TCheckBox;
    imgSprite: TImage;
    imgTexture: TImage;
    lbImages: TListBox;
    lbImagesets: TListBox;
    lfeImages: TListFilterEdit;
    miSelectAll: TMenuItem;
    miExtract: TMenuItem;
    pnlImages: TPanel;
    pnlSprite: TPanel;
    pnlLeft: TPanel;
    mnuImgSet: TPopupMenu;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    Splitter3: TSplitter;
    StatusBar: TStatusBar;
    procedure cbDarkBgClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure DrawDarkBg(ASender: TObject; ACanvas: TCanvas; ARect: TRect);
    procedure imgTextureMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure lbImagesetsSelectionChange(Sender: TObject; User: boolean);
    procedure lbImagesSelectionChange(Sender: TObject; User: boolean);
    procedure lfeImagesAfterFilter(Sender: TObject);
    procedure lbImagesKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure miExtractClick(Sender: TObject);
    procedure miSelectAllClick(Sender: TObject);
  private
    rectBorder:TRect;
    FActiveImageset:integer;
    FSprite:integer;
    FOnImagesetInfo:TOnImagesetInfo;
    procedure FillImagesetList();
    procedure FillSpriteList(ais: integer);

  public
    FImageset:TRGImageset;

    procedure FillList(const actrl: TRGController;
        adata: PByte; asize: integer; adir:string='');
    procedure FillList(const fname:string);

    property OnImagesetInfo:TOnImagesetInfo read FOnImagesetInfo write FOnImagesetInfo;
  end;

var
  FormImageset: TFormImageset;

implementation

{$R *.lfm}

uses
  LCLType,
  rgglobal;

resourcestring
  rsSaveSprite   = 'Save sprite';
  rsLoadImageset = 'Load imageset';
  rsAllImagesets = 'All imagesets';


procedure TFormImageset.FormDestroy(Sender: TObject);
begin
  FImageset.Free;
end;

procedure TFormImageset.FormCreate(Sender: TObject);
begin
  FImageset.Init;
  imgTexture.Canvas.Pen.Mode   :=pmNotXor;
  imgTexture.Canvas.Pen.Width  :=6;
  imgTexture.Canvas.Brush.Style:=bsClear;
  rectBorder.Left :=0;
  rectBorder.Right:=0;
end;

procedure TFormImageset.imgTextureMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  lrect:TRect;
  i,j:integer;
  kw,kh:single;
begin
  kw:=imgTexture.Picture.Width /imgTexture.Width;
  kh:=imgTexture.Picture.Height/imgTexture.Height;
  if kw<kh then kw:=kh;
  X := Round(X*kw);
  Y := Round(Y*kw);

  for i:=0 to FImageset.ItemCount-1 do
  begin
    if FImageset.Items[i].ISFile<>FActiveImageset then continue;

    with FImageset.ItemBounds(i) do
      lrect:=Rect(Left,Top,Left+Right,Top+Bottom);

    if (X>=lrect.Left) and (X<lrect.Right ) and
       (Y>=lrect.Top ) and (Y<lrect.Bottom) then
    begin
      for j:=0 to lbImages.Items.Count-1 do
        if i=IntPtr(lbImages.Items.Objects[j]) then
        begin
          lbImages.ItemIndex:=j;
//          lbImagesClick(lbImages);
          break;
        end;
      break;
    end;
  end;
end;

procedure TFormImageset.lbImagesKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Shift=[ssCtrl] then
  begin
    if (Key=VK_A) then lbImages.SelectAll;
    if (Key=VK_S) or (Key=VK_E) then miExtractClick(Sender);
    Key:=0;
  end;
end;

procedure TFormImageset.miExtractClick(Sender: TObject);
var
  ldlg:TSaveDialog;
  ldir:TSelectDirectoryDialog;
  lpath:string;
  i,lidx:integer;
begin
  if lbImages.SelCount=1 then
  begin
    ldlg:=TSaveDialog.Create(nil);
    ldlg.Title   :=rsSaveSprite;
    ldlg.FileName:=lbImages.Items[lbImages.ItemIndex]+'.png';
    ldlg.Options :=ldlg.Options+[ofOverwritePrompt];
    if ldlg.Execute then
    begin
      if ExtractExt(ldlg.FileName)='' then
        ldlg.FileName:=ldlg.FileName+'.png';

{
      FImageset.ExtractSprite(
        IntPtr(lbImages.Items.Objects[lbImages.ItemIndex]),
        ldlg.FileName);
}
      imgSprite.Picture.PNG.SaveToFile(ldlg.FileName);
      //!!!! check why saves as BMP !!!!
//      imgSprite.Picture.SaveToFile(ldlg.FileName,'png');
    end;
    ldlg.Free;
  end
  else if lbImages.SelCount>1 then
  begin
    ldir:=TSelectDirectoryDialog.Create(nil);
    if ldir.Execute then
      lpath:=ldir.FileName
    else
      lpath:=ExtractPath(ParamStr(0));
    ldir.Free;

    FImageset.OutputPath:=lpath;
    for i:=0 to lbImages.Items.Count-1 do
    begin
      if lbImages.Selected[i] then
      begin
        FImageset.ExtractSprite(IntPtr(lbImages.Items.Objects[i]));
      end;
    end;
  end;
end;

procedure TFormImageset.miSelectAllClick(Sender: TObject);
begin
  lbImages.SelectAll;
end;

procedure TFormImageset.DrawDarkBg(ASender: TObject; ACanvas: TCanvas; ARect: TRect);
begin
  ACanvas.Brush.Color := clGray;
  ACanvas.FillRect(ARect);
end;

procedure TFormImageset.cbDarkBgClick(Sender: TObject);
begin
  if cbDarkBg.Checked then
  begin
    imgSprite .OnPaintBackground:=@DrawDarkBg;
    imgTexture.OnPaintBackground:=@DrawDarkBg;
  end
  else
  begin
    imgSprite .OnPaintBackground:=nil;
    imgTexture.OnPaintBackground:=nil;
  end;
  imgSprite .Repaint;
  imgTexture.Repaint;
end;

procedure TFormImageset.lbImagesSelectionChange(Sender: TObject; User: boolean);
begin
  if lbImages.ItemIndex>=0 then
  begin
    FSprite:=IntPtr(lbImages.Items.Objects[lbImages.ItemIndex]);

    if FImageset.Items[FSprite].ISFile<>FActiveImageset then
    begin
      FActiveImageset:=FImageset.Items[FSprite].ISFile;
      FImageset.GetImage(imgTexture.Picture,FActiveImageset);
    end
    else
    begin
      if rectBorder.Left<>rectBorder.Right then
        imgTexture.Canvas.Rectangle(rectBorder);
    end;

    if FOnImagesetInfo<>nil then
      FOnImagesetInfo(FImageset.Imagesets[0].Sheet,
                      FImageset.ItemBounds(FSprite));

    FImageset.GetSprite(FSprite,imgSprite.Picture);

    with FImageset.ItemBounds(FSprite) do
    begin
      StatusBar.Panels[0].Text:=Format('%d, %d; %d x %d',[Left,Top,Right,Bottom]);
      rectBorder:=Rect(Left,Top,Left+Right,Top+Bottom);
    end;
    imgTexture.Canvas.Rectangle(rectBorder);
  end
  else
    imgTexture.Picture.Clear;
end;

procedure TFormImageset.lbImagesetsSelectionChange(Sender: TObject; User: boolean);
begin
  if lbImagesets.ItemIndex<0 then exit;

  FillSpriteList(IntPtr(lbImagesets.Items.Objects[lbImagesets.ItemIndex]));
end;

procedure TFormImageset.lfeImagesAfterFilter(Sender: TObject);
begin
  if lbImages.Items.Count>0 then
  begin
    lbImages.ItemIndex:=0;
//    lbImagesClick(Sender);
  end;
end;

procedure TFormImageset.FillSpriteList(ais:integer);
var
  i:integer;
begin
  rectBorder:=Rect(0,0,0,0);
{
  lfeImages.Items.Clear;
  lfeImages.Text:='';
  for i:=0 to FImageset.ItemCount-1 do
    if (ais<0) or (ais=FImageset.Items[i].ISFile) then
      lfeImages.Items.AddObject(FImageset.Items[i].Name,TObject(IntPtr(i)));
  lfeImages.InvalidateFilter;
  // lbImages still empty here
}
  lfeImages.Items.Clear;
  lfeImages.Text:='';

  for i:=0 to FImageset.ItemCount-1 do
    if (ais<0) or (ais=FImageset.Items[i].ISFile) then
      lfeImages.Items.AddObject(FImageset.Items[i].Name,TObject(IntPtr(i)));

  if lfeImages.Items.Count>0 then
  begin
    lfeImages.ForceFilter(' ');
    lfeImages.ForceFilter('');

    lbImages.Selected[0]:=true;
    lbImages.ItemIndex:=0;
    lbImagesSelectionChange(lbImages, true);
  end;
{
  lfeImages.FilteredListBox:=nil;
  lfeImages.Text:='';
  lbImages.items.Clear;

  for i:=0 to FImageset.ItemCount-1 do
    if (ais<0) or (ais=FImageset.Items[i].ISFile) then
      lbImages.Items.AddObject(FImageset.Items[i].Name,TObject(IntPtr(i)));

  if lbImages.Items.Count>0 then
  begin
    lbImages.Selected[0]:=true;
    lbImages.ItemIndex:=0;
    lbImagesSelectionChange(lbImages, true);
  end;
  lfeImages.FilteredListBox:=lbImages;
}
end;

procedure TFormImageset.FillImagesetList();
var
  i:integer;
begin
  if FImageset.ImagesetCount>1 then
  begin
    lbImagesets.Visible:=true;
    Splitter3.Visible:=true;
    lbImagesets.Clear;
    lbImagesets.Items.AddObject(rsAllImagesets,TObject(-1));
    for i:=0 to FImageset.ImagesetCount-1 do
      lbImagesets.Items.AddObject(FImageset.Imagesets[i].Name,TObject(IntPtr(i)));
    lbImagesets.ItemIndex:=0;
  end
  else
  begin
    lbImagesets.Visible:=false;
    Splitter3.Visible:=false;

    FillSpriteList(0);
  end;
end;

procedure TFormImageset.FillList(const actrl:TRGController;
    adata:PByte; asize:integer; adir:string='');
var
  ls:string;
  i:integer;
  lres:boolean;
begin
  imgSprite.Picture.Clear;

  if FImageset.ParseFromMemory(adata,asize) then
  begin
    if adir<>'' then
    begin
      ls:=FImageset.Imagesets[FImageset.ImagesetCount-1].Sheet;
      FImageset.Imagesets[FImageset.ImagesetCount-1].Sheet:=StringReplace(UpCase(ls),'MEDIA/',adir,[]);
      lres:=FImageset.UseController(actrl);
      if not lres then
        FImageset.Imagesets[FImageset.ImagesetCount-1].Sheet:=ls;
    end
    else
      lres:=false;

    if not lres then
      if not FImageset.UseController(actrl) then ;
    FImageset.GetImage(imgTexture.Picture);
    FActiveImageset:=FImageset.ImagesetCount-1;
  end;
  FillImagesetList();

end;

procedure TFormImageset.FillList(const fname:string);
var
  ldlg:TOpenDialog;
  lfname:string;
  i:integer;
begin
  if fname='' then
  begin
    ldlg:=TOpenDialog.Create(nil);
    ldlg.Filter:='Imageset|*.imageset';
    ldlg.Title:=rsLoadImageset;
    lfname:='';
    if ldlg.Execute then
    begin
      ChDir(ldlg.InitialDir);
      lfname:=ldlg.FileName;
    end;
    ldlg.Free;
  end
  else
  begin
    Chdir(ExtractFilePath(fname));
    lfname:=fname;
  end;
  if lfname='' then exit;

  imgSprite.Picture.Clear;

  if FImageset.ParseFromFile(lfname) then
  begin
    FActiveImageset:=FImageset.ImagesetCount-1;
    FImageset.UseImageFile(FImageset.Imagesets[FActiveImageset].Sheet);
    FImageset.GetImage(imgTexture.Picture);
  end;
  FillImagesetList();

end;

end.
