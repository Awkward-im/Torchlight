{}
{TODO: readonly switch, "save" button (whole file)}
{TODO: preview bytes values as different types}
{TODO: make dump text/bytes search}
unit rgvDump;

interface

uses
  Forms,
  RGCtrl;


function PreviewDump(var actrl:TRGController; aidx:integer):TForm;


implementation

uses
  Classes,
  Controls,
  StdCtrls,
  FWHexView,
  RGGlobal,
  DMViewer;


procedure OnCBChange(aObject:pointer; Sender: TObject);
begin
  TFWHexView(aObject).Encoder.EncodeType:=
      TCharEncoderType(IntPtr(TComboBox(Sender).Items.Objects[TComboBox(Sender).ItemIndex]));
end;

function PreviewDump(var actrl:TRGController; aidx:integer):TForm;
var
  ldump:TFWHexView;
  lst:TMemoryStream;
  cbEncoding:TCombobox;
  lbuf:PByte;
  lsize:integer;
begin
  lbuf:=nil;
  lsize:=actrl.GetBinary(aidx,lbuf);
  if lsize>0 then
  begin
    result:=TBaseViewer.Create(actrl,aidx);
    ldump:=TFWHexView.Create(result);
    ldump.Align :=alClient;
    ldump.Parent:=TBaseViewer(result);

    with TBaseViewer(result) do
    begin
      cbEncoding:=TComboBox.Create(result);
      cbEncoding.Parent :=pnlInfo;
      cbEncoding.Anchors:=[akRight];
      cbEncoding.Width  :=128;
      cbEncoding.Left   :=pnlInfo.ClientWidth-cbEncoding.Width-8;
      cbEncoding.Top    :=14;

      cbEncoding.Items.AddObject('ANSI - Cyrillic (1251)'     ,TObject(1));
      cbEncoding.Items.AddObject('US-ASCII (20127)'           ,TObject(2));
      cbEncoding.Items.AddObject('Unicode (1200)'             ,TObject(3));
      cbEncoding.Items.AddObject('Unicode - Big-Endian (1201)',TObject(4));
      cbEncoding.Items.AddObject('UTF-7 (65000)'              ,TObject(5));
      cbEncoding.Items.AddObject('UTF-8 (65001)'              ,TObject(6));

      cbEncoding.OnChange:=TNotifyEvent(MakeMethod(ldump,@OnCBChange));
      cbEncoding.ItemIndex:=1;
    end;

    lst:=TMemoryStream.Create();
  //  lst.SetBuffer(FUData);
    lst.Write(lbuf^,lsize);
    FreeMem(lbuf);
    lst.Position:=0;

    ldump.SetDataStream(lst,0,soOwned);
  end
  else
    result:=nil;
end;

end.
