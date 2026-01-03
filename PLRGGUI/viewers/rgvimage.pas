{}
{$DEFINE CustomFormats} // PNG and TGA from Imaging. JPEG still from RTL. DDS from Imaging always
unit rgvImage;

interface

uses
  Forms,
  RGCtrl;


function PreviewImage(var actrl:TRGController; aidx:integer):TForm;


implementation

uses
  Classes,
  SysUtils,

  Controls,
  Graphics,
  Buttons,
  ExtCtrls,

  Imaging,
  ImagingDds,
{$IFDEF CustomFormats}
  ImagingNetworkGraphics,
  ImagingTarga,
{$ELSE}
  lazTGA,
{$ENDIF}
  ImagingTypes,
  ImagingComponents,

  RGGlobal,
  DMViewer;
  

resourcestring
  rsHintScale  = 'Stretch image';
  rsHintDarkBg = 'Draw dark background';

type
  TImageForm = class(TBaseViewer)
    sbScale :TSpeedButton;
    sbDarkBG:TSpeedButton;
    imgPreview:TImage;
    procedure ScaleClick (Sender:TObject);
    procedure DarkBGClick(Sender:TObject);
    procedure DrawDarkBg (ASender: TObject; ACanvas: TCanvas; ARect: TRect);
  end;

procedure TImageForm.DrawDarkBg(ASender: TObject; ACanvas: TCanvas; ARect: TRect);
begin
  ACanvas.Brush.Color := clGray;
  ACanvas.FillRect(ARect);
end;

procedure TImageForm.ScaleClick(Sender:TObject);
begin
  imgPreview.Stretch:=sbScale.Down;
  imgPreview.Repaint;
end;

procedure TImageForm.DarkBGClick(Sender:TObject);
begin
  if sbDarkBg.Down then
    imgPreview.OnPaintBackground:=@DrawDarkBg
  else
    imgPreview.OnPaintBackground:=nil;

  imgPreview.Repaint;
end;

function PreviewImage(var actrl:TRGController; aidx:integer):TForm;
var
  lst :TMemoryStream;
  limg:TImageData;
  lbuf:PByte;
  ls:AnsiString;
  lsize:integer;
begin
  lbuf:=nil;
  lsize:=actrl.GetBinary(aidx,lbuf);
  if lsize=0 then exit(nil);

  result:=TImageForm.Create(actrl,aidx);
  with TImageForm(result) do
  begin
    sbScale:=TSpeedButton.Create(result);
    with sbScale do
    begin
      Left       :=4;
      Top        :=4;
      AllowAllUp :=True;
      GroupIndex :=1;
      ShowCaption:=False;
      Hint       :=rsHintScale;
      Images     :=Viewer.ilViewer;
      ImageIndex :=iiStretch;
      OnClick    :=@ScaleClick;
      Parent     :=pnlInfo;
    end;

    sbDarkBG:=TSpeedButton.Create(result);
    with sbDarkBG do
    begin
      Left       :=sbScale.Left+sbScale.Width+4;
      Top        :=4;
      AllowAllUp :=True;
      GroupIndex :=2;
      ShowCaption:=False;
      Hint       :=rsHintDarkBg;
      Images     :=Viewer.ilViewer;
      ImageIndex :=iiDarkBg;
      OnClick    :=@DarkBGClick;
      Parent     :=pnlInfo;
    end;

    imgPreview:=TImage.Create(result);
    imgPreview.Center      :=True;
    imgPreview.Proportional:=True;
    imgPreview.Align       :=alClient;
    imgPreview.Parent      :=TImageForm(result);

    ls:=ExtractExt(FastWideToStr(actrl.Files[aidx]^.Name));
    if (ls='.DDS') or
{$IFDEF CustomFormats}
       (ls='.PNG') or (ls='.TGA') or
{$ENDIF}      
      ((PByte(lbuf)[0]=ORD('D')) and
       (PByte(lbuf)[1]=ORD('D')) and
       (PByte(lbuf)[2]=ORD('S'))) then
    begin
      InitImage(limg);
      LoadImageFromMemory(lbuf,lsize,limg);
      try
        ConvertDataToBitmap(limg,imgPreview.Picture.Bitmap);
      except
      end;
      FreeImage(limg);
    end
    else
    begin
      lst:=TMemoryStream.Create();
      try
        // PUData cleared in ClearInfo() and/or FormClose;
  //      lstr.SetBuffer(FUData);
        lst.Write(lbuf^,lsize);
        lst.Position:=0;
        try
  //        TImage(result).Picture.LoadFromStream(lst);
          imgPreview.Picture.LoadFromStreamWithFileExt(lst, ls);
        except
        end;
      finally
        lst.Free;
      end;
    end;
    FreeMem(lbuf);
    imgPreview.Hint:='Size: '+
        IntToStr(imgPreview.Picture.Width)+' x '+
        IntToStr(imgPreview.Picture.Height);
  end;
end;

{$IFNDEF CustomFormats}
initialization
  LazTGA.Register;

finalization
  LazTGA.UnRegister;
{$ENDIF}
end.
