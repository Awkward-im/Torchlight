{%REGION Adds}

{$i scan_graph.inc}

function ScanAdds(ams:pointer):integer;
begin
  result:=ScanGraph(ams,'',1);
end;

function CreateAddsTable(ams:pointer):boolean;
begin
  result:=CreateGraphTable (ams);

  if not IsTableExists(PModScanner(ams)^.db,'effects') then
    result:=ExecuteDirect(PModScanner(ams)^.db,
      'CREATE TABLE effects ('+
      '  id        INTEGER,'+
      '  name      TEXT,'+
      '  gooddes   TEXT,'+
      '  gooddesot TEXT,'+
      '  baddes    TEXT,'+
      '  baddesot  TEXT);');

  if not IsTableExists(PModScanner(ams)^.db,'inventory') then
    result:=ExecuteDirect(PModScanner(ams)^.db,
      'CREATE TABLE inventory ('+
      '  id          INTEGER,'+
      '  name        TEXT,'+
      '  iscontainer INTEGER (1));');

{
  Good to add:
    Equip Sets
}
end;

{%ENDREGION Adds}