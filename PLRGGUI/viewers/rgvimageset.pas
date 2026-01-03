{}
unit rgvImageset;

interface

uses
  Forms,
  RGCtrl;


function PreviewImageset(var actrl:TRGController; aidx:integer):TForm;


implementation

uses
  SysUtils,
  Types,
  Controls,
  StdCtrls,
  RGGlobal,
  fmImageset,
  DMViewer;


resourcestring
  rsImageFile = 'Texture file';
  rsSprite    = 'X: %d; Y: %d; Width: %d; Height: %d';

type
  TISForm = class(TBaseViewer)
    lblInfo1:TLabel;
    lblInfo2:TLabel;
    procedure ShowImagesetInfo(const afile:string; arect:TRect);
  end;

procedure TISForm.ShowImagesetInfo(const afile:string; arect:TRect);
begin
  lblInfo1.Caption:=rsImageFile+': '+afile;
  lblInfo2.Caption:=Format(rsSprite,[arect.Left,arect.Top,arect.Right,arect.Bottom]);
end;

function PreviewImageset(var actrl:TRGController; aidx:integer):TForm;
var
  lbuf:PByte;
  ldir:string;
  lsize,i:integer;
begin
  lbuf:=nil;
  lsize:=actrl.GetSource(aidx,lbuf);
  if lsize>0 then
  begin
    result:=TISForm.Create(actrl,aidx);
    with TISForm(result) do
    begin
      lblInfo1:=TLabel.Create(result);
      lblInfo1.Left  :=8;
      lblInfo1.Top   :=3;
      lblInfo1.Parent:=pnlInfo;

      lblInfo2:=TLabel.Create(result);
      lblInfo2.Left  :=8;
      lblInfo2.Top   :=19; // lblInfo1.Top+lblInfo1.Height+2;
      lblInfo2.Parent:=pnlInfo;

      with TFormImageset.Create(result) do
      begin
        OnImagesetInfo:=@ShowImagesetInfo;

        ldir:=WideToStr(actrl.PathOfFile(aidx));
        i:=Pos('/UI/',ldir);
        if i>7 then ldir:=Copy(ldir,1,i) else ldir:='';
        FillList(actrl,lbuf,lsize,ldir);

        Align  :=alClient;
        Parent :=result;
        Visible:=true;
      end;
    end;
    FreeMem(lbuf);
  end
  else
    result:=nil;
end;

end.
