{%REGION Adds}

{$i scan_graph.inc}
{$i scan_effects.inc}

function ScanAdds(ams:pointer):integer;
begin
  if PModScanner(ams)^.FLogLevel>0 then RGLog.Add('Scanning effects');
  result:=ScanEffects(ams);
  if PModScanner(ams)^.FLogLevel>0 then RGLog.Add(IntToStr(result)+' records added');
end;

function CreateAddsTable(adb:PSQLite3):boolean;
begin
  result:=CreateEffectsTable(adb);
{
  Good to add:
    Equip Sets
}
end;

{%ENDREGION Adds}
