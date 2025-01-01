{$R ..\TL2Lib\dict.rc}

uses
  rgglobal,
  rgnode,
  logging,
  rgdict,
  rgdictlayout,
  rgio.layout,
  rgio.text;


function MakeMethod(Data, Code:Pointer):TMethod;
begin
  Result.Data:=Data;
  Result.Code:=Code;
end;

function AddToLog(dummy:pointer; var adata:string):integer;
begin
  writeln(adata);
  adata:='';
  result:=0;
end;

var
  p:pointer;
begin
  RGLog.OnAdd:=TLogOnAdd(MakeMethod(nil,@AddToLog));

  RGTags.Import('RGDICT','TEXT');

//  RGTags.SortBy(0);

  LoadLayoutDict('LAYTL1', 'TEXT', verTL1);
  LoadLayoutDict('LAYTL2', 'TEXT', verTL2);
  LoadLayoutDict('LAYRG' , 'TEXT', verRG);
  LoadLayoutDict('LAYRGO', 'TEXT', verRGO);
  LoadLayoutDict('LAYHOB', 'TEXT', verHob);

  p:=ParseLayoutFile(ParamStr(1));
  BuildTextFile(p,'out.txt');
  DeleteNode(p);
end.
