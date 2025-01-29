{TODO: Copy existing icons from TL2 to TL1}
{$IFDEF Interface}

type
  tPetArray = array of record
    id   :TRGID;
    name :string;
    title:string;
    scale:single;
    icon :string;
  end;

function RGDBGetPet    (const aid:TRGID; out amods:string):string; overload;
function RGDBGetPet    (const aid:TRGID                  ):string; overload;

function RGDBGetPetMods (const aid:TRGID):string;
function RGDBGetPetIcon (const aid:TRGID):string;
function RGDBGetPetSkins(const aid:TRGID):integer;

function RGDBGetPetList(out alist:tPetArray):integer;
function RGDBGetDefaultPet:TRGID;

{$ELSE}

const
  dbPetTable = 'pets';

const
  tl1petstart = 21;
  DefaultPets: tPetArray = (
    // TL2
    (id:-8880591480184383566; name:'Pet_Cat'        ; title:'Cat'        ; scale:0.65; icon:'lynxicon'),
    (id:-8742058185063171412; name:'Pet_Jackalbeast'; title:'Jackalbeast'; scale:0.75; icon:''),
    (id:-6861078633348114419; name:'Pet_Hawk'       ; title:'Hawk'       ; scale:1   ; icon:'hawkicon'),
    (id:-6861072635378114419; name:'Pet_Flyer'      ; title:'Swampflyer' ; scale:1   ; icon:''),
    (id:-6082309300095414029; name:'Pet_Falcor'     ; title:'Papillon'   ; scale:0.8 ; icon:'falcoricon'),
    (id:-4272058185063171412; name:'Pet_Crab'       ; title:'Crab'       ; scale:1   ; icon:''),
    (id:-2472058185064571412; name:'Pet_Wolf'       ; title:'Wolf'       ; scale:0.75; icon:'dogicon'),
    (id:-2472058185064571327; name:'Pet_BigCat'     ; title:'Panther'    ; scale:1   ; icon:'bigcaticon'),
    (id:-2472058185032171412; name:'Pet_Warbeast'   ; title:'Warbeast'   ; scale:0.8 ; icon:''),
    (id:-2412341850671171412; name:'Pet_Molebeast'  ; title:'Molebeast'  ; scale:1.15; icon:''),
    (id:-1672582398143053873; name:'Pet_Alpaca'     ; title:'Alpaca'     ; scale:1   ; icon:'alpacaicon'),
    (id:-1144795368701180224; name:'Pet_Chakawary'  ; title:'Chakawary'  ; scale:0.75; icon:'chakawaryicon'),
    (id:-18242231495209399  ; name:'Pet_HeadcrabA'  ; title:'Headcrab'   ; scale:1   ; icon:'headcrabicon'),
    (id:2236371573517850133 ; name:'Pet_torso'      ; title:'Torso'      ; scale:1.25; icon:''),
    (id:2846508072355823983 ; name:'Pet_Bulldog'    ; title:'Bulldog'    ; scale:1   ; icon:'bulldogicon'),
    (id:2947367154991955139 ; name:'Pet_PandaA'     ; title:'Panda'      ; scale:1   ; icon:'pandaicon'),
    (id:6085265292355965406 ; name:'Pet_Ferret'     ; title:'Ferret'     ; scale:1   ; icon:'ferreticon'),
    (id:6212525112683485562 ; name:'Pet_Deer'       ; title:'Stag'       ; scale:1   ; icon:'deericon'),
    (id:6516037093941808301 ; name:'Pet_Owl'        ; title:'Owl'        ; scale:1   ; icon:'owlicon'),
    (id:7002609406216574240 ; name:'Pet_Spider'     ; title:'Spider'     ; scale:0.8 ; icon:''),
    (id:7846508072355823983 ; name:'Pet_HoneyBadger'; title:'Badger'     ; scale:1   ; icon:'badgericon'),

    // TL1
    (id:6655120081984033246 ; name:'Cat'                  ; title:'Cat'               ; scale:0.75; icon:''),
    (id:-3195029593784249890; name:'Dog'                  ; title:'Dog'               ; scale:0.85; icon:''),
    (id:1343088339509383646 ; name:'Pet Imaginary'        ; title:'Imaginary'         ; scale:0.85; icon:''),
    (id:-7605033305437564450; name:'Pet ElementalFire'    ; title:'Fire Elemental'    ; scale:0.6 ; icon:''),
    (id:-6814372775916924450; name:'Pet ElementalIce'     ; title:'Ice Elemental'     ; scale:0.6 ; icon:''),
    (id:-6143069387552124450; name:'Pet ElementalPoison'  ; title:'Poison Elemental'  ; scale:0.6 ; icon:''),
    (id:-5450171995450830370; name:'Pet Spider'           ; title:'Spider'            ; scale:1   ; icon:''),
    (id:-4598024974468640290; name:'Aloe Gel'             ; title:'Aloe Gel'          ; scale:0.4 ; icon:''),
    (id:-4167721604410830370; name:'Pet Varkolyn'         ; title:'Varkolyn'          ; scale:1   ; icon:''),
    (id:-550131638619598370 ; name:'Pet ElementalElectric'; title:'Electric Elemental'; scale:0.6 ; icon:''),
    (id:1701168610042778078 ; name:'Pet Burrower'         ; title:'Burrower'          ; scale:1   ; icon:''),
    (id:2689284772225815006 ; name:'Pet Troll'            ; title:'Troll'             ; scale:1   ; icon:''),
    (id:5391124521138721246 ; name:'Pet Gel'              ; title:'Gel'               ; scale:1   ; icon:''),
    (id:6085265292355965406 ; name:'Ferret'               ; title:'Ferret'            ; scale:1   ; icon:''),
    (id:7931060729150640606 ; name:'Pet Goblinhound'      ; title:'Goblinhound'       ; scale:1   ; icon:''),
    (id:992310930692641246  ; name:'RootGolemPet'         ; title:'Thorned Strider'   ; scale:0.7 ; icon:''),
    (id:1864924804405793246 ; name:'Pet Mimic'            ; title:'Mimic'             ; scale:1   ; icon:'')
  );

function RGDBGetPet(const aid:TRGID; out amods:string):string;
var
  lname:string;
  i:integer;
begin
  if db=nil then
  begin
    amods:='';
    for i:=0 to High(DefaultPets) do
    begin
      if DefaultPets[i].id=aid then
      begin
        result:=DefaultPets[i].title;
        exit;
      end;
    end;
    result:='';
  end
  else
    result:=GetById(aid,dbPetTable,'',amods,lname);
end;

function RGDBGetPet(const aid:TRGID):string;
var
  lmods:string;
begin
  result:=RGDBGetPet(aid,lmods);
end;

function RGDBGetPetIcon(const aid:TRGID):string;
begin
  result:=RGDBGetTextValue(aid,dbPetTable,'icon');
end;

function RGDBGetPetMods(const aid:TRGID):string;
begin
  result:=RGDBGetTextValue(aid,dbPetTable,'modid');
end;

function RGDBGetPetSkins(const aid:TRGID):integer;
begin
  result:=RGDBGetIntValue(aid,dbPetTable,'skins');
end;

//----- List -----

function RGDBGetPetList(out alist:tPetArray):integer;
var
  lwhere,lSQL:string;
  vm:pointer;
  i:integer;
begin
  if db<>nil then
  begin
    if ModFilter<>'' then
      lwhere:=' WHERE '+ModFilter
    else
      lwhere:='';

    result:=ReturnInt(db,'SELECT count(*) FROM '+dbPetTable+lwhere);

    if result>0 then
    begin
      SetLength(alist,result);
      lSQL:='SELECT id, name, title, scale, icon FROM '+dbPetTable+lwhere;

      if sqlite3_prepare_v2(db, PAnsiChar(lSQL),-1, @vm, nil)=SQLITE_OK then
      begin
        i:=0;
        while {(i<result) and} (sqlite3_step(vm)=SQLITE_ROW) do
        begin
          alist[i].id   :=sqlite3_column_int64 (vm,0);
          alist[i].name :=sqlite3_column_text  (vm,1);
          alist[i].title:=sqlite3_column_text  (vm,2);
          alist[i].scale:=sqlite3_column_double(vm,3);
          alist[i].icon :=sqlite3_column_text  (vm,4);
          inc(i);
        end;
        sqlite3_finalize(vm);
      end;
    end;
  end
  else
  begin
    if GameVersion=verTL1 then
    begin
      alist:=Copy(DefaultPets,tl1petstart);
      result:=Length(DefaultPets)-tl1petstart;
    end
    else
    begin
      alist:=Copy(DefaultPets,0,tl1petstart);
      result:=tl1petstart;
    end;
  end;
end;

function RGDBGetDefaultPet:TRGID;
begin
  if GameVersion=verTL1 then
    result:=DefaultPets[tl1petstart].id
  else
    result:=DefaultPets[0].id;
end;

{$ENDIF}
