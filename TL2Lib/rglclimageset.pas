{
  Graphics and ImagingComponents requires Interfaces (framework) unit
  Graphics used for TPicture and PNG read/write
  PNG from Imaging requires DZlib additionaly
  ImagingComponents used for imaging <-> graphics formats conversion
  !! WARGING !! rect is X,Y,Width,Height, NOT right, bottom !!
}
unit RGLCLImageset;

{$mode ObjFPC}{$H+}

interface

uses
  Graphics,
  rgimageset;


type
  TRGImageset = object(rgimageset.TRGImageset)
  public
    function  UseImagePicture(apic: TPicture; ais:integer=-1):boolean;
    procedure GetImage       (apic: TPicture; ais:integer=-1);
    function  GetSprite(const aname:string ; apic:TPicture):boolean;
    function  GetSprite(      idx  :integer; apic:TPicture):boolean;
  end;


implementation

uses
  Classes,
  Imaging, ImagingTypes, ImagingComponents;

procedure TRGImageset.GetImage(apic:TPicture; ais:integer=-1);
begin
  if ais<0 then ais:=ImagesetCount-1; if ais<0 then exit;
  if Imagesets[ais].Image.Format=IFUnknown then
  begin
    apic.Clear;
    exit;
  end;
  //  if UseImageset then
    ConvertDataToBitmap(Imagesets[ais].Image,apic.Bitmap);
end;

function TRGImageset.UseImagePicture(apic:TPicture; ais:integer=-1):boolean;
begin
  if ais<0 then ais:=ImagesetCount-1; if ais<0 then exit(false);
  FreeImage(Imagesets[ais].Image);
  ConvertBitmapToData(apic.Bitmap,Imagesets[ais].Image);
  result:=UseImageSet();
end;

function TRGImageset.GetSprite(idx:integer; apic:TPicture):boolean;
var
  lsprite:TImageData;
  lrc:TRect;
begin
  result:=false;

  if (idx>=0) and (idx<ItemCount) then
  begin
    with Items[idx] do
    begin
      if Imagesets[ISFile].Image.Format=IFUnknown then exit;
      lrc:=ItemBounds(idx);
      NewImage(lrc.Right,lrc.Bottom,
               Imagesets[ISFile].Image.Format,lsprite);
      CopyRect(Imagesets[ISFile].Image,
        lrc.Left ,lrc.Top,
        lrc.Right,lrc.Bottom,
        lsprite,0,0);
    end;
    ConvertDataToBitmap(lsprite,apic.Bitmap);
    FreeImage(lsprite);

    result:=true;
  end;
end;

function TRGImageset.GetSprite(const aname:string; apic:TPicture):boolean;
begin
  result:=GetSprite(ItemByName(aname),apic);
end;


end.
