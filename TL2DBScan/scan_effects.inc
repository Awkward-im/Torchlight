{%REGION Effects}

{TODO: add modid field?}
function AddEffectToBase(ams:pointer;  aid:integer;
     const aname, agooddes, agooddesot, abaddes, abaddesot:string):boolean;
var
  lSQL:string;
begin
  result:=false;

  lSQL:='REPLACE INTO effects (id, name, gooddes, gooddesot, baddes, baddesot) VALUES ('+
      IntToStr(aid)+', '+FixedText(aname)+', '+FixedText(agooddes)+', '+FixedText(agooddesot)+
      ', '+FixedText(abaddes)+', '+FixedText(abaddesot)+')';

  result:=ExecuteDirect(PModScanner(ams)^.db,lSQL);
end;

function AddEffectNode(ams:pointer; anode:pointer):integer;
var
  lnode, llnode:pointer;
  pcw:PWideChar;
  lname,lgooddes,lgooddesot,lbaddes,lbaddesot:string;
  i,j,lmask:integer;
begin
  result:=0;

  for i:=0 to GetChildCount(anode)-1 do
  begin
    lnode:=GetChild(anode,i); // 'MOVIE'
    lmask     :=0;
    lname     :='';
    lgooddes  :='';
    lgooddesot:='';
    lbaddes   :='';
    lbaddesot :='';

    for j:=0 to GetChildCount(lnode)-1 do
    begin
      llnode:=GetChild(lnode,j);

      pcw:=GetNodeName(llnode);
      if      CompareWide(pcw,'NAME')=0 then
      begin
        lname:=AsString(llnode);
        lmask:=lmask or 1;
      end
      else if CompareWide(pcw,'GOODDES')=0 then
      begin
        lgooddes:=AsTranslate(llnode);
        lmask:=lmask or 2;
      end
      else if CompareWide(pcw,'GOODDESOT')=0 then
      begin
        lgooddesot:=AsTranslate(llnode);
        lmask:=lmask or 4;
      end
      else if CompareWide(pcw,'BADDES')=0 then
      begin
        lbaddes:=AsTranslate(llnode);
        lmask:=lmask or 8;
      end
      else if CompareWide(pcw,'BADDESOT')=0 then
      begin
        lbaddesot:=AsTranslate(llnode);
        lmask:=lmask or 16;
      end;
      if lmask=31 then
      begin
        if AddEffectToBase(ams,i,lname,lgooddes,lgooddesot,lbaddes,lbaddesot) then inc(result);
        break;
      end;
    end;

  end;

end;

function ScanEffects(ams:pointer):integer;
var
  p:pointer;
begin
  result:=sres_fail;

  LoadFile(ams,'MEDIA/EFFECTSLIST.DAT',p);
  if (p=nil) and (PModScanner(ams)^.gamever=verTL1) then
    LoadFile(ams,'MEDIA/EFFECTSLIST.DAT.ADM',p);

  if p<>nil then
  begin
    if AddEffectNode(ams,p)>0 then
      result:=1
    else if PModScanner(ams)^.FLogLevel>1 then RGLog.Add('can''t update EFFECTSLIST.DAT');

    DeleteNode(p);
  end;
end;

function CreateEffectsTable(adb:PSQLite3):boolean;
begin
  if not IsTableExists(adb,'effects') then
    result:=ExecuteDirect(adb,
      'CREATE TABLE effects ('+
      '  id        INTEGER,'+
      '  name      TEXT,'+
      '  gooddes   TEXT,'+
      '  gooddesot TEXT,'+
      '  baddes    TEXT,'+
      '  baddesot  TEXT);')
  else
    result:=true;
end;

{%ENDREGION Effects}
