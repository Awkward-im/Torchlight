{$I-}
uses
  sqlite3
  ,awkSQLite3
  ,sysutils
  ,TL2ModInfo
  ,TL2DatNode
  ;

var
  smodid:string;
  db:PSQLite3;

type
  tScanProc = procedure (fname:PChar);


function FixedText(const astr:string):string;
begin
  result:=#39+StringReplace(astr,#39,#39#39,[rfReplaceAll])+#39;
end;

function ExtractFileNameOnly(const AFilename: string): string;
var
  StartPos: Integer;
  ExtPos: Integer;
begin
  StartPos:=length(AFilename)+1;
  while (StartPos>1)
  and not (AFilename[StartPos-1] in AllowDirectorySeparators)
  {$IF defined(Windows) or defined(HASAMIGA)}and (AFilename[StartPos-1]<>':'){$ENDIF}
  do
    dec(StartPos);
  ExtPos:=length(AFilename);
  while (ExtPos>=StartPos) and (AFilename[ExtPos]<>'.') do
    dec(ExtPos);
  if (ExtPos<StartPos) then ExtPos:=length(AFilename)+1;
  Result:=copy(AFilename,StartPos,ExtPos-StartPos);
end;

function CompareWide(s1,s2:PWideChar):boolean;
begin
  if s1=s2 then exit(true);
  if ((s1=nil) and (s2^=#0)) or
     ((s2=nil) and (s1^=#0)) then exit(true);
  repeat
    if s1^<>s2^ then exit(false);
    if s1^=#0 then exit(true);
    inc(s1);
    inc(s2);
  until false;
end;

function CheckForMod(const atable,anid,amodid:string):boolean;
var
  lSQL,lmodid:string;
  vm:pointer;
begin
  result:=false;
  lSQL:='SELECT modid FROM '+atable+' WHERE id='+anid;
  if sqlite3_prepare_v2(db,PChar(lSQL),-1,@vm,nil)=SQLITE_OK then
  begin
    if sqlite3_step(vm)=SQLITE_ROW then
    begin
      lmodid:=sqlite3_column_text(vm,0);
      if lmodid<>'' then
      begin
        result:=true;
        if (lmodid <> ' 0 ') and
           (Pos(' '+amodid+' ',lmodid)=0) then
        begin
          sqlite3_finalize(vm);
          lmodid:=lmodid+amodid+' ';
          lSQL:='UPDATE '+atable+' SET modid='''+lmodid+''' WHERE id='+anid;
          sqlite3_prepare_v2(db,PChar(lSQL),-1,@vm,nil);
          sqlite3_step(vm);
        end;
      end;
    end;
    sqlite3_finalize(vm);
  end;
end;

//----- Pet -----

type
  tpetinfo = record
    id      :string;
    title   :string;
    name    :string;
    icon    :string;
    atype   :integer;
    scale   :single;
    textures:integer;
    gr_hp   :string;
    gr_armor:string;
    gr_dmg  :string;
  end;

function AddPetToBase(var apet:tpetinfo):boolean;
var
  lSQL,lscale:string;
  vm:pointer;
begin
  result:=CheckForMod('pets', aPet.id, smodid);
  if not result then
  begin
    Str(aPet.Scale:0:2,lscale);

    lSQL:='INSERT INTO pets (id, name, title, type, scale, skins, icon, '+
          'graph_hp, graph_armor, graph_dmg, modid) VALUES ('+
        aPet.id+', '+FixedText(apet.name)+', '+FixedText(apet.title)+', '+
        IntToStr(apet.atype)+', '+lscale+', '+IntToStr(apet.textures)+
        ', '+FixedText(apet.icon)+', '''+apet.gr_hp+''', '''+apet.gr_armor+''', '''+apet.gr_dmg+
        ''', '' '+smodid+' '')';

    if sqlite3_prepare_v2(db,PChar(lSQL),-1,@vm,nil)=SQLITE_OK then
    begin
      sqlite3_step(vm);
      sqlite3_finalize(vm);
      result:=true;
    end;
  end;
end;

procedure AddPet(fname:PChar);
var
  p:PTL2Node;
  lpet:tpetinfo;
  i:integer;
begin
  p:=ParseDatFile(fname);
  lpet.scale:=1.0;
  lpet.textures:=0;
  for i:=0 to p^.childcount-1 do
  begin
    if CompareWide(p^.children^[i].name,'NAME') then
    begin
      lpet.name:=p^.children^[i].asString;
    end
    else if CompareWide(p^.children^[i].name,'DISPLAYNAME') then
    begin
      lpet.title:=p^.children^[i].asString;
    end
    else if CompareWide(p^.children^[i].name,'UNIT_GUID') then
    begin
      lpet.id:=p^.children^[i].asString;
    end
    else if CompareWide(p^.children^[i].name,'ARMOR_GRAPH') then
    begin
      lpet.gr_armor:=p^.children^[i].asString;
      if UpCase(lpet.gr_armor)<>'ARMOR_MINION_BYLEVEL' then
        writeln('Add ',lpet.gr_armor,' for pet Armor please');
    end
    else if CompareWide(p^.children^[i].name,'DAMAGE_GRAPH') then
    begin
      lpet.gr_dmg:=p^.children^[i].asString;
      if UpCase(lpet.gr_dmg)<>'DAMAGE_MINION_BYLEVEL' then
        writeln('Add ',lpet.gr_dmg,' for pet Damage please');
    end
    else if CompareWide(p^.children^[i].name,'HEALTH_GRAPH') then
    begin
      lpet.gr_hp:=p^.children^[i].asString;
      if UpCase(lpet.gr_hp)<>'HEALTH_MINION_BYLEVEL' then
        writeln('Add ',lpet.gr_hp,' for pet HP please');
    end
    else if CompareWide(p^.children^[i].name,'UNITTYPE') then
    begin
      if CompareWide(p^.children^[i].asString,'STARTING PET') then
        lpet.atype:=0
      else
        lpet.atype:=1;
    end
    else if CompareWide(p^.children^[i].name,'ICON') then
    begin
      lpet.icon:=ExtractFileNameOnly(p^.children^[i].asString);
    end
    else if CompareWide(p^.children^[i].name,'SCALE') then
    begin
      lpet.scale:=p^.children^[i].asFloat;
    end
    else if CompareWide(p^.children^[i].name,'TEXTURE_OVERRIDE_LIST') then
    begin
      lpet.textures:=p^.children^[i].childcount;
    end;
  end;
  if not AddPetToBase(lpet) then
    writeln('can''t update ',fname);
  DeleteNode(p);
end;

//----- Quests -----

function AddQuestToBase(const aname:string; aId:int64; const atitle:string):boolean;
var
  lSQL,sid:string;
  vm:pointer;
begin
  Str(aid,sid);
  result:=CheckForMod('quests', sid, smodid);
  if not result then
  begin
    lSQL:='INSERT INTO quests (id, name, title, modid) VALUES ('+
        sid+', '+FixedText(aname)+', '+FixedText(atitle)+', '' '+smodid+' '')';

    if sqlite3_prepare_v2(db,PChar(lSQL),-1,@vm,nil)=SQLITE_OK then
    begin
      sqlite3_step(vm);
      sqlite3_finalize(vm);
      result:=true;
    end;
  end;
end;

procedure AddQuest(fname:PChar);
var
  p:PTL2Node;
  name,title:string;
  lid:int64;
  i:integer;
begin
  p:=ParseDatFile(fname);
  title:='';
  lid:=-1;

  for i:=0 to p^.childcount-1 do
  begin
    if p^.children^[i].nodetype<>ntGroup then
    begin
      if CompareWide(p^.children^[i].name,'NAME') then
      begin
        name:=p^.children^[i].asString;
      end
      else if CompareWide(p^.children^[i].name,'QUEST_GUID') then
      begin
        lid:=p^.children^[i].asInteger64;
      end
      else if CompareWide(p^.children^[i].name,'DISPLAYNAME') then
      begin
        title:=p^.children^[i].asString;
      end;
    end;
  end;
  if lid<>-1 then
  begin
    if not AddQuestToBase(name,lid,title) then
      writeln('can''t update ',fname);
  end
  else
    writeln(' don''t added',fname);
  DeleteNode(p);
end;

//----- Stats -----

function AddStatToBase(const aname:string; aId:int64; const atitle:string; asaves:boolean):boolean;
var
  lSQL,sid,ssaves:string;
  vm:pointer;
begin
  Str(aid,sid);
  result:=CheckForMod('stats', sid, smodid);
  if not result then
  begin
    if asaves then ssaves:='1' else ssaves:='0';

    lSQL:='INSERT INTO stats (id, name, title, saves, modid) VALUES ('+
        sid+', '+FixedText(aname)+', '+FixedText(atitle)+', '+ssaves+', '' '+smodid+' '')';

    if sqlite3_prepare_v2(db,PChar(lSQL),-1,@vm,nil)=SQLITE_OK then
    begin
      sqlite3_step(vm);
      sqlite3_finalize(vm);
      result:=true;
    end;
  end;
end;

procedure AddStat(fname:PChar);
var
  p:PTL2Node;
  name,title:string;
  lid:int64;
  saves:boolean;
  i:integer;
begin
  p:=ParseDatFile(fname);
  title:='';
  saves:=false;
  for i:=0 to p^.childcount-1 do
  begin
    if CompareWide(p^.children^[i].name,'NAME') then
    begin
      name:=p^.children^[i].asString;
    end
    else if CompareWide(p^.children^[i].name,'UNIQUE_GUID') then
    begin
      lid:=p^.children^[i].asInteger64;
    end
    else if CompareWide(p^.children^[i].name,'SAVES') then
    begin
      saves:=p^.children^[i].asBoolean;
    end
    else if CompareWide(p^.children^[i].name,'DISPLAYNAME') then
    begin
      title:=p^.children^[i].asString;
    end;
  end;
  if not AddStatToBase(name,lid,title,saves) then
    writeln('can''t update ',fname);
  DeleteNode(p);
end;

//----- Recipes -----

function AddRecipeToBase(const aname:string; aId:int64; const atitle:string):boolean;
var
  lSQL,sid:string;
  vm:pointer;
begin
  Str(aid,sid);
  result:=CheckForMod('recipes', sid, smodid);
  if not result then
  begin
    lSQL:='INSERT INTO recipes (id, name, title, modid) VALUES ('+
        sid+', '+FixedText(aname)+', '+FixedText(atitle)+', '' '+smodid+' '')';

    if sqlite3_prepare_v2(db,PChar(lSQL),-1,@vm,nil)=SQLITE_OK then
    begin
      sqlite3_step(vm);
      sqlite3_finalize(vm);
      result:=true;
    end;
  end;
end;

procedure AddRecipe(fname:PChar);
var
  p:PTL2Node;
  name,title:string;
  lid:int64;
  i,mask:integer;
begin
  p:=ParseDatFile(fname);
  title:='';
  lid:=-1;

  mask:=0;
  for i:=0 to p^.childcount-1 do
  begin
    if p^.children^[i].nodetype<>ntGroup then
    begin
      if CompareWide(p^.children^[i].name,'NAME') then
      begin
        mask:=mask or 1;
        name:=p^.children^[i].asString;
      end
      else if CompareWide(p^.children^[i].name,'GUID') then
      begin
        mask:=mask or 2;
        lid:=p^.children^[i].asInteger64;
      end
      else if CompareWide(p^.children^[i].name,'RESULT') then
      begin
        mask:=mask or 4;
        title:=p^.children^[i].asString;
      end;
      if mask=7 then break;
    end;
  end;
  if lid<>-1 then
  begin
    if not AddRecipeToBase(name,lid,title) then
      writeln('can''t update ',fname);
  end
  else
    writeln(' don''t added ',fname);
  DeleteNode(p);
end;

//----- Mobs -----

function AddMobToBase(const anid,aname,atitle:string):boolean;
var
  lSQL:string;
  vm:pointer;
begin
  result:=CheckForMod('mobs', anid, smodid);
  if not result then
  begin
    lSQL:='INSERT INTO mobs (id, name, title, modid) VALUES ('+
        anid+', '+FixedText(aname)+', '+FixedText(atitle)+', '' '+smodid+' '')';

    if sqlite3_prepare_v2(db,PChar(lSQL),-1,@vm,nil)=SQLITE_OK then
    begin
      sqlite3_step(vm);
      sqlite3_finalize(vm);
      result:=true;
    end;
  end;
end;

procedure AddMob(fname:PChar);
var
  p:PTL2Node;
  lid,lname,ltitle:string;
  i,mask:integer;
begin
  if Pos('MEDIA\UNITS\MONSTERS\PETS'           ,fname)<>0 then exit;
  if Pos('MEDIA\UNITS\MONSTERS\WARBOUNDS'      ,fname)<>0 then exit;
  if Pos('MEDIA\UNITS\MONSTERS\BROTHER-IN-ARMS',fname)<>0 then exit;

  p:=ParseDatFile(fname);
  mask:=0;
  for i:=0 to p^.childcount-1 do
  begin
    if CompareWide(p^.children^[i].name,'NAME') then
    begin
      mask:=mask or 1;
      lname:=p^.children^[i].asString;
    end
    else if CompareWide(p^.children^[i].name,'DISPLAYNAME') then
    begin
      mask:=mask or 2;
      ltitle:=p^.children^[i].asString;
    end
    else if CompareWide(p^.children^[i].name,'UNIT_GUID') then
    begin
      mask:=mask or 4;
      lid:=p^.children^[i].asString;
    end;
    if mask=7 then break;
  end;
  if not AddMobToBase(lid,lname,ltitle) then
    writeln('can''t update ',fname);
  DeleteNode(p);
end;

//----- Items -----

type
  tItemInfo = record
    id   :string;
    name :string;
    title:string;
    descr:string;
    icon :string;
    auses:string;
    quest:string;
    afile:string;
    base :string;
  end;

function AddItemToBase(const aitem:tItemInfo):boolean;
var
  lSQL:string;
  vm:pointer;
begin
  result:=CheckForMod('items', aitem.id, smodid);
  if not result then
  begin
    lSQL:='INSERT INTO items (id, name, title, descr, icon, uses, quest, file, base, modid) VALUES ('+
        aitem.id+', '+FixedText(aitem.name)+', '+FixedText(aitem.title)+', '+FixedText(aitem.descr)+
        ', '+FixedText(aitem.icon)+', '+aitem.auses+', '+aitem.quest+
        ', '+FixedText(aitem.afile)+', '+FixedText(aitem.base)+', '' '+smodid+' '')';

    if sqlite3_prepare_v2(db,PChar(lSQL),-1,@vm,nil)=SQLITE_OK then
    begin
      sqlite3_step(vm);
      sqlite3_finalize(vm);
      result:=true;
    end;
  end;
end;

function GetBaseIcon(const fname:string):string;
var
  p:PTL2Node;
  lbase:string;
  i:integer;
begin
  result:='';
  lbase :='';
  p:=ParseDatFile(PChar(fname));
  if p=nil then
  begin
    writeln('can''t load: ',fname);
    exit;
  end;

  for i:=0 to p^.childcount-1 do
  begin
    if CompareWide(p^.children^[i].name,'ICON') then
    begin
      result:=p^.children^[i].asString;
      break;
    end;
    if CompareWide(p^.children^[i].name,'BASEFILE') then
    begin
      lbase:=p^.children^[i].asString;
    end;
  end;

  if (result='') and (lbase<>'') then
    result:=GetBaseIcon(lbase);

  DeleteNode(p);
end;

procedure AddItem(fname:PChar);
var
  p:PTL2Node;
  litem:tItemInfo;
  i:integer;
begin
  p:=ParseDatFile(fname);
  litem.title:='';
  litem.auses:='0';
  litem.base :='';
  litem.afile:=fname;

  if Pos('MEDIA\UNITS\ITEMS\QUEST_ITEMS\',fname)>0 then litem.quest:='1' else litem.quest:='0';
  for i:=0 to p^.childcount-1 do
  begin
    if CompareWide(p^.children^[i].name,'NAME') then
    begin
      litem.name:=p^.children^[i].asString;
    end
    else if CompareWide(p^.children^[i].name,'DISPLAYNAME') then
    begin
      litem.title:=p^.children^[i].asString;
    end
    else if CompareWide(p^.children^[i].name,'DESCRIPTION') then
    begin
      litem.descr:=p^.children^[i].asString;
    end
    else if CompareWide(p^.children^[i].name,'ICON') then
    begin
      litem.icon:=ExtractFileNameOnly(p^.children^[i].asString);
    end
    else if CompareWide(p^.children^[i].name,'BASEFILE') then
    begin
      litem.base:=p^.children^[i].asString;
    end
    else if CompareWide(p^.children^[i].name,'UNIT_GUID') then
    begin
      litem.id:=p^.children^[i].asString;
    end
    else if (litem.quest='0') and CompareWide(p^.children^[i].name,'UNITTYPE') then
    begin
      if CompareWide(p^.children^[i].asString,'LEVEL ITEM') or 
         CompareWide(p^.children^[i].asString,'QUESTITEM') then
           litem.quest:='1';
    end
    else if CompareWide(p^.children^[i].name,'USES') then
    begin
      litem.auses:=p^.children^[i].asString;
    end;
  end;
  if (litem.icon='') and (litem.base<>'') then
    litem.icon:=GetBaseIcon(litem.base);
  if litem.icon='' then writeln('No icon for ',fname);

  if not AddItemToBase(litem) then
    writeln('can''t update ',fname);
  DeleteNode(p);
end;

//----- Props -----

function AddPropToBase(const anid,aname,atitle,aquest:string):boolean;
var
  lSQL:string;
  vm:pointer;
begin
  result:=CheckForMod('props', anid, smodid);
  if not result then
  begin
    lSQL:='INSERT INTO props (id, name, title, quest, modid) VALUES ('+
        anid+', '+FixedText(aname)+', '+FixedText(atitle)+', '+
        aquest+', '' '+smodid+' '')';

    if sqlite3_prepare_v2(db,PChar(lSQL),-1,@vm,nil)=SQLITE_OK then
    begin
      sqlite3_step(vm);
      sqlite3_finalize(vm);
      result:=true;
    end;
  end;
end;

procedure AddProp(fname:PChar);
var
  p:PTL2Node;
  lid,lname,ltitle,lquest:string;
  i:integer;
begin
  p:=ParseDatFile(fname);
  ltitle:='';
  if Pos('MEDIA\UNITS\PROPS\QUESTPROPS\',fname)>0 then lquest:='1' else lquest:='0';
  for i:=0 to p^.childcount-1 do
  begin
    if CompareWide(p^.children^[i].name,'NAME') then
    begin
      lname:=p^.children^[i].asString;
    end
    else if CompareWide(p^.children^[i].name,'DISPLAYNAME') then
    begin
      ltitle:=p^.children^[i].asString;
    end
    else if CompareWide(p^.children^[i].name,'UNIT_GUID') then
    begin
      lid:=p^.children^[i].asString;
    end;
{
    else if (lquest='0') and CompareWide(p^.children^[i].name,'UNITTYPE') then
    begin
    end
}
  end;
  if not AddPropToBase(lid,lname,ltitle,lquest) then
    writeln('can''t update ',fname);
  DeleteNode(p);
end;

//----- Skills -----

type
  tSkillInfo = record
    id     :string;
    name   :string;
    title  :string;
    descr  :string;
    graph  :string;
    icon   :string;
    minlvl :string;
    maxlvl :string;
    passive:char;
    shared :char;
  end;

function AddSkillToBase(const askill:tSkillInfo):boolean;
var
  lSQL:string;
  vm:pointer;
begin
  result:=CheckForMod('skills', askill.id, smodid);
  if not result then
  begin
    lSQL:='INSERT INTO skills (id, name, title, descr, tier, icon,'+
          ' minlevel, maxlevel, passive, shared, modid) VALUES ('+
        askill.id+', '+FixedText(askill.name)+', '+FixedText(askill.title)+', '+FixedText(askill.descr)+
        ', '''+askill.graph+''', '+FixedText(askill.icon)+', '+
        askill.minlvl+', '+askill.maxlvl+', '+askill.passive+', '+askill.shared+', '' '+smodid+' '')';

    if sqlite3_prepare_v2(db,PChar(lSQL),-1,@vm,nil)=SQLITE_OK then
    begin
      sqlite3_step(vm);
      sqlite3_finalize(vm);
      result:=true;
    end;
  end;
end;

procedure AddSkill(fname:PChar);
var
  p,pp,ppp:PTL2Node;
  lskill:TSkillInfo;
  levels:array [0..63] of integer;
  ls:string;
  minlevel,i,j,lcnt:integer;
  haslevels:boolean;
begin
  p:=ParseDatFile(fname);

  fillchar(levels,SizeOf(levels),0);
  fillchar(lskill,sizeof(lskill),0);

  if Pos('MEDIA\SKILLS\SHARED',fname)>0 then
    lskill.shared:='1'
  else
    lskill.shared:='0';

  lskill.passive:='0';
  lskill.minlvl :='0';

  lcnt:=0;
  haslevels:=false;
  minlevel:=0;

  for i:=0 to p^.childcount-1 do
  begin
    pp:=@p^.children^[i];

    if CompareWide(pp^.name,'NAME') then
    begin
      lskill.name:=pp^.asString;
    end
    else if CompareWide(pp^.name,'DISPLAYNAME') then
    begin
      lskill.title:=pp^.asString;
    end
    else if CompareWide(pp^.name,'DESCRIPTION') then
    begin
      lskill.descr:=pp^.asString;
    end
    else if CompareWide(pp^.name,'BASE_DESCRIPTION') then
    begin
      lskill.descr:=pp^.asString;
    end
    else if CompareWide(pp^.name,'REQUIREMENT_GRAPH') then
    begin
      lskill.graph:=pp^.asString;
    end
    else if CompareWide(pp^.name,'ACTIVATION_TYPE') then
    begin
      if pp^.asString='PASSIVE' then
        lskill.passive:='1';
    end
    else if CompareWide(pp^.name,'SKILL_ICON') then
    begin
      lskill.icon:=pp^.asString;
    end
    else if CompareWide(pp^.name,'LEVEL_REQUIRED') then
    begin
      Str(pp^.asInteger,lskill.minlvl);
    end
    else if CompareWide(pp^.name,'UNIQUE_GUID') then
    begin
      Str(pp^.asInteger64,lskill.id);
    end;
    if (pp^.nodeType=ntGroup) and (Pos('LEVEL',WideString(pp^.name))=1) then
    begin
      for j:=0 to pp^.childcount-1 do
      begin
        ppp:=@pp^.children^[j];
        if CompareWide(ppp^.name,'LEVEL_REQUIRED') then
        begin
          levels[lcnt]:=ppp^.asInteger;
          if minlevel>levels[lcnt] then minlevel:=levels[lcnt];
          if levels[lcnt]>0 then
            haslevels:=true;
        end;
      end;
      inc(lcnt);
    end;
  end;

  if lskill.minlvl='0' then
  begin
    if minlevel=0 then
    begin
      pp:=FindNode(p,'LEVEL1/EVENT_TRIGGER/AFFIXES/AFFIXLEVEL');
      if pp<>nil then
        minlevel:=pp^.AsInteger;
    end;
    if minlevel<0 then minlevel:=0;
    Str(minlevel,lskill.minlvl);
  end;

  if lcnt=0 then
    lcnt:=1;
  Str(lcnt,lskill.maxlvl);

  if (lskill.graph='') and haslevels then
  begin
    lskill.graph:=',';
    for i:=0 to lcnt-1 do
    begin
      Str(levels[i],ls);
      lskill.graph:=lskill.graph+ls+',';
    end;
  end;

  if not AddSkillToBase(lskill) then
    writeln('can''t update ',fname);

  DeleteNode(p);
end;

//----- Classes -----

type
  tclassinfo = record
    id       :string;
    name     :string;
    title    :string;
    descr    :string;
    afile    :string;
    base     :string;
    skill    :string;
    icon     :string;
    gr_hp    :string;
    gr_mp    :string;
    gr_st    :string;
    gr_sk    :string;
    gr_fm    :string;
    strength :string;
    dexterity:string;
    magic    :string;
    defense  :string;
    gender   :string;
  end;

function AddClassToBase(const aclass:tclassinfo):boolean;
var
  lSQL,lfile,lbase:string;
  vm:pointer;
  i:integer;
begin
  result:=CheckForMod('classes', aclass.id, smodid);
  if not result then
  begin
    lfile:=LowerCase(aclass.afile);
    for i:=1 to Length(lfile) do if lfile[i]='\' then lfile[i]:='/';
    lbase:=LowerCase(aclass.base);
    for i:=1 to Length(lbase) do if lbase[i]='\' then lbase[i]:='/';
    lSQL:='INSERT INTO classes (id, name, title, descr,'+
          ' file, base, skills, icon,'+
          ' graph_hp, graph_mp, graph_stat, graph_skill, graph_fame,'+
          ' gender, strength, dexterity, magic, defense,'+
          ' modid) VALUES ('+
        aclass.id+', '+FixedText(aclass.name)+', '+FixedText(aclass.title)+', '+FixedText(aclass.descr)+
        ', '''+lfile+''', '''+lbase+''', '+FixedText(aclass.skill)+', '+FixedText(aclass.icon)+
        ', '''+aclass.gr_hp+''', '''+aclass.gr_mp+''', '''+aclass.gr_st+
        ''', '''+aclass.gr_sk+''', '''+aclass.gr_fm+''', '''+aclass.gender+
        ''', '+aclass.strength+', '+aclass.dexterity+', '+aclass.magic+', '+aclass.defense+
        ','' '+smodid+' '')';
    
    if sqlite3_prepare_v2(db,PChar(lSQL),-1,@vm,nil)=SQLITE_OK then
    begin
      sqlite3_step(vm);
      sqlite3_finalize(vm);
      result:=true;
    end;
  end;
end;

procedure AddPlayer(fname:PChar);
var
  p:PTL2Node;
  lclass:tclassinfo;
  lunittype,lsname,lslevel:string;
  i,j:integer;
begin
  p:=ParseDatFile(fname);

  lclass.title:='';
  lclass.skill:=',';
  lclass.strength :='0';
  lclass.dexterity:='0';
  lclass.magic    :='0';
  lclass.defense  :='0';
  lunittype:='';

  for i:=0 to p^.childcount-1 do
  begin
    if CompareWide(p^.children^[i].name,'BASEFILE') then
    begin
      lclass.base:=p^.children^[i].asString;
    end
    else if CompareWide(p^.children^[i].name,'NAME') then
    begin
      lclass.name:=p^.children^[i].asString;
    end
    else if CompareWide(p^.children^[i].name,'DISPLAYNAME') then
    begin
      lclass.title:=p^.children^[i].asString;
    end
    else if CompareWide(p^.children^[i].name,'DESCRIPTION') then
    begin
      lclass.descr:=p^.children^[i].asString;
    end

    else if CompareWide(p^.children^[i].name,'UNITTYPE') then
    begin
      lunittype:=p^.children^[i].asString;
    end

    else if CompareWide(p^.children^[i].name,'STRENGTH') then
    begin
      Str(p^.children^[i].asInteger,lclass.strength);
    end
    else if CompareWide(p^.children^[i].name,'DEXTERITY') then
    begin
      Str(p^.children^[i].asInteger,lclass.dexterity);
    end
    else if CompareWide(p^.children^[i].name,'MAGIC') then
    begin
      Str(p^.children^[i].asInteger,lclass.magic);
    end
    else if CompareWide(p^.children^[i].name,'DEFENSE') then
    begin
      Str(p^.children^[i].asInteger,lclass.defense);
    end

    else if CompareWide(p^.children^[i].name,'ICON') then
    begin
      lclass.icon:=ExtractFileNameOnly(p^.children^[i].asString);
    end
    else if CompareWide(p^.children^[i].name,'MANA_GRAPH') then
    begin
      lclass.gr_mp:=p^.children^[i].asString;
      if UpCase(lclass.gr_mp)<>'MANA_PLAYER_GENERIC' then
        writeln('Add ',lclass.gr_mp,' for class MP please');
    end
    else if CompareWide(p^.children^[i].name,'HEALTH_GRAPH') then
    begin
      lclass.gr_hp:=p^.children^[i].asString;
      if UpCase(lclass.gr_hp)<>'HEALTH_PLAYER_GENERIC' then
        writeln('Add ',lclass.gr_hp,' for class HP please');
    end
    else if CompareWide(p^.children^[i].name,'STAT_POINTS_PER_LEVEL') then
    begin
      lclass.gr_st:=p^.children^[i].asString;
      if UpCase(lclass.gr_st)<>'STAT_POINTS_PER_LEVEL' then
        writeln('Add ',lclass.gr_st,' for class STAT please');
    end
    else if CompareWide(p^.children^[i].name,'SKILL_POINTS_PER_LEVEL') then
    begin
      lclass.gr_sk:=p^.children^[i].asString;
      if UpCase(lclass.gr_sk)<>'SKILL_POINTS_PER_LEVEL' then
        writeln('Add ',lclass.gr_sk,' for class SKILL please');
    end
    else if CompareWide(p^.children^[i].name,'SKILL_POINTS_PER_FAME_LEVEL') then
    begin
      lclass.gr_fm:=p^.children^[i].asString;
      if UpCase(lclass.gr_fm)<>'SKILL_POINTS_PER_FAME_LEVEL' then
        writeln('Add ',lclass.gr_fm,' for class FAME please');
    end
    else if CompareWide(p^.children^[i].name,'UNIT_GUID') then
    begin
      lclass.id:=p^.children^[i].asString;
    end;

    if CompareWide(p^.children^[i].name,'SKILL') then
    begin
      lsname :='';
      lslevel:='';
      with p^.children^[i] do
        for j:=0 to childcount-1 do
        begin
          if CompareWide(children^[j].name,'NAME') then
          begin
            lsname:=children^[j].asString;
          end
          else if CompareWide(children^[j].name,'LEVEL') then
          begin
            Str(children^[j].asInteger,lslevel);
          end;
        end;

      if lsname<>'' then
      begin
        if lslevel<>'' then lsname:=lsname+'#'+lslevel;
        lclass.skill:=lclass.skill+lsname+',';
      end;

    end;

  end;
  DeleteNode(p);

  lclass.gender:='';
  if lunittype<>'' then
  begin
    p:=ParseDatFile(PChar('MEDIA\UNITTYPES\'+lunittype+'.DAT'));
    if p<>nil then
      for i:=0 to p^.childcount-1 do
      begin
        if CompareWide(p^.children^[i].asString,'PLAYER_FEMALE') then
        begin
          lclass.gender:='F';
          break;
        end
        else if CompareWide(p^.children^[i].asString,'PLAYER_MALE') then
        begin
          lclass.gender:='M';
          break;
        end

      end;
    DeleteNode(p);
  end;
  if lclass.gender='' then
  begin
    i:=Length(lclass.name);
    if lclass.name[i-1]='_' then
    begin
      if UpCase(lclass.name[i])='M' then lclass.gender:='M';
      if UpCase(lclass.name[i])='F' then lclass.gender:='F';
    end;
  end;

  if lclass.skill=',' then lclass.skill:='';
  lclass.afile:=fname;
  if not AddClassToBase(lclass) then
    writeln('can''t update ',fname);
end;

//----- main cycle -----

procedure CycleDir(const adir:AnsiString; aproc:tScanProc);
var
  sr:TSearchRec;
  lname:AnsiString;
begin
  if FindFirst(adir+'\*.*',faAnyFile and faDirectory,sr)=0 then
  begin
    repeat
      lname:=adir+'\'+sr.Name;
      if (sr.Attr and faDirectory)=faDirectory then
      begin
        if (sr.Name<>'.') and (sr.Name<>'..') then
          CycleDir(lname,aproc);
      end
      else
      begin
        if UpCase(ExtractFileExt(lname))='.DAT' then
        begin
          aproc(PChar(lname));
        end;
      end;
    until FindNext(sr)<>0;
    FindClose(sr);
  end;
end;

//----- MOD info -----

procedure AddTheMod();
var
  lSQL,lid:string;
  vm:pointer;
  lver:integer;
  lmod:TTL2ModInfo;
begin
  if ReadModInfo('MOD.DAT',lmod) then
  begin
    lid :=IntToStr(lmod.modid);
    lSQL:='SELECT version FROM Mods WHERE id='+lid;
    lver:=0;
    if sqlite3_prepare_v2(db,PChar(lSQL),-1,@vm,nil)=SQLITE_OK then
    begin
      if sqlite3_step(vm)=SQLITE_OK then
        lver:=sqlite3_column_int(vm,0);
      sqlite3_finalize(vm);
    end;

    if lver<>0 then
    begin
      if lmod.modver>=lver then exit;
      lSQL:='UPDATE Mods SET version='+IntToStr(lmod.modver)+' WHERE id='+lid;
    end
    else
    begin
      lSQL:='INSERT INTO Mods (id,title,version,gamever,author,descr,website,download) '+
            ' VALUES ('+lid+', '+FixedText(lmod.title)+', '+IntToStr(lmod.modver)+
            ', '+IntToStr(lmod.gamever)+', '+FixedText(lmod.author)+', '+FixedText(lmod.descr)+
            ', '+FixedText(lmod.website)+', '+FixedText(lmod.download)+')';
    end;
    if sqlite3_prepare_v2(db,PChar(lSQL),-1,@vm,nil)=SQLITE_OK then
    begin
      sqlite3_step(vm);
      sqlite3_finalize(vm);
    end;
  end;
end;

//===== Body =====

var
  p,pp:PTL2Node;
  ls:string;
  modid:int64;
  lcnt:integer;
begin
  lcnt:=ParamCount();
  ls:=ParamStr(1);

  AddTheMod();

  p:=ParseDatFile('MOD.DAT');
  pp:=FindNode(p,'MOD_ID');
  modid:=pp^.asInteger64;
  DeleteNode(p);

  Str(modid,smodid);

  sqlite3_open(':memory:',@db);
  if CopyFromFile(db,'tl2db2.db')<>SQLITE_OK then
  begin
    writeln('can''t open');
    exit;
  end;
//  sqlite3_exec(db,'Begin Transaction',nil,nil,nil);

  // Pets
  if (lcnt=0) or (ls='pets') then
  begin
    writeln('Go pets!');
    CycleDir('MEDIA\UNITS\MONSTERS\PETS'           ,@AddPet);
    CycleDir('MEDIA\UNITS\MONSTERS\WARBOUNDS'      ,@AddPet);
    CycleDir('MEDIA\UNITS\MONSTERS\BROTHER-IN-ARMS',@AddPet);
  end;

  // Quests
  if (lcnt=0) or (ls='quests') then
  begin
    writeln('Go quests!');
    CycleDir('MEDIA\QUESTS',@AddQuest);
  end;

  // Stats
  if (lcnt=0) or (ls='stats') then
  begin
    writeln('Go stats!');
    CycleDir('MEDIA\STATS',@AddStat);
  end;

  // Recipes
  if (lcnt=0) or (ls='recipes') then
  begin
    writeln('Go recipes!');
    CycleDir('MEDIA\RECIPES',@AddRecipe);
  end;

  // Mobs
  if (lcnt=0) or (ls='mobs') then
  begin
    writeln('Go mobs!');
    CycleDir('MEDIA\UNITS\MONSTERS',@AddMob);
  end;

  // Items
  if (lcnt=0) or (ls='items') then
  begin
    writeln('Go items!');
    CycleDir('MEDIA\UNITS\ITEMS',@AddItem);
  end;

  // Props
  if (lcnt=0) or (ls='props') then
  begin
    writeln('Go props!');
    CycleDir('MEDIA\UNITS\PROPS',@AddProp);
  end;

  // Skills
  if (lcnt=0) or (ls='skills') then
  begin
    writeln('Go skills!');
    CycleDir('MEDIA\SKILLS',@AddSkill);
  end;

  // Classes
  if (lcnt=0) or (ls='classes') then
  begin
    writeln('Go classes!');
    CycleDir('MEDIA\UNITS\PLAYERS',@AddPlayer);
  end;

//  sqlite3_exec(db,'End Transaction',nil,nil,nil);
  CopyToFile(db,'tl2db2.db');
  sqlite3_close(db);
end.
