unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, OpenGLContext, GL, glu,
  rgglobal, rgobj, lcltype, Types;

type

  { TForm1 }

  TForm1 = class(TForm)
    GLBox: TOpenGLControl;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormMouseWheelDown(Sender: TObject; Shift: TShiftState;
      MousePos: TPoint; var Handled: Boolean);
    procedure FormMouseWheelUp(Sender: TObject; Shift: TShiftState;
      MousePos: TPoint; var Handled: Boolean);
    procedure GLBoxClick(Sender: TObject);
    procedure GLBoxKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure GLBoxPaint(Sender: TObject);
    procedure OnAppIdle(Sender: TObject; var Done: Boolean);
  private
    FMeshList:integer;
    FGLTextures:TIntegerDynArray;

    Tex1:longword;
    FDoRotate:boolean;
    wx,wy,wz:single;
    tx,ty,tz:single;
    rx,ry,rz:single;
    FMesh:TRGMesh;

    procedure PrepareTextures;
  public
    procedure CreateMeshList;
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

uses
  Imaging,
  ImagingTypes,
  ImagingComponents,
  ImagingDds,
  ImagingOpenGL;

{ TForm1 }

procedure TForm1.FormMouseWheelDown(Sender: TObject; Shift: TShiftState;
  MousePos: TPoint; var Handled: Boolean);
begin
  if ssShift in Shift then tz:=tz-0.4 else tz:=tz-0.1;
//  tz:=tz-0.3;
  GLBox.Invalidate;
end;

procedure TForm1.FormMouseWheelUp(Sender: TObject; Shift: TShiftState;
  MousePos: TPoint; var Handled: Boolean);
begin
  if ssShift in Shift then tz:=tz+0.4 else tz:=tz+0.1;
//  tz:=tz+0.3;
  GLBox.Invalidate;
end;

procedure TForm1.GLBoxClick(Sender: TObject);
begin
  FDoRotate:=not FDoRotate;
end;

procedure TForm1.GLBoxKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  case Key of
    VK_SPACE: FDoRotate:=not FDoRotate;
    VK_UP   : ty:=ty+0.1;
    VK_DOWN : ty:=ty-0.1;
    VK_LEFT : tx:=tx-0.1;
    VK_RIGHT: tx:=tx+0.1;
    VK_PRIOR: if ssShift in Shift then tz:=tz+0.4 else tz:=tz+0.1;
    VK_NEXT : if ssShift in Shift then tz:=tz-0.4 else tz:=tz-0.1;
  end;
end;

const
   DiffuseLight: array[0..3] of GLfloat = (0.8, 0.8, 0.8, 1);

procedure TForm1.GLBoxPaint(Sender: TObject);
var
  i:integer;
  lsm:PRGSubMesh;
  Speed: Double;
  xmin,xmax,ymin,ymax:GLDouble;
  lp:PByte;
begin
  glClearColor(0.27, 0.53, 0.71, 1.0); // Задаем синий фон

  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);

  if FMeshList=0 then
  begin
    CreateMeshList;

    if FMesh.BoundMin.Z<6.0 then
      tz:=FMesh.BoundMin.Z
    else
      tz:=-6.0;

    tx:=-(FMesh.BoundMax.X+FMesh.BoundMin.X)/2;
    ty:=-(FMesh.BoundMax.Y+FMesh.BoundMin.Y)/2;
    wx:=  FMesh.BoundMax.X-FMesh.BoundMin.X;
    wy:=  FMesh.BoundMax.Y-FMesh.BoundMin.Y;
    wz:=  FMesh.BoundMax.Z-FMesh.BoundMin.Z;
    if wy<wx then wy:=wx;
    tz:=-(wz+wy);
    if tz<-200 then tz:=-200;

    glEnable(GL_DEPTH_TEST);

    glEnable(GL_LIGHTING);
    glLightfv(GL_LIGHT0, GL_DIFFUSE, DiffuseLight);
    glEnable(GL_LIGHT0);

    glMatrixMode(GL_PROJECTION);
    glLoadIdentity;
    glFrustum (-1.0, 1.0, -1.0, 1.0, 1.5, 200.0);
  end;

  if FMeshList<>0 then
  begin
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity;
    gluPerspective(45.0, double(GLBox.width) / GLBox.height, 0.1, 200.0);
    //    glFrustum (-1.0, 1.0, -1.0, 1.0, 1.5, 200.0);
    wx:=  FMesh.BoundMax.X-FMesh.BoundMin.X;
    wy:=  FMesh.BoundMax.Y-FMesh.BoundMin.Y;
    wz:=  FMesh.BoundMax.Z-FMesh.BoundMin.Z;

    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity;

//    if (wx>200) or (wy>200) or (wz>200) then glScalef(0.1, 0.1, 0.1);
    glTranslatef(tx, ty, tz);

//    glRotatef(rx,1.0,0.0,0.0);
    glRotatef(ry,0.0,1.0,0.0);
//    glRotatef(rz,0.0,0.0,1.0);
    if FDoRotate then
    begin
      Speed := double(GLBox.FrameDiffTimeInMSecs)/100;
      rx += 5.15 * Speed;
      ry += 5.15 * Speed;
      rz += 20.0 * Speed;
    end;

//    glBindTexture(GL_TEXTURE_2D, Tex1);
    glCallList(FMeshList);
{
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_NORMAL_ARRAY);
    for i:=1 to FMesh.SubMeshCount do
    begin
      lsm:=FMesh.SubMesh[i];
      glVertexPointer(3, GL_FLOAT , 0, lsm^.Vertex);
      glNormalPointer(   GL_FLOAT , 0, lsm^.Normal);
      glDrawElements (GL_TRIANGLES, lsm^.FaceCount*3, GL_UNSIGNED_INT, lsm^.Face);
    end;
    glDisableClientState(GL_VERTEX_ARRAY);
    glDisableClientState(GL_NORMAL_ARRAY);
}
  end;

  GLbox.SwapBuffers;
end;

procedure TForm1.CreateMeshList;
var
  lsm:PRGSubMesh;
  i,j:integer;
  v4:TVector3;
  lp:PIntVector3;
  ln,lv:PVector3;
  lt:PVector2;
begin
  PrepareTextures();

  if ParamCount>=2 then
  begin
    Tex1:=LoadGLTextureFromFile(ParamStr(2));
//    glBindTexture(GL_TEXTURE_2D, Tex1);
  end;

  glTexEnvf(GL_TEXTURE_ENV,GL_TEXTURE_ENV_MODE,GL_DECAL);
  glEnable(GL_TEXTURE_2D);
  
  FMeshList:=glGenLists(1);
  glNewList(FMeshList,GL_COMPILE);

  for j:=1 to FMesh.SubMeshCount do
  begin
    lsm:=FMesh.SubMesh[j];

//    if FMesh.MeshVersion=99 then
    if ParamCount<2 then
    begin
      for i:=0 to txtLast do
      begin
        if FMesh.FMaterials[lsm^.Material].textures[i]>=0 then
        begin
          Tex1:=FGLTextures[FMesh.FMaterials[lsm^.Material].textures[i]];
          glBindTexture(GL_TEXTURE_2D, Tex1);
          break;
        end;
      end;
    end
    else
    begin
      glBindTexture(GL_TEXTURE_2D, Tex1);
    end;

    glBegin(GL_TRIANGLES);

    lp:=lsm^.Face;
    lv:=lsm^.Vertex;
    ln:=lsm^.Normal;
    lt:=lsm^.Buffer[VES_TEXTURE_COORDINATES,0];
    for i:=0 to lsm^.FaceCount-1 do
    begin
      glTexCoord2fv(@lt[lp[i].X]);
      glNormal3fv  (@ln[lp[i].X]);
      glVertex3fv  (@lv[lp[i].X]);

      glTexCoord2fv(@lt[lp[i].Y]);
      glNormal3fv  (@ln[lp[i].Y]);
      glVertex3fv  (@lv[lp[i].Y]);

      glTexCoord2fv(@lt[lp[i].Z]);
      glNormal3fv  (@ln[lp[i].Z]);
      glVertex3fv  (@lv[lp[i].Z]);
    end;

    glEnd;
  end;
//  glDisable(GL_TEXTURE_2D);

  glEndList;
end;

function CheckTexture(const aname:AnsiString):integer;
var
  lDDS:boolean;
  lname:AnsiString;
  limage:TImageData;
  lpic:TPicture;
begin
  lDDS:=ExtractExt(aname)='.DDS';

  if FileExists(aname) then
    lname:=aname
  else
  begin
    if lDDS then exit(0);

    lname:=ChangeFileExt(aname,'.DDS');
    if not FileExists(lname) then exit(0);
    lDDS:=true;
  end;
  if lDDS then
    result:=LoadGLTextureFromFile(lname)
  else
  begin
    lpic:=TPicture.Create;
    lpic.LoadFromFile(lname);
    ConvertBitmapToData(lpic.Bitmap,limage);
    result:=CreateGLTextureFromImage(limage);
    lpic.Free;
  end;
end;

procedure TForm1.PrepareTextures;
var
  lsm:PRGSubMesh;
  lmat:PMaterial;
  i,j,k:integer;
  ltxt:integer;
begin
  i:=Length(FMesh.FTextures);
  SetLength(FGLTextures,i);
//  FillChar(FGLTextures,FGLTextures[0],SizeOf(FGLTextures[0])*i);

//glEnable(GL_TEXTURE_2D);

  for i:=1 to FMesh.SubMeshCount do
  begin
    lsm:=FMesh.SubMesh[i];
    lmat:=@FMesh.FMaterials[lsm^.Material];

    for k:=0 to txtLast do
    begin
      ltxt:=lmat^.Textures[k];
      if (ltxt>=0) and (FGLTextures[ltxt]=0) then
      begin
        FGLTextures[ltxt]:=CheckTexture(FMesh.FTextures[ltxt]);
      end;
    end;

  end;
end;

procedure TForm1.OnAppIdle(Sender: TObject; var Done: Boolean);
begin
  Done:=false;
  GLBox.Invalidate;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  OpenDialog:TOpenDialog;
  lname:AnsiString;
begin
  FDoRotate:=true;
  Tex1:=0;

  FMeshList:=0;
  FMesh.Init;

  if ParamCount=0 then
  begin
    OpenDialog:=TOpenDialog.Create(self);
    if OpenDialog.Execute then
      lname:=OpenDialog.FileName
    else
      lname:='';
    OpenDialog.Free;
  end
  else
  begin
    lname:=ParamStr(1);
  end;

  if lname='' then exit;

  FMesh.ImportFromFile(lname);
//  PrepareTextures();

  Application.AddOnIdleHandler(@OnAppIdle);
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  glDeleteLists(FMeshList,1);
  FMesh.Free;
end;

end.

