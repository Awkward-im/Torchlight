{%REGION Adds}

{$i scan_graph.inc}

function ScanAdds(ams:pointer):integer;
begin
  result:=0;
end;

function CreateAddsTable(adb:PSQLite3):boolean;
begin
  if not IsTableExists(adb,'effects') then
    result:=ExecuteDirect(adb,
      'CREATE TABLE effects ('+
      '  id        INTEGER,'+
      '  name      TEXT,'+
      '  gooddes   TEXT,'+
      '  gooddesot TEXT,'+
      '  baddes    TEXT,'+
      '  baddesot  TEXT);');

{
  Good to add:
    Equip Sets
}
end;

{%ENDREGION Adds}