program tl2dump;

{$mode objfpc}{$H+}

uses
  rgglobal,
  tl2save{,tl2db};

type
  tdummy = object
    function AddToLog(var adata:string):integer;
  end;

function tdummy.AddToLog(var adata:string):integer;
begin
  if IsConsole then writeln(adata);
  adata:='';
  result:=0;
end;

var
  dummy:tdummy;
  tr:TTL2SaveFile;
begin
//  LoadBases;
  RGLog.OnAdd:=@dummy.AddToLog;
  tr:=TTL2SaveFile.Create;
  tr.LoadFromFile(ParamStr(1));
  tr.Parse();

//  tr.Prepare;
//  tr.SaveToFile(ParamStr(1)+'.bin');
  tr.Free;
end.

