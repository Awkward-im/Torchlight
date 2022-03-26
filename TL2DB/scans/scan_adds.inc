{%REGION Adds}

{$i scan_graph.inc}

function ScanAdds(ams:pointer):integer;
begin
  result:=0;
end;

function CreateAddsTable(ams:pointer):boolean;
begin
  if not IsTableExists(PModScanner(ams)^.db,'effects') then
    result:=ExecuteDirect(PModScanner(ams)^.db,
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