{%REGION Recipes}

function AddRecipeToBase(ams:pointer; const aname:string; aId:int64; const atitle:string):boolean;
var
  lmodid,lSQL,sid:string;
begin
  result:=false;

  if aId=-1 then
  begin
    sid:='-1';
    lmodid:=CheckNameForMod(ams,'recipes', aname);
  end
  else
  begin
    Str(aid,sid);
    lmodid:=CheckIdForMod(ams,'recipes', sid);
  end;
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

//  if lid<>-1 then
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
  result:=sres_fail;

  if asize>0 then
  begin
    RGLog.Reserve('Scan '+adir+aname);

    p:=ParseTextMem(abuf);
    if p=nil then
      p:=ParseDatMem(abuf);
    
    if p<>nil then
    begin
      i:=AddRecipeNode(aparam,p);

      if i=0  then if RGDebugLevel=dlDetailed then RGLog.Add('can''t update '+aname);
//      if i=-1 then if RGDebugLevel=dlDetailed then RGLog.Add('don''t added ' +aname);
      if i>0  then result:=1;

      DeleteNode(p);
    end;

    RGLog.Reserve('');
  end;
end;

function ScanRecipes(ams:pointer):integer;
begin
  if RGDebugLevel<>dlNone then RGLog.Add('Scanning recipes');
  result:=DoRGScan(PModScanner(ams)^.scan, 'MEDIA/RECIPES', @ProcessRecipes);
  if RGDebugLevel<>dlNone then RGLog.Add(IntToStr(result)+' records added');
end;

// Variant: to make two different structures, for TL1 and TL2 games
// id can be AUTOINCREMENT then
function CreateRecipesTable(adb:PSQLite3):boolean;
begin
  if not IsTableExists(adb,'recipes') then
    result:=ExecuteDirect(adb,
      'CREATE TABLE recipes ('+
//      '    id    INTEGER PRIMARY KEY,'+
      '    id    INTEGER,'+
      '    name  TEXT,'+
      '    title TEXT,'+
      '    modid TEXT );')
  else
    result:=true;
end;

{%ENDREGION}
