{TODO: ui for choosing texture for mesh/submesh}
{TODO: ui for choosing submesh for show}
{TODO: statusbar with? offset? corner? visible submesh count?}
{TODO: list of alt textures for mesh/submesh}
{TODO: list of submeshes to show/hide}
{TODO: recreate form every time}
{TODO: if recreate set ctrl at constructor}
{TODO: set parent at constructor}
unit fm3DView;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, OpenGLContext, GL, glu,
  rgglobal, rgctrl, rgobj, lcltype, ExtCtrls, Types;

type

  { TForm3dView }

  TForm3dView = class(TForm)
    GLBox: TOpenGLControl;
    pnlLeft: TPanel;
    pnlStatus: TPanel;
    pnlOptions: TPanel;
    splLeft: TSplitter;
    procedure FormDestroy(Sender: TObject);
    procedure FormHide(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormMouseWheelDown(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
    procedure FormMouseWheelUp  (Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
    procedure GLBoxKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure GLBoxClick  (Sender: TObject);
    procedure GLBoxPaint  (Sender: TObject);
    procedure On3DViewIdle(Sender: TObject; var Done: Boolean);

  private
    ctrl:PRGController;
    fname:AnsiString;
    FMeshList:integer;
    FGLTextures:TIntegerDynArray;
    FSubOpt:pointer;

    FDoRotateX,FDoRotateY,FDoRotateZ:boolean;
    tx,ty,tz:single; // transition
    rx,ry,rz:single; // rotation
    fdist   :single;

    function CheckTexture(const adir, aname: AnsiString): integer;
    procedure ResetPosition;
    procedure PrepareTextures(const adir:string);
    procedure CreateMeshList;
    procedure SetSubMeshOpts();

  public
    Mesh:TRGMesh;

    procedure FreeModel;
    procedure SetContainer(actrl:PRGController);
    {
      model    from buffer
      material from model or current dir (or ctrl)
      texture  from          current dir (or ctrl)
    }
    function LoadFromMemory(abuf:PByte; asize:integer; const afname:string=''):boolean;
    {
      model    from file
      material from model or current dir (or ctrl)
      texture  from          current dir (or ctrl)
    }
    function LoadFromFile(const afname:string):boolean;
  end;

var
  Form3DView: TForm3dView;


implementation

{$R *.lfm}

uses
  rgstream,
  lazTGA,
  Imaging,
  ImagingTypes,
  ImagingComponents,
  ImagingDds,
  ImagingNetworkGraphics,
  ImagingOpenGL;

type
  TSubMeshOption = record
    show:boolean;
  end;
  TSubMeshOptions = array of TSubMeshOption;

const
   DiffuseLight: array[0..3] of GLfloat = (0.8, 0.8, 0.8, 1);

{%REGION Actions}
procedure TForm3dView.FormMouseWheelDown(Sender: TObject; Shift: TShiftState;
  MousePos: TPoint; var Handled: Boolean);
begin
  if ssShift in Shift then tz:=tz-0.4 else tz:=tz-0.1;
  GLBox.Invalidate;
end;

procedure TForm3dView.FormMouseWheelUp(Sender: TObject; Shift: TShiftState;
  MousePos: TPoint; var Handled: Boolean);
begin
  if ssShift in Shift then tz:=tz+0.4 else tz:=tz+0.1;
  GLBox.Invalidate;
end;

procedure TForm3dView.GLBoxClick(Sender: TObject);
begin
  FDoRotateY:=not FDoRotateY;
end;

procedure TForm3dView.GLBoxKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  case Key of
    VK_ESCAPE: ResetPosition;
    VK_RETURN,
    VK_X     : FDoRotateX:=not FDoRotateX;
    VK_SPACE,
    VK_Y     : FDoRotateY:=not FDoRotateY;
    VK_Z     : FDoRotateZ:=not FDoRotateZ;
    VK_UP    : ty:=ty+0.1;
    VK_DOWN  : ty:=ty-0.1;
    VK_LEFT  : tx:=tx-0.1;
    VK_RIGHT : tx:=tx+0.1;
    VK_PRIOR : if ssShift in Shift then tz:=tz+0.4 else tz:=tz+0.1;
    VK_NEXT  : if ssShift in Shift then tz:=tz-0.4 else tz:=tz-0.1;
  else
    exit;
  end;
end;

procedure TForm3dView.On3DViewIdle(Sender: TObject; var Done: Boolean);
begin
  Done:=false;
  GLBox.Invalidate;
end;
{%ENDREGION Actions}

{%REGION Model}
procedure TForm3dView.GLBoxPaint(Sender: TObject);
var
  Speed: Double;
begin
  glClearColor(0.27, 0.53, 0.71, 1.0); // Blue background

  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);

//  if FMeshList<0 then CreateMeshList();

  if FMeshList<>0 then
  begin

    glMatrixMode(GL_PROJECTION);
    glLoadIdentity;
    gluPerspective(45.0, double(GLBox.width) / GLBox.height, 0.1, fdist);
    //    glFrustum (-1.0, 1.0, -1.0, 1.0, 1.5, 200.0);

    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity;

//    if (wx>200) or (wy>200) or (wz>200) then glScalef(0.1, 0.1, 0.1);
    glTranslatef(tx, ty, tz);

    glRotatef(rx,1.0,0.0,0.0);
    glRotatef(ry,0.0,1.0,0.0);
    glRotatef(rz,0.0,0.0,1.0);
    Speed := double(GLBox.FrameDiffTimeInMSecs)/100;
    if FDoRotateX then rx:=rx+5.15*Speed;
    if FDoRotateY then ry:=ry+5.15*Speed;
    if FDoRotateZ then rz:=rz+5.15*Speed;

    glCallList(FMeshList);
  end;

  GLbox.SwapBuffers;
end;

procedure TForm3dView.CreateMeshList;
var
  lsm:PRGSubMesh;
  i,j,ltex:integer;
  llp,lp:PIntVector3;
  ln,lv:PVector3;
  lt:PVector2;
begin
  if FMeshList<>0 then exit;

  PrepareTextures(ExtractPath(fname));

  glTexEnvf(GL_TEXTURE_ENV,GL_TEXTURE_ENV_MODE,GL_DECAL);
  glEnable(GL_TEXTURE_2D);

  FMeshList:=glGenLists(1);
  glNewList(FMeshList,GL_COMPILE);

  for j:=1 to Mesh.SubMeshCount do
  begin
    if not TSubMeshOptions(FSubOpt)[j-1].show then continue;

    lsm:=Mesh.SubMesh[j];

    for i:=0 to txtLast do
    begin
      ltex:=Mesh.FMaterials[lsm^.Material].textures[i];
      if ltex>=0 then
      begin
        ltex:=FGLTextures[ltex];
        break;
      end;
    end;
    if ltex<0 then ltex:=0;
    glBindTexture(GL_TEXTURE_2D, ltex);

    glBegin(GL_TRIANGLES);

    lp:=lsm^.Face;
    lv:=lsm^.Vertices[VES_POSITION];
    ln:=lsm^.Vertices[VES_NORMAL];
    lt:=lsm^.Vertices[VES_TEXTURE_COORDINATES,0];
    for i:=0 to lsm^.FaceCount-1 do
    begin
      llp:=@lp[i];
      if lt<>nil then glTexCoord2fv(@lt[llp^.X]);
      glNormal3fv(@ln[llp^.X]);
      glVertex3fv(@lv[llp^.X]);

      if lt<>nil then glTexCoord2fv(@lt[llp^.Y]);
      glNormal3fv(@ln[llp^.Y]);
      glVertex3fv(@lv[llp^.Y]);

      if lt<>nil then glTexCoord2fv(@lt[llp^.Z]);
      glNormal3fv(@ln[llp^.Z]);
      glVertex3fv(@lv[llp^.Z]);
    end;

    glEnd;
  end;

  glEndList;
end;

function TForm3dView.CheckTexture(const adir,aname:AnsiString):integer;
var
  f:file of byte;
  limage:TImageData;
  lpic:TPicture;
  lstr:TMemoryStream;
  lbuf:PByte;
  lname:AnsiString;
  lfile,lsize:integer;
  lDDS:boolean;
begin
  lDDS:=ExtractExt(aname)='.DDS';

  lname:=adir+aname;
  if (ctrl<>nil) and (adir<>'') then
  begin
    lfile:=ctrl^.SearchFile(lname);
    if lfile<0 then
    begin
      if lDDS then exit(0);

      lfile:=ctrl^.SearchFile(ChangeFileExt(lname,'.DDS'));
      if lfile<0 then exit(0);
      lDDS:=true;
    end;
    lbuf:=nil;
    lsize:=ctrl^.GetBinary(lfile,lbuf);
  end;

//  if adir='' then
  if lsize=0 then
  begin
    if not FileExists(lname) then
    begin
      if lDDS then exit(0);

      lname:=ChangeFileExt(lname,'.DDS');
      if not FileExists(lname) then exit(0);
      lDDS:=true;
    end;
    AssignFile(f,lname);
    Reset(f);
    if IOResult()=0 then
    begin
      lsize:=FileSize(f);
      GetMem(lbuf,lsize);
      BlockRead(f,lbuf^,lsize);
      CloseFile(f);
    end;
  end;

  if lsize>0 then
  begin
    if lDDS or
      ((lbuf[0]=ORD('D')) and
       (lbuf[1]=ORD('D')) and
       (lbuf[2]=ORD('S'))) then
    begin
      result:=LoadGLTextureFromMemory(lbuf,lsize)
    end
    else
    begin
      lstr:=TMemoryStream.Create();
      lpic:=TPicture.Create;
      try
        // PUData cleared in ClearInfo() and/or FormClose;
        lstr.SetBuffer(lbuf);
        lpic.LoadFromStream(lstr);
        ConvertBitmapToData(lpic.Bitmap,limage);
      finally
        lstr.Free;
        lpic.Free;
      end;
      result:=CreateGLTextureFromImage(limage);
      FreeImage(limage);
    end;

    FreeMem(lbuf);
  end;

end;

procedure TForm3dView.PrepareTextures(const adir:string);
var
  lsm:PRGSubMesh;
  lmat:PMaterial;
  i,k:integer;
  ltxt:integer;
begin
  i:=Length(Mesh.FTextures);
  SetLength(FGLTextures,i);
//  FillChar(FGLTextures,FGLTextures[0],SizeOf(FGLTextures[0])*i);

//glEnable(GL_TEXTURE_2D);

  for i:=1 to Mesh.SubMeshCount do
  begin
    lsm:=Mesh.SubMesh[i];
    lmat:=@Mesh.FMaterials[lsm^.Material];

    for k:=0 to txtLast do
    begin
      ltxt:=lmat^.Textures[k];
      if (ltxt>=0) and (FGLTextures[ltxt]=0) then
      begin
        FGLTextures[ltxt]:=CheckTexture(adir,Mesh.FTextures[ltxt]);
      end;
    end;

  end;
end;

procedure TForm3dView.ResetPosition;
var
  wx,wy,wz:single;
begin
  FDoRotateX:=false;
  FDoRotateY:=false;
  FDoRotateZ:=false;
  rx:=0;
  ry:=0;
  rz:=0;

  wx:=Mesh.BoundMax.X-Mesh.BoundMin.X;
  wy:=Mesh.BoundMax.Y-Mesh.BoundMin.Y;
  wz:=Mesh.BoundMax.Z-Mesh.BoundMin.Z;
  if wx<wy then wx:=wy;

  tx:=-(Mesh.BoundMax.X+Mesh.BoundMin.X)/2;
  ty:=-(Mesh.BoundMax.Y+Mesh.BoundMin.Y)/2;
  tz:=-(wz+wx);
  if tz<-200 then tz:=-200;

  fdist:=-(wz+wx)*2;
  if fdist<200 then fdist:=200;
end;

procedure TForm3dView.FreeModel;
var
  i:integer;
begin
  if FMeshList=0 then exit;

  glDeleteLists(FMeshList,1);
  FMeshList:=0;

  for i:=0 to High(FGLTextures) do
    if FGLTextures[i]>0 then
      glDeleteTextures(1,@FGLTextures[i]);
  SetLength(FGLTextures,0);
end;
{%ENDREGION Model}

{%REGION Load}
procedure TForm3dView.SetSubMeshOpts();
var
  i:integer;
begin
  SetLength(TSubMeshOptions(FSubOpt),0);
  SetLength(TSubMeshOptions(FSubOpt),Mesh.SubMeshCount);
  for i:=0 to Mesh.SubMeshCount-1 do
  begin
    TSubMeshOptions(FSubOpt)[i].show:=true;
  end;
end;

procedure TForm3dView.SetContainer(actrl:PRGController);
begin
  ctrl:=actrl;
end;
{$I-}
function TForm3dView.LoadFromMemory(abuf:PByte; asize:integer; const afname:string=''):boolean;
var
  f:File of byte;
  lbuf:PByte;
  lfile,lsize:integer;
begin
  Mesh.Free;
  Mesh.Init;
  result:=Mesh.ImportFromMemory(abuf,asize);
  if result then
  begin
    fname:=afname;
    ResetPosition();
    if (afname<>'') and (Mesh.MeshVersion<>99) then
    begin
      AssignFile(f,ChangeFileExt(afname,'.MATERIAL'));
      Reset(f);
      if IOResult()=0 then
      begin
        lsize:=FileSize(f);
        GetMem(lbuf,lsize+1);
        BlockRead(f,lbuf^,lsize);
        lbuf[lsize]:=0;
        CloseFile(f);

        Mesh.ReadMaterialSimple(lbuf,lsize);
        FreeMem(lbuf);
      end;

      if ctrl<>nil then
      begin
        lbuf:=nil;
        lfile:=ctrl^.SearchFile(ChangeFileExt(afname,'.MATERIAL'));
        if lfile>=0 then
        begin
          lsize:=ctrl^.GetSource(lfile,lbuf);
          if lsize>0 then
            Mesh.ReadMaterialSimple(lbuf,lsize);
          FreeMem(lbuf);
        end;
      end;
//      CreateMeshList();
    end;
  end
  else
    fname:='';
end;
{$I-}
function TForm3dView.LoadFromFile(const afname:string):boolean;
var
  lbuf:PByte;
  lfile,lsize:integer;
begin
  result:=false;
  Mesh.Free;
  Mesh.Init;
  fname:='';

  if ctrl<>nil then
  begin
    lfile:=ctrl^.SearchFile(afname);
    if lfile>=0 then
    begin
      lbuf:=nil;
      lsize:=ctrl^.GetBinary(lfile,lbuf);
      if lsize>0 then
      begin
        result:=Mesh.ImportFromMemory(lbuf,lsize);
        FreeMem(lbuf);

        if result then
        begin
          fname:=afname;
          ResetPosition();

          if Mesh.MeshVersion<>99 then
          begin
            lbuf:=nil;
            lfile:=ctrl^.SearchFile(ChangeFileExt(afname,'.MATERIAL'));
            if lfile>=0 then
            begin
              lsize:=ctrl^.GetSource(lfile,lbuf);
              if lsize>0 then
                Mesh.ReadMaterialSimple(lbuf,lsize);
              FreeMem(lbuf);
            end;
          end;
          CreateMeshList();
        end;
        exit;
      end;
    end;
  end;

  if Mesh.ImportFromFile(afname) then
  begin
    fname:=afname;
    ResetPosition();
//    CreateMeshList();
  end;
end;
{%ENDREGION Load}

{%REGION Form}
procedure TForm3dView.FormShow(Sender: TObject);
begin
  glEnable(GL_DEPTH_TEST);

  glEnable(GL_LIGHTING);
  glLightfv(GL_LIGHT0, GL_DIFFUSE, DiffuseLight);
  glEnable(GL_LIGHT0);

  CreateMeshList();

  Application.AddOnIdleHandler(@On3DViewIdle);
  (Owner as TForm).ActiveControl:=GLBox;
end;

procedure TForm3dView.FormHide(Sender: TObject);
begin
  Application.RemoveOnIdleHandler(@On3DViewIdle);
  FreeModel();
end;

procedure TForm3dView.FormDestroy(Sender: TObject);
begin
  Visible:=false;
  Mesh.Free;
  SetLength(TSubMeshOptions(FSubOpt),0);
end;
{%ENDREGION Form}

initialization
  LazTGA.Register;

finalization
  LazTGA.UnRegister;
end.
