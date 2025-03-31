{TODO: paint border for sprite on image (need to recalc coords)}
unit fmImageset;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Menus, rglclimageset, rgctrl;

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
    miSelectAll: TMenuItem;
    miExtract: TMenuItem;
    pnlSprite: TPanel;
    pnlLeft: TPanel;
    mnuImgSet: TPopupMenu;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    procedure cbDarkBgClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure DrawDarkBg(ASender: TObject; ACanvas: TCanvas; ARect: TRect);
    procedure lbImagesClick(Sender: TObject);
    procedure lbImagesKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure miExtractClick(Sender: TObject);
    procedure miSelectAllClick(Sender: TObject);
  private
    FImageset:TRGImageset;
    FSprite:integer;
    FOnImagesetInfo:TOnImagesetInfo;

  public
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

procedure TFormImageset.lbImagesClick(Sender: TObject);
begin
  if lbImages.ItemIndex>=0 then
  begin
    FSprite:=lbImages.ItemIndex;

    if FOnImagesetInfo<>nil then FOnImagesetInfo(FImageset.ImageFile,FImageset.Bounds[FSprite]);

    FImageset.GetSprite(FSprite,imgSprite.Picture);
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
      lpath:=ExtractPath(ParamStr(0));
    ldir.Free;

    FImageset.OutputPath(lpath);
    for i:=0 to lbImages.Items.Count-1 do
    begin
      if lbImages.Selected[i] then
      begin
        FImageset.ExtractSprite(i);
      end;
    end;
  end;
end;

procedure TFormImageset.miSelectAllClick(Sender: TObject);
begin
  lbImages.SelectAll;
end;

procedure TFormImageset.FormDestroy(Sender: TObject);
begin
  FImageset.Free;
end;

procedure TFormImageset.FormCreate(Sender: TObject);
begin
  FImageset.Init;
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

procedure TFormImageset.FillList(const actrl:TRGController;
    adata:PByte; asize:integer; adir:string='');
var
  ls,ls1:string;
  i:integer;
  lres:boolean;
begin

  lbImages.Items.Clear;
  imgSprite.Picture.Clear;

  if FImageset.ParseFromMemory(adata,asize) then
  begin
    for i:=0 to FImageset.Count-1 do
    begin
      lbImages.Items.Add(FImageset.Name[i]);
    end;

    if adir<>'' then
    begin
      ls:=FImageset.ImageFile;
      FImageset.ImageFile:=StringReplace(UpCase(ls),'MEDIA/',adir,[]);
      lres:=FImageset.UseController(actrl);
      if not lres then
        FImageset.ImageFile:=ls;
    end
    else
      lres:=false;

    if not lres then
      if not FImageset.UseController(actrl) then ;
    FImageset.GetImage(imgTexture.Picture);
  end;

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

  lbImages.Items.Clear;
  imgSprite.Picture.Clear;

  if FImageset.ParseFromFile(lfname) then
  begin
    for i:=0 to FImageset.Count-1 do
    begin
      lbImages.Items.Add(FImageset.Name[i]);
    end;

    FImageset.GetImage(imgTexture.Picture);
  end;

end;

end.
