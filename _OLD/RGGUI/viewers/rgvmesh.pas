{}
unit rgvMesh;

interface

uses
  Forms,
  rgctrl;

function PreviewModel(var actrl:TRGController; aidx:integer):TForm;


implementation

uses
  SysUtils,
  Controls,
  StdCtrls,
  rgglobal,
  fm3dview,
  DMViewer;

resourcestring
  rsMdlMeshes = 'Bounds: Min:(%f, %f, %f); Max(%f, %f, %f); SubMeshes: %d';

function PreviewModel(var actrl:TRGController; aidx:integer):TForm;
var
  lbuf:PByte;
  lmesh:TForm3dView;
  lbl:TLabel;
  ls:AnsiString;
  lsize:integer;
begin
  lbuf:=nil;
  lsize:=actrl.GetBinary(aidx,lbuf);
  if lsize>0 then
  begin
    result:=TBaseViewer.Create(actrl,aidx);

    lbl:=TLabel.Create(result);
    lbl.Left  :=8;
    lbl.Top   :=3;
    lbl.Parent:=TBaseViewer(result).pnlInfo;
    
//    result.Visible:=True;

    lmesh:=TForm3dView.Create(result);
    lmesh.Align  :=alClient;
    lmesh.Parent :=result;
    lmesh.SetContainer(@actrl);
    ls:=WideToStr(actrl.PathOfFile(aidx))+
        WideToStr(actrl.Files[aidx]^.Name);
    lmesh.LoadFromMemory(lbuf,lsize,ls);
    lmesh.Visible:=True;
    FreeMem(lbuf);

    // #meshes, have skeleton
    with lmesh.Mesh do
    begin
      if BoneCount>0 then
        ls:='+bones'
      else
        ls:='-bones';
      lbl.Caption:=Format(rsMdlMeshes,
        [BoundMin.X, BoundMin.Y, BoundMin.Z,
         BoundMax.X, BoundMax.Y, BoundMax.Z,
         SubMeshCount])+' '+ls;
  //  lblInfo2.Caption:=Format(rsMdlCoords,[tx,ty,tz]);
    end;
  end
  else
    result:=nil;
end;

end.
