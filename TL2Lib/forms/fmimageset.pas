{NOTE: Imagesets object is imagesets ID, Images object is Items index}
{TODO: exit form after dBlClick on spite/sprite name}
{TODO: Preview Imageset as text (memo), select text line of sprite}
{TODO: edit imageset (name, sprite, text) and save}
unit fmImageSet;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Menus, ComCtrls, ActnList, ListFilterEdit, SpinEx, RGLCLImageSet, RGCtrl;

//!! WARGING !! rect is X,Y,Width,Height, NOT right, bottom !!
type
  TOnImagesetInfo = procedure (const afile:string; arect:TRect) of object;

type

  { TFormImageset }

  TFormImageset = class(TForm)
    actDelete: TAction;
    actISAutosplit: TAction;
    actNewSprite: TAction;
    ActionList: TActionList;
    actDarkBG   : TAction;
    actISClose    : TAction;
    actISOpen     : TAction;
    actISSave     : TAction;
    actSelectAll: TAction;
    actExtract  : TAction;
    actRename   : TAction;
    cbDarkBg: TCheckBox;
    imgSprite: TImage;
    imgTexture: TImage;
    lbImagesets: TListBox;
    lbImages   : TListBox;
    lfeImages  : TListFilterEdit;
    miDelete: TMenuItem;
    miRename: TMenuItem;
    miNewItem: TMenuItem;
    miSep1: TMenuItem;
    pnlTop   : TPanel;
    pnlRight : TPanel;
    pnlImages: TPanel;
    pnlSprite: TPanel;
    pnlLeft  : TPanel;
    mnuImages: TPopupMenu;
    miSelectAll: TMenuItem;
    miExtract  : TMenuItem;
    seLeft  : TSpinEditEx;  lblLeft  : TLabel;
    seTop   : TSpinEditEx;  lblTop   : TLabel;
    seWidth : TSpinEditEx;  lblWidth : TLabel;
    seHeight: TSpinEditEx;  lblHeight: TLabel;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    Splitter3: TSplitter;
    StatusBar: TStatusBar;

    procedure DarkBgChange(Sender: TObject);
    procedure DoAutosplit (Sender: TObject);
    procedure DoCloseIS   (Sender: TObject);
    procedure DoDelete(Sender: TObject);
    procedure DoRename    (Sender: TObject);
    procedure DoDarkBg    (Sender: TObject);
    procedure DoOpen      (Sender: TObject);
    procedure DoSave      (Sender: TObject);
    procedure DoExtract   (Sender: TObject);
    procedure DoSelectAll (Sender: TObject);
    procedure DoNewItem   (Sender: TObject);
    procedure FormCreate (Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure DrawDarkBg(ASender: TObject; ACanvas: TCanvas; ARect: TRect);
    procedure imgTextureMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure imgTextureMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure lbImagesetsSelectionChange(Sender: TObject; User: boolean);
    procedure lbImagesSelectionChange   (Sender: TObject; User: boolean);
    procedure lfeImagesAfterFilter      (Sender: TObject);
    procedure SpinValueChanged(Sender: TObject);
//    procedure lbImagesKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    rectBorder:TRect;
    FSetSEValues:boolean;
    FActiveImageset:integer;
    FSprite:integer;
    FOnImagesetInfo:TOnImagesetInfo;

    procedure AddImageset(const fname: string);
    procedure CheckActs();
    procedure FillImagesetList();
    procedure FillSpriteList(ais: integer);
    function GetActiveIS(): integer;
    procedure SetSelected(aval:string);
    function  GetSelected():string;

  public
    FImageset:TRGImageset;

    procedure FillList(const actrl:TRGController; adata:PByte; asize:integer; adir:string='');
    procedure FillList(const fname:string);

    property OnImagesetInfo:TOnImagesetInfo read FOnImagesetInfo write FOnImagesetInfo;
    property Selected:string read GetSelected write SetSelected;
  end;

var
  FormImageset: TFormImageset;

implementation

{$R *.lfm}

uses
  LCLType,
  RGGlobal;

resourcestring
  rsSaveSprite   = 'Save sprite';
  rsLoadImageset = 'Load imageset';
  rsAllImagesets = 'All imagesets';
  rsChangeName   = 'Change sprite name';
  rsNewName      = 'New Name';


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
  FSetSEValues:=false;
  CheckActs();
end;

procedure TFormImageset.CheckActs();
var
  i,lid:integer;
  lis:boolean;
begin
  lis:=FImageset.ImagesetCount>0;
  actISClose    .Enabled:=lis;
  actISSave     .Enabled:=lis;
  actISAutosplit.Enabled:=lis;
  if lis then
    lbImages.PopupMenu:=mnuImages
  else
    lbImages.PopupMenu:=nil;

  lid:=GetActiveIS();
  lis:=false;
  for i:=0 to FImageset.ItemCount-1 do
    if FImageset.Items[i].ISFile=lid then
    begin
      lis:=true;
      break;
    end;
  actRename .Enabled:=lis;
  actExtract.Enabled:=lis;
  actDelete .Enabled:=lis;
end;

function TFormImageset.GetActiveIS():integer;
begin
  if FImageset.ImagesetCount=0 then exit(-1);

  result:=FImageset.Imagesets[0].id;
  if lbImagesets.Items.Count>0 then
    if lbImagesets.ItemIndex>=0 then
      result:=IntPtr(lbImagesets.Items.Objects[lbImagesets.ItemIndex]);
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

procedure TFormImageset.imgTextureMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
  StatusBar.Panels[0].Text:=Format('X: %d, Y: %d',[X,Y]);
end;

{
procedure TFormImageset.lbImagesKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Shift=[ssCtrl] then
  begin
    if (Key=VK_A) then lbImages.SelectAll;
    if (Key=VK_S) or (Key=VK_E) then miExtractClick(Sender);
    Key:=0;
  end;
end;
}
procedure TFormImageset.DoExtract(Sender: TObject);
var
  ldlg:TSaveDialog;
  ldir:TSelectDirectoryDialog;
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

procedure TFormImageset.DoSelectAll(Sender: TObject);
begin
  lbImages.SelectAll;
end;

procedure TFormImageset.DoOpen(Sender: TObject);
begin
  FillList('');
  CheckActs();
end;

procedure TFormImageset.DoSave(Sender: TObject);
var
  f:file of byte;
  ldlg:TSaveDialog;
  lbuf:PByte;
  lsize,lis:integer;
begin
  lis:=FImageset.ISbyID(FActiveImageset);
//  if FImageset.Imagesets[lis].modified then
  begin
    ldlg:=TSaveDialog.Create(self);
    ldlg.Options   :=ldlg.Options+[ofOverwritePrompt];
    ldlg.Filter:='Imageset|*.imageset';
    ldlg.DefaultExt:='.imageset';
    ldlg.FileName  :=ChangeFileExt(FImageset.Imagesets[lis].Name,ldlg.DefaultExt);
    if ldlg.Execute then
    begin
      lbuf:=nil;
      lsize:=FImageset.BuildImageset(lis,lbuf);
      if lsize>0 then
      begin
        AssignFile(f,ldlg.FileName);
        Rewrite(f);
        if IOResult=0 then
        begin
          BlockWrite(f,lbuf^,lsize);
          CloseFile(f);
        end;
        FreeMem(lbuf);
      end;
      FImageset.Imagesets[lis].modified:=false;
    end;
    ldlg.Free;
  end;
end;

procedure TFormImageset.DoCloseIS(Sender: TObject);
begin
  FImageset.CloseImageset(GetActiveIS());
  FillImagesetList();
  lbImagesets.ItemIndex:=0;
  lbImagesetsSelectionChange(lbImagesets,true);
  CheckActs();
end;

procedure TFormImageset.DoDelete(Sender: TObject);
var
  i:integer;
begin
  for i:=lbImages.Items.Count-1 downto 0 do
    if lbImages.Selected[i] then
      FImageset.DeleteItem(IntPtr(lbImages.Items.Objects[i]));
  FillSpriteList(GetActiveIS());
end;

procedure TFormImageset.DoRename(Sender: TObject);
var
  lname:AnsiString;
  lidx,lis:integer;
begin
//  if ActiveControl=lbImages then
  begin
    lname:=lbImages.Items[lbImages.ItemIndex];
    if not InputQuery(rsChangeName, rsNewName,lname) then exit;
    if lname=lbImages.Items[lbImages.ItemIndex] then exit;
// not allowed on sorted list
//    lbImages.Items[lbImages.ItemIndex]:=lname;
    lidx:=IntPtr(lbImages.Items.Objects[lbImages.ItemIndex]);
    lis:=FImageset.Items[lidx].ISFile;
    FImageset.Items[lidx].Name:=lname;
    FImageset.Imagesets[FImageset.ISbyID(lis)].modified:=true;
//    FillSpriteList(lis);
    FillSpriteList(GetActiveIS());
  end;
end;

procedure TFormImageset.DoNewItem(Sender: TObject);
var
  lidx:integer;
begin
  lidx:=GetActiveIS();
  lfeImages.Items.AddObject(FImageset.Items[lidx].Name,TObject(IntPtr(lidx)));
  lfeImages.Filter:='';
  lfeImages.InvalidateFilter;
end;

procedure TFormImageset.DoDarkBg(Sender: TObject);
begin
  cbDarkBg.Checked:=not cbDarkBg.Checked;
  DarkBgChange(cbDarkBg);
end;

procedure TFormImageset.DarkBgChange(Sender: TObject);
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

procedure TFormImageset.DoAutosplit(Sender: TObject);
var
  lis:integer;
begin
  lis:=GetActiveIs();
  FImageset.AutoSplit(lis,1);
  FillSpriteList(lis);
end;

procedure TFormImageset.DrawDarkBg(ASender: TObject; ACanvas: TCanvas; ARect: TRect);
begin
  ACanvas.Brush.Color := clGray;
  ACanvas.FillRect(ARect);
end;

procedure TFormImageset.lbImagesetsSelectionChange(Sender: TObject; User: boolean);
begin
  if lbImagesets.ItemIndex<0 then exit;

  if FActiveImageset=IntPtr(lbImagesets.Items.Objects[lbImagesets.ItemIndex]) then exit;

  FillSpriteList(IntPtr(lbImagesets.Items.Objects[lbImagesets.ItemIndex]));
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
      lbImagesets.Items.AddObject(
          FImageset.Imagesets[i].Name,
          TObject(IntPtr(FImageset.Imagesets[i].id)));
    lbImagesets.ItemIndex:=0;
  end
  else
  begin
    lbImagesets.Visible:=false;
    Splitter3.Visible:=false;

    FillSpriteList(0);
  end;
end;


procedure TFormImageset.lbImagesSelectionChange(Sender: TObject; User: boolean);
begin
  if lbImages.ItemIndex>=0 then
  begin
    FSprite:=IntPtr(lbImages.Items.Objects[lbImages.ItemIndex]);

    if FImageset.Items[FSprite].ISFile<>FActiveImageset then
    begin
      FActiveImageset:=FImageset.Items[FSprite].ISFile;
      FImageset.GetImage(imgTexture.Picture,FImageset.ISbyID(FActiveImageset));
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

    FSetSEValues:=true;
    with FImageset.ItemBounds(FSprite) do
    begin
      seLeft  .Value:=Left;
      seTop   .Value:=Top;
      seWidth .Value:=Right;
      seHeight.Value:=Bottom;
//      StatusBar.Panels[0].Text:=Format('%d, %d; %d x %d',[Left,Top,Right,Bottom]);
      rectBorder:=Rect(Left,Top,Left+Right,Top+Bottom);
    end;
    imgTexture.Canvas.Rectangle(rectBorder);
  end
  else
  begin
    seLeft  .Value:=0;
    seTop   .Value:=0;
    seWidth .Value:=0;
    seHeight.Value:=0;
    FImageset.GetImage(imgTexture.Picture,FImageset.ISbyID(FActiveImageset));
  end;
  FSetSEValues:=false;
  //    imgTexture.Picture.Clear;
end;

procedure TFormImageset.lfeImagesAfterFilter(Sender: TObject);
begin
  if lbImages.Items.Count>0 then
  begin
    lbImages.Selected  [lbImages.Items.Count-1]:=true;
    lbImages.ItemIndex:=lbImages.Items.Count-1;
    lbImagesSelectionChange(lbImages, true);
    pnlTop.Visible:=true;
//    lbImages.ItemIndex:=0;

//    lbImagesClick(Sender);
  end;
end;

procedure TFormImageset.SpinValueChanged(Sender: TObject);
begin
  if not FSetSEValues then imgTexture.Canvas.Rectangle(rectBorder);
  FSprite:=IntPtr(lbImages.Items.Objects[lbImages.ItemIndex]);
  with FImageset.Items[FSprite] do
  begin
         if Sender=seLeft   then XPos  :=seLeft  .Value
    else if Sender=seTop    then YPos  :=seTop   .Value
    else if Sender=seWidth  then Width :=seWidth .Value
    else if Sender=seHeight then Height:=seHeight.Value;
    rectBorder:=Rect(XPos,YPos,XPos+Width,YPos+Height);

    if (XPos>=0) and (yPos>=0) and (Width>1) and (Height>1) then
      FImageset.GetSprite(FSprite,imgSprite.Picture);
  end;
  if not FSetSEValues then imgTexture.Canvas.Rectangle(rectBorder);
end;

procedure TFormImageset.FillSpriteList(ais:integer);
var
  i:integer;
begin
  if rectBorder.Left<>rectBorder.Right then
    imgTexture.Canvas.Rectangle(rectBorder);

  rectBorder:=Rect(0,0,0,0);

  CheckActs();

  lfeImages.Items.Clear;
  lfeImages.Text:='';
  lbImages.Items.Clear;

  for i:=0 to FImageset.ItemCount-1 do
  begin
    if FImageset.Items[i].ISFile<0 then continue;

    if (ais<0) or (ais=FImageset.Items[i].ISFile) then
      lfeImages.Items.AddObject(FImageset.Items[i].Name,TObject(IntPtr(i)));
  end;

  if lfeImages.Items.Count>0 then
  begin
    lfeImages.ForceFilter(' ');
    lfeImages.ForceFilter('');

    lbImages.Selected[0]:=true;
    lbImages.ItemIndex:=0;
    lbImagesSelectionChange(lbImages, true);
    pnlTop.Visible:=true;
  end
  else
  begin
    pnlTop.Visible:=false;
    FActiveImageset:=ais;
    FImageset.GetImage(imgTexture.Picture,FImageset.ISbyID(FActiveImageset));
//    imgTexture.Picture.Clear;
    imgSprite.Picture.Clear;
  end;
{
  lfeImages.FilteredListBox:=nil;
  lfeImages.Text:='';
  lbImages.items.Clear;

  for i:=0 to FImageset.ItemCount-1 do
  begin
    if FImageset.Items[i].ISFile<0 then continue;
    if (ais<0) or (ais=FImageset.Items[i].ISFile) then
      lbImages.Items.AddObject(FImageset.Items[i].Name,TObject(IntPtr(i)));
  end;

  if lbImages.Items.Count>0 then
  begin
    lbImages.Selected[0]:=true;
    lbImages.ItemIndex:=0;
    lbImagesSelectionChange(lbImages, true);
  end;
  lfeImages.FilteredListBox:=lbImages;
}
end;

procedure TFormImageset.FillList(const actrl:TRGController;
    adata:PByte; asize:integer; adir:string='');
var
  ls:string;
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

    FActiveImageset:=FImageset.Imagesets[FImageset.ImagesetCount-1].id;
    FImageset.GetImage(imgTexture.Picture);
  end;
  FillImagesetList();

end;

procedure TFormImageset.AddImageset(const fname:string);
var
  lls:string;
  lidx:integer;
begin
  if ExtractExt(fname)<>'.IMAGESET' then
  begin
    lls:=ExtractNameOnly(fname);
    lidx:=FImageset.ISbyName(lls);
    if lidx<0 then lidx:=FImageset.NewImageset(lls);
    FImageset.Imagesets[lidx].Sheet:=fname;
    FImageset.UseImageFile(fname);
  end
  else
  begin
    if FImageset.ParseFromFile(fname) then
      FImageset.UseImageFile(FImageset.Imagesets[FImageset.ImagesetCount-1].Sheet);
  end;
end;

procedure TFormImageset.FillList(const fname:string);
var
  ldlg:TOpenDialog;
  i:integer;
begin
  if fname='' then
  begin
    ldlg:=TOpenDialog.Create(nil);
    ldlg.Filter:='Imageset|*.imageset|Texture|*.PNG;*.DDS|Supported|*.imageset;*.PNG;*.DDS';
    ldlg.Options:=ldlg.Options+[ofAllowMultiSelect];
    ldlg.Title:=rsLoadImageset;
    if ldlg.Execute then
    begin
      ChDir(ldlg.InitialDir);
      for i:=0 to ldlg.Files.Count-1 do
      begin
        AddImageset(ldlg.Files[i]);
      end;
    end;
    ldlg.Free;
  end
  else
  begin
    Chdir(ExtractFilePath(fname));
    AddImageset(fname);
  end;

  if FImageset.ImagesetCount=1 then
    Caption:=FImageset.Imagesets[0].Name
  else
    Caption:='';

  //  imgSprite.Picture.Clear;
  FActiveImageset:=FImageset.Imagesets[FImageset.ImagesetCount-1].id;
  if FActiveImageset>=0 then
  begin
    FImageset.GetImage(imgTexture.Picture{,FImageset.ImagesetCount-1});
  end;

  FillImagesetList();
end;

procedure TFormImageset.SetSelected(aval:string);
var
  lidx,i:integer;
begin
  lidx:=FImageset.ItemByName(aval);
  for i:=0 to lbImages.Items.Count-1 do
  begin
    if lidx=IntPtr(lbImages.Items.Objects[i]) then
    begin
      lbImages.ItemIndex:=i;
      exit;
    end;
  end;
  if lbImages.Items.Count>0 then
    lbImages.ItemIndex:=0;
end;

function TFormImageset.GetSelected():string;
begin
  if lbImages.ItemIndex<0 then
    result:=''
  else
    result:=FImageset.Items[IntPtr(lbImages.Items.Objects[lbImages.ItemIndex])].Name;
end;

end.
