{%REGION Recipes}

function AddRecipeToBase(ams:pointer; const aname:string; aId:int64; const atitle:string):boolean;
var
  lmodid,lSQL,sid:string;
begin
  result:=false;

  Str(aid,sid);
  lmodid:=CheckForMod(ams,'recipes', sid, PModScanner(ams)^.FModId);
  if lmodid<>'' then
  begin
    lSQL:='REPLACE INTO recipes (id, name, title, modid) VALUES ('+
        sid+', '+FixedText(aname)+', '+FixedText(atitle)+', '+lmodid+')';

    result:=ExecuteDirect(PModScanner(ams)^.db,lSQL);
  end;
end;

function AddRecipeNode(ams:pointer; anode:pointer):int64;
var
  lnode:pointer;
  pcw:PWideChar;
  name,title:string;
  lid:int64;
  i,mask:integer;
begin
  title:='';
  lid:=-1;

  mask:=0;
  for i:=0 to GetChildCount(anode)-1 do
  begin
    lnode:=GetChild(anode,i);

    if GetNodeType(lnode)<>rgGroup then
    begin
      pcw:=GetNodeName(lnode);
      if CompareWide(pcw,'NAME')=0 then
      begin
        mask:=mask or 1;
        name:=AsString(lnode);
      end
      else if CompareWide(pcw,'GUID')=0 then
      begin
        mask:=mask or 2;
        lid:=AsInteger64(lnode);
      end
      else if CompareWide(pcw,'RESULT')=0 then
      begin
        mask:=mask or 4;
        title:=AsString(lnode);
      end;
      if mask=7 then break;
    end;
  end;

  if lid<>-1 then
    if not AddRecipeToBase(ams,name,lid,title) then lid:=0;

  result:=lid;
end;

function ProcessRecipes(
          abuf:PByte; asize:integer;
          const adir,aname:string;
          aparam:pointer):integer;
var
  p:pointer;
  i:int64;
begin
  result:=0;

  p:=ParseTextMem(abuf);
  if p=nil then
    p:=ParseDatMem(abuf);
  
  if p<>nil then
  begin
    i:=AddRecipeNode(aparam,p);

    if      i=0 then RGLog.Add('can''t update '+aname)
    else if i<0 then RGLog.Add(' don''t added '+aname);

    DeleteNode(p);
  end;
end;

function ScanRecipes(ams:pointer):integer;
begin
  result:=DoRGScan(PModScanner(ams)^.scan, 'MEDIA/RECIPES', @ProcessRecipes);
end;

function CreateRecipesTable(ams:pointer):boolean;
begin
  if not IsTableExists(PModScanner(ams)^.db,'recipes') then
    result:=ExecuteDirect(PModScanner(ams)^.db,
      'CREATE TABLE recipes ('+
      '    id    INTEGER PRIMARY KEY,'+
      '    name  TEXT,'+
      '    title TEXT,'+
      '    modid TEXT );');
end;

{%ENDREGION}
