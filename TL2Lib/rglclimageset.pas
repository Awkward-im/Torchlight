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
    function  UseImagePicture(apic:TPicture):boolean;                 // TPicture class
    procedure GetImage(apic:TPicture);
    function  GetSprite(const aname:string ; apic:TPicture):boolean;  // by name , to TPicture
    function  GetSprite(      idx  :integer; apic:TPicture):boolean;  // by index, to TPicture
  end;


implementation

uses
  Classes,
  Imaging, ImagingTypes, ImagingComponents;

procedure TRGImageset.GetImage(apic:TPicture);
begin
//  if UseImageset then
    ConvertDataToBitmap(Image,apic.Bitmap);
end;

function TRGImageset.UseImagePicture(apic:TPicture):boolean;
begin
  FreeImage(Image);
  ConvertBitmapToData(apic.Bitmap,Image);
  result:=UseImageSet();
end;

function TRGImageset.GetSprite(idx:integer; apic:TPicture):boolean;
var
  lsprite:TImageData;
  lrc:TRect;
begin
  if (idx>=0) and (idx<Count) then
  begin
    lrc:=Bounds[idx];
    NewImage(lrc.Right,lrc.Bottom,
            Image.Format,lsprite);
    CopyRect(Image,
      lrc.Left ,lrc.Top,
      lrc.Right,lrc.Bottom,
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


end.
