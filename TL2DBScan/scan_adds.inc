{%REGION Adds}

{$i scan_graph.inc}
{$i scan_effects.inc}

function ScanAdds(ams:pointer):integer;
begin
  RGLog.Add('Scanning effects');
  result:=ScanEffects(ams);
  RGLog.Add(IntToStr(result)+' records added');
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
