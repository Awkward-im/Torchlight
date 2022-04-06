{%REGION Adds}

{$i scan_graph.inc}
{$i scan_effects.inc}

function ScanAdds(ams:pointer):integer;
begin
  result:=ScanEffects(ams);
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
