{%REGION Wardrobe}

type
  twardrobeinfo = record
    id    :string;
    name  :string;
    atype :string;
    gender:string;
  end;

function AddWardrobeToBase(ams:pointer; var adata:twardrobeinfo):boolean;
var
  lmodid,lSQL:string;
begin
  result:=false;

  lmodid:=CheckForMod(ams,'wardrobe', adata.id, PModScanner(ams)^.FModId);
  if lmodid<>'' then
  begin
    lSQL:='REPLACE INTO wardrobe (id, name, type, gender, modid) VALUES ('+
        adata.id+', '+FixedText(adata.name)+', '+FixedText(adata.atype)+', '''+adata.gender+
        ''', '+lmodid+')';

    result:=ExecuteDirect(PModScanner(ams)^.db,lSQL);
  end;
end;

function ScanWardrobeNode(ams:pointer; anode:pointer):integer;
var
  pp,lnode:pointer;
  pcw:PWideChar;
  ls:string;
  ldata:twardrobeinfo;
  i,j:integer;
begin
  result:=0;

  for j:=0 to GetChildCount(anode)-1 do
  begin
    pp:=GetChild(anode,j);
    if CompareWide(GetNodeName(pp),'FEATURE')=0 then
    begin
      for i:=0 to GetChildCount(pp)-1 do
      begin
        lnode:=GetChild(pp,i);
        pcw:=GetNodeName(lnode);
        if      CompareWide(pcw,'NAME' )=0 then ldata.name :=AsString(lnode)
        else if CompareWide(pcw,'TYPE' )=0 then ldata.atype:=AsString(lnode)
        else if CompareWide(pcw,'GUID' )=0 then Str(AsInteger64(lnode),ldata.id)
        else if CompareWide(pcw,'CLASS')=0 then
        begin
          ls:=asString(lnode);
          ldata.gender:=UpCase(ls[length(ls)]);
        end;
      end;

      if not AddWardrobeToBase(ams,ldata) then
        RGLog.Add('can''t update '+ldata.name)
      else
        inc(result);
    end;
  end;

end;

function ScanWardrobe(ams:pointer):integer;
var
  p:pointer;
begin
  result:=0;

  LoadFile(ams,'MEDIA/WARDROBE/WARDROBESETS.DAT',p);
  if p<>nil then
  begin
    result:=ScanWardrobeNode(ams,p);
    DeleteNode(p);
  end;
end;

function CreateWardrobeTable(ams:pointer):boolean;
begin
  if not IsTableExists(PModScanner(ams)^.db,'wardrobe') then
    result:=ExecuteDirect(PModScanner(ams)^.db,
      'CREATE TABLE wardrobe ('+
      '    id     INTEGER PRIMARY KEY,'+
      '    name   TEXT,'+
      '    title  TEXT,'+
      '    modid  TEXT,'+
      '    type   TEXT,'+
      '    gender CHAR );');
end;

{%ENDREGION}
