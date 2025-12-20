unit RGSkeleton;

interface

uses
  Classes,
  rgglobal,
  rg3dshared;

type
  TRGSkeleton = object
  private
    type
      TAnimLink = record
        skeletonName:AnsiString;
        scale       :single;
      end;

      TBone = record
        name    :AnsiString;
        handle  :word;       // i think, can be ignored coz MUST BE the same as apper order (from 0)
        position:TVector3;
        orient  :TVector4;
        scale   :TVector3;
      end;

      TKeyFrame = record
        time     :Single;
        rotate   :TVector4;
        translate:TVector3;
        scale    :TVector3;
      end;

      TAnimation = record
        name             :AnsiString;
        baseAnimationName:AnsiString;
        len              :Single;
        baseKeyframeTime :Single;
        TrackCount       :integer;
        Tracks:array of record
          boneIndex :integer;
          FrameCount:integer;
          Frames    :array of TKeyFrame;
        end;

      end;

  private
    FVersion   :integer;
    FBuffer    :PByte;
    FDataSize  :integer;
    FBones     :array of TBone;
    FHierarchy :array of record
      handle:word;
      parent:word;
    end;
    FAnimLinks :array of TAnimLink;
    FAnimations:array of TAnimation;

    FBoneCount     :integer;
    FHierarchyCount:integer; // must be same as FBoneCount
    FAnimationCount:integer;
    FAnimLinkCount :integer;

    function  ReadChunk(var aptr:PByte; out achunk:TOgreChunk):word;
  public
    blendMode:word;

    procedure Init;
    procedure Free;

    procedure ReadTrack    (var aptr:PByte);
    procedure ReadAnimation(var aptr:PByte);
    function  ReadSkeleton (var aptr:PByte):boolean;
    function  ImportFromMemory (aptr:PByte; asize:integer):boolean;
    function  ImportFromFile   (const aFileName:string   ):boolean;

    procedure WriteAnimation(astream:TStream; aver:integer);
    procedure WriteBones    (astream:TStream; aver:integer);
    procedure WriteSkeleton (astream:TStream; aver:integer);

    procedure SaveToXML(astream:TStream);
    procedure SaveToXML(const aFileName:String);
  end;


implementation

uses
  Math,
  SysUtils,
  rwmemory,
  rgstream;

procedure FromAngleAxis(rfAngle:single; const rkAxis:TVector3; var dst:TVector4);
var
  fHalfAngle:Single;
  fSin:Single;
begin
  // assert:  axis[] is unit length
  //
  // The quaternion representing the rotation is
  //   q = cos(A/2)+sin(A/2)*(x*i+y*j+z*k)

  fHalfAngle := 0.5*rfAngle;
  dst.w := Cos(fHalfAngle);

  fSin  := Sin(fHalfAngle);
  dst.x := fSin*rkAxis.x;
  dst.y := fSin*rkAxis.y;
  dst.z := fSin*rkAxis.z;
end;

procedure ToAngleAxis(src:TVector4; var rfAngle:Single; var rkAxis:TVector3);
var
  fSqrLength:Single;
  fInvLength:Single;
begin
  // The quaternion representing the rotation is
  //   q = cos(A/2)+sin(A/2)*(x*i+y*j+z*k)

  fSqrLength := src.x*src.x+src.y*src.y+src.z*src.z;
  if fSqrLength > 0.0 then
  begin
    rfAngle := 2.0*ArcCos(src.w);

    fInvLength := 1/Sqrt(fSqrLength);
    rkAxis.x := src.x*fInvLength;
    rkAxis.y := src.y*fInvLength;
    rkAxis.z := src.z*fInvLength;
  end
  else
  begin
    // angle is 0 (mod 2*pi), so any axis will do
    rfAngle  := 0.0;
    rkAxis.x := 1.0;
    rkAxis.y := 0.0;
    rkAxis.z := 0.0;
  end;
end;

function GetChunkName(aid:word):string;
var
  i:integer;
begin
  for i:=0 to High(SkeletonChunkNames) do
    if SkeletonChunkNames[i].id=aid then exit(SkeletonChunkNames[i].name);

  result:='';
end;

function GetFileVersion(var abuf:PByte):integer;
var
  ls:AnsiString;
begin
  result:=-1;
  if memReadWord(abuf)=SKELETON_HEADER then
  begin
    ls:=memReadText(abuf);
    result:=TranslateVersion(ls);
    if not result in [110,180] then
      Log('version',ls+' not supported')
    else
      Log('version',ls);
  end;
end;

procedure TRGSkeleton.Init;
begin
  FillChar(self,SizeOf(self),0);
end;

procedure TRGSkeleton.Free;
var
  i,j:integer;
begin
  for i:=0 to FAnimationCount-1 do
  begin
    with FAnimations[i] do
    begin
      for j:=0 to TrackCount-1 do
        SetLength(Tracks[j].Frames,0);
      SetLength(Tracks,0);
    end;
  end;

  SetLength(FBones     ,0);
  SetLength(FHierarchy ,0);
  SetLength(FAnimations,0);
  SetLength(FAnimLinks ,0);
end;

function TRGSkeleton.ReadChunk(var aptr:PByte; out achunk:TOgreChunk):word;
var
  ls:string;
begin
  achunk._type:=memReadWord (aptr);
  achunk._len :=memReadDWord(aptr);
  result:=achunk._type;

//  if RGDebugLevel=dlDetailed then
  begin
    ls:='Chunk type: 0x'+HexStr(achunk._type,4)+' '+GetChunkName(achunk._type)+
           '; offset=0x'+HexStr(aptr-FBuffer,8)+
           '; length=0x'+HexStr(achunk._len ,4)+' ('+IntToStr(achunk._len)+
            ')';
//            '); offset=0x'  +HexStr(abuf-FBuffer-SizeOf(achunk),8);
    Log(ls);
  end;
end;

procedure TRGSkeleton.ReadTrack(var aptr:PByte);
var
  lchunk:TOgreChunk;
  lpos:PByte;
begin
  with FAnimations[FAnimationCount] do
  begin
    if TrackCount=Length(Tracks) then
      SetLength(Tracks,Length(Tracks)+32);

    with Tracks[TrackCount] do
    begin
      boneIndex:=memReadWord(aptr);

      FrameCount:=0;
      Frames    :=nil;

      while (aptr<(FBuffer+FDataSize)) and
           (ReadChunk(aptr,lchunk)=SKELETON_ANIMATION_TRACK_KEYFRAME) do
      begin
        lpos:=aptr-SizeOf(TOgreChunk);

        if FrameCount=Length(Frames) then
          SetLength(Frames,Length(Frames)+32);

        with Frames[FrameCount] do
        begin
          time:=memReadFloat(aptr);
          memRead(aptr,rotate   ,SizeOf(TVector4));
          memRead(aptr,translate,SizeOf(TVector3));
          //!! can be absent
          if (lpos+lchunk._len)>=(aptr+SizeOf(TVector3)) then
            memRead(aptr,scale,SizeOf(TVector3))
          else
          begin
            scale.X:=1;
            scale.Y:=1;
            scale.Z:=1;
          end;
        end;
        inc(FrameCount);
      end;
      if lchunk._type<>SKELETON_ANIMATION_TRACK_KEYFRAME then
        dec(aptr,SizeOf(TOgreChunk));
    end;
    inc(TrackCount);
  end;
end;

procedure TRGSkeleton.ReadAnimation(var aptr:PByte);
var
  lchunk:TOgreChunk;
begin
  if FAnimationCount=Length(FAnimations) then
    SetLength(FAnimations,Length(FAnimations)+32);

  with FAnimations[FAnimationCount] do
  begin
    name:=memReadText (aptr);
    len :=memReadFloat(aptr);

    TrackCount:=0;
    Tracks    :=nil;
  
    if aptr<(FBuffer+FDataSize) then
    begin
      if ReadChunk(aptr,lchunk)=SKELETON_ANIMATION_BASEINFO then
      begin
        baseAnimationName:=memReadText (aptr);
        baseKeyFrameTime :=memReadFloat(aptr);

        if aptr<(FBuffer+FDataSize) then ReadChunk(aptr,lchunk);
      end;

      while (aptr<(FBuffer+FDataSize)) and (lchunk._type=SKELETON_ANIMATION_TRACK) do
      begin
        ReadTrack(aptr);

        if aptr<(FBuffer+FDataSize) then ReadChunk(aptr,lchunk);
      end;

      if lchunk._type<>SKELETON_ANIMATION_TRACK then
        dec(aptr,SizeOf(TOgreChunk));
    end;
  end;

  inc(FAnimationCount);
end;

function TRGSkeleton.ReadSkeleton(var aptr:PByte):boolean;
var
  lchunk:TOgreChunk;
  lpos:PByte;
begin
  result:=false;

  while aptr<(FBuffer+FDataSize) do
  begin
    lpos:=aptr;

    case ReadChunk(aptr,lchunk) of

      SKELETON_BLENDMODE: begin
        blendMode:=memReadWord(aptr);
        Log('blendmode',blendMode);
      end;

      SKELETON_BONE: begin
        if FBoneCount=Length(FBones) then
          SetLength(FBones,Length(FBones)+16);

        with FBones[FBoneCount] do
        begin
          name  :=memReadText(aptr);
          handle:=memReadWord(aptr);
          memRead(aptr,position,SizeOf(TVector3));
          memRead(aptr,orient  ,SizeOf(TVector4));
          //!! can be absent
          if (lpos+lchunk._len)>=(aptr+SizeOf(TVector3)) then
            memRead(aptr,scale   ,SizeOf(TVector3))
          else
          begin
            scale.X:=1;
            scale.Y:=1;
            scale.Z:=1;
          end;
        end;
        inc(FBoneCount);
      end;

      SKELETON_BONE_PARENT: begin
        if FHierarchyCount=Length(FHierarchy) then
          SetLength(FHierarchy,Length(FHierarchy)+32);

        with FHierarchy[FHierarchyCount] do
        begin
          handle:=memReadWord(aptr);
          parent:=memReadWord(aptr);

          // right way is use not as index but as search or right handle
          if (handle<FBoneCount) and (parent<FBoneCount) then
            Log('Hierarchy bone="'+FBones[handle].name+'" parent="'+FBones[parent].name+'"');
        end;
        inc(FHierarchyCount);
      end;

      SKELETON_ANIMATION: begin
        ReadAnimation(aptr);
      end;

      SKELETON_ANIMATION_LINK: begin
        if FAnimLinkCount=Length(FAnimLinks) then
          SetLength(FAnimLinks,Length(FAnimLinks)+4);

        with FAnimLinks[FAnimLinkCount] do
        begin
          skeletonName:=memReadText (aptr);
          scale       :=memReadFloat(aptr);
          Log('AnimationLink');
          Log('  skeletonName',skeletonName);
          Log('  scale'       ,scale);
        end;
        inc(FAnimLinkCount);
      end;

    else
      dec(aptr,SizeOf(TOgreChunk));
      break;
    end;
  end;

  result:=true;
end;

function TRGSkeleton.ImportFromMemory(aptr:PByte; asize:integer):boolean;
begin
  result:=false;

  FBuffer:=aptr;
  FDataSize:=asize;

  FVersion:=GetFileVersion(aptr);
  if FVersion<0 then exit;

  result:=ReadSkeleton(aptr);

  Log('offset',HexStr(aptr-FBuffer,8));
end;

function TRGSkeleton.ImportFromFile(const aFileName:string):boolean;
var
  lfile:File of byte;
  lbuf:PByte;
  lsize:integer;
begin
  AssignFile(lfile,aFileName);
  Reset(lfile);
  if IOResult=0 then
  begin
    lsize:=FileSize(lfile);
    if lsize>0 then
    begin
      GetMem(lbuf,lsize);
      BlockRead(lfile,lbuf^,lsize);
      CloseFile(lfile);

      result:=ImportFromMemory(lbuf,lsize);
      FreeMem(lbuf);

      exit;
    end;
    CloseFile(lfile);
  end;
  result:=false;
end;


procedure TRGSkeleton.WriteAnimation(astream:TStream; aver:integer);
var
  lapos,lpos,lp:integer;
  i,j,k:integer;
begin
  for i:=0 to FAnimationCount-1 do
  begin
    lapos:=WriteChunk(astream,SKELETON_ANIMATION);

    with FAnimations[i] do
    begin
      WriteText(astream,name);
      astream.WriteFloat(len);

      if aver>SKELETON_VERSION_1_0 then
      begin
        lp:=WriteChunk(astream,SKELETON_ANIMATION_BASEINFO);

        WriteText(astream,baseAnimationName);
        astream.WriteFloat(baseKeyframeTime);
        
        astream.WriteDWordAt(astream.Position-lp+2,lp);
      end;

      for j:=0 to TrackCount-1 do
      begin
        lpos:=WriteChunk(astream,SKELETON_ANIMATION_TRACK);

        with Tracks[j] do
        begin
          astream.WriteWord(boneIndex);
          for k:=0 to FrameCount-1 do
          begin
            lp:=WriteChunk(astream,SKELETON_ANIMATION_TRACK_KEYFRAME);

            with Frames[k] do
            begin
              astream.WriteFloat(time);
              astream.Write     (rotate   ,SizeOf(TVector4));
              astream.Write     (translate,SizeOf(TVector3));
              if (scale.X<>1) or (scale.Y<>1) or (scale.Z<>1) then
                astream.Write(scale,SizeOf(TVector3));
            end;

            astream.WriteDWordAt(astream.Position-lp+2,lp);
          end;
        end;

        astream.WriteDWordAt(astream.Position-lpos+2,lpos);
      end;
    end;

    astream.WriteDWordAt(astream.Position-lapos+2,lapos);
  end;
end;

procedure TRGSkeleton.WriteBones(astream:TStream; aver:integer);
var
  lpos:integer;
  i:integer;
begin
  for i:=0 to FBoneCount-1 do
  begin
    lpos:=WriteChunk(astream,SKELETON_BONE);

    with FBones[i] do
    begin
      WriteText(astream,name);
      astream.WriteWord(handle);
      astream.Write    (position,SizeOf(TVector3));
      astream.Write    (orient  ,SizeOf(TVector4));
      if (scale.X<>1) or (scale.Y<>1) or (scale.Z<>1) then
        astream.Write(scale,SizeOf(TVector3));
    end;

    //!!!! standard gives chunk length without name
    astream.WriteDWordAt(astream.Position-lpos+2-(Length(FBones[i].name)+1),lpos);
  end;

  for i:=0 to FHierarchyCount-1 do
  begin
    WriteChunk(astream,SKELETON_BONE_PARENT,SizeOf(Word)*2);
    astream.WriteWord(FHierarchy[i].handle);
    astream.WriteWord(FHierarchy[i].parent);
  end;
end;

procedure TRGSkeleton.WriteSkeleton(astream:TStream; aver:integer);
var
  i:integer;
begin
  astream.WriteWord(SKELETON_HEADER);
  WriteText(astream,GetVersionText(aver));

  if aver>SKELETON_VERSION_1_0 then
  begin
    WriteChunk(astream,SKELETON_BLENDMODE, SizeOf(Word));
    astream.WriteWord(blendMode);
  end;

  WriteBones(astream, aver);

  WriteAnimation(astream,aver);

  for i:=0 to FAnimLinkCount-1 do
  begin
    with FAnimLinks[i] do
    begin
      WriteChunk(astream,SKELETON_ANIMATION_LINK,Length(skeletonName)+1+SizeOf(Single));
      WriteText (astream,skeletonName);
      astream.WriteFloat(scale);
    end;
  end;

end;


procedure TRGSkeleton.SaveToXML(aStream:TStream);
var
  ls:string;
  angle:Single;
  axis:TVector3;
  i,j,k:integer;
begin
  WriteLine(aStream,'<?xml version="1.0"?>');

  if blendMode=ANIMBLEND_CUMULATIVE then
       ls:='cumulative'
  else ls:='average';
  WriteLine(aStream,'<skeleton blendmode="'+ls+'">');

  if FBoneCount>0 then
  begin
    WriteLine(aStream,'  <bones>');
    for i:=0 to FBoneCount-1 do
    begin
      with FBones[i] do
      begin
        WriteLine(aStream,'    <bone id="'+IntToStr(handle)+'" name="'+name+'">');
        with position do
          WriteLine(aStream,'      <position'+
               ' x="'+RGFloatToStr(X)+
              '" y="'+RGFloatToStr(Y)+
              '" z="'+RGFloatToStr(Z)+'" />');

        ToAngleAxis(orient, angle, axis);
        WriteLine(aStream,'      <rotation angle="'+RGFloatToStr(angle)+'">');
        with axis do
          WriteLine(aStream,'        <axis'+
               ' x="'+RGFloatToStr(X)+
              '" y="'+RGFloatToStr(Y)+
              '" z="'+RGFloatToStr(Z)+'" />');
        WriteLine(aStream,'      </rotation>');

        if (scale.X<>1) or (scale.Y<>1) or (scale.Z<>1) then
          with scale do
            WriteLine(aStream,'      <scale'+
                 ' x="'+RGFloatToStr(X)+
                '" y="'+RGFloatToStr(Y)+
                '" z="'+RGFloatToStr(Z)+'" />');
        WriteLine(aStream,'    </bone>');
      end;
    end;
    WriteLine(aStream,'  </bones>');
  end;

  if FHierarchyCount>0 then
  begin
    WriteLine(aStream,'  <bonehierarchy>');
    for i:=0 to FHierarchyCount-1 do
    begin
      with FHierarchy[i] do
        WriteLine(aStream,'    <boneparent'+
          ' bone="'   +FBones[handle].name+
          '" parent="'+FBones[parent].name+'" />');
    end;
    WriteLine(aStream,'  </bonehierarchy>');
  end;

  if FAnimationCount>0 then
  begin
    WriteLine(aStream,'  <animations>');
    for i:=0 to FAnimationCount-1 do
    begin
      with FAnimations[i] do
      begin
        WriteLine(aStream,'    <animation'+
          ' name="'  +name+
          '" length="'+RGFloatToStr(len)+'" >');
        if baseKeyframeTime<>0 then
          WriteLine(aStream,'      <baseinfo'+
            ' baseanimationname="'+baseAnimationName+
            '" basekeyframetime="'+RGFloatToStr(baseKeyframeTime)+'" >');

        WriteLine(aStream,'      <tracks>');
        for j:=0 to TrackCount-1 do
        begin
          with Tracks[j] do
          begin
            WriteLine(aStream,'        <track bone="'+FBones[boneIndex].name+'">');
            WriteLine(aStream,'          <keyframes>');
            for k:=0 to FrameCount-1 do
            begin
              with Frames[k] do
              begin
                WriteLine(aStream,'            <keyframe time="'+RGFloatToStr(time)+'">');
                with translate do
                  WriteLine(aStream,'              <translate'+
                       ' x="'+RGFloatToStr(X)+
                      '" y="'+RGFloatToStr(Y)+
                      '" z="'+RGFloatToStr(Z)+'" />');

                ToAngleAxis(rotate, angle, axis);
                WriteLine(aStream,'              <rotate angle="'+RGFloatToStr(angle)+'">');
                with axis do
                  WriteLine(aStream,'                <axis'+
                       ' x="'+RGFloatToStr(X)+
                      '" y="'+RGFloatToStr(Y)+
                      '" z="'+RGFloatToStr(Z)+'" />');
                WriteLine(aStream,'              </rotate>');

                if (scale.X<>1) or (scale.Y<>1) or (scale.Z<>1) then
                  with scale do
                    WriteLine(aStream,'              <scale'+
                         ' x="'+RGFloatToStr(X)+
                        '" y="'+RGFloatToStr(Y)+
                        '" z="'+RGFloatToStr(Z)+'" />');
              end;
              WriteLine(aStream,'            </keyframe>');
            end;
            WriteLine(aStream,'          </keyframes>');
          end;
          WriteLine(aStream,'        </track>');
        end;
        WriteLine(aStream,'      </tracks>');
      end;
      WriteLine(aStream,'    </animation>');
    end;
    WriteLine(aStream,'  </animations>');
  end;

  if FAnimLinkCount>0 then
  begin
    WriteLine(aStream,'  <animationlinks>');
    for i:=0 to FAnimLinkCount-1 do
    begin
      with FAnimLinks[i] do
        WriteLine(aStream,'    <animationlink'+
          ' skeletonName="'+skeletonName+
          '" scale="'      +RGFloatToStr(scale)+'" />');
    end;
    WriteLine(aStream,'  </animationlinks>');
  end;

  WriteLine(aStream,'</skeleton>');
end;

procedure TRGSkeleton.SaveToXML(const aFileName:String);
var
  lStream:TFileStream;
begin
  lStream:=TFileStream.Create(aFileName,fmCreate);
  try
    SaveToXML(lStream);
  finally
    FreeAndNil(lStream);
  end;
end;

end.
