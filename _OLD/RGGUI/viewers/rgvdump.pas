{}
unit rgvDump;

interface

uses
  Forms,
  rgctrl;

function PreviewDump(var actrl:TRGController; aidx:integer):TForm;


implementation

uses
  Classes,
  Controls,
  FWHexView,
  DMViewer;


function PreviewDump(var actrl:TRGController; aidx:integer):TForm;
var
  ldump:TFWHexView;
  lst:TMemoryStream;
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
