unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  ComCtrls, Buttons, ValEdit, Grids, StrUtils, Types;

type

  { TSignaForm }

  TSignaForm = class(TForm)
    SelectFolder: TBitBtn;
    CheckCross: TBitBtn;
    Save: TBitBtn;
    Load: TBitBtn;
    Clean: TBitBtn;
    PlotList: TMemo;
    ListDir: TMemo;
    TmpFile: TMemo;
    PlotToDir: TMemo;
    OpenD: TOpenDialog;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    Panel1: TPanel;
    Panel5: TPanel;
    Phys: TLabeledEdit;
    SaveD: TSaveDialog;
    SelectD: TSelectDirectoryDialog;
    Share: TLabeledEdit;
    Table: TStringGrid;
    procedure SelectFolderClick(Sender: TObject);
    procedure CheckCrossClick(Sender: TObject);
    procedure SaveClick(Sender: TObject);
    procedure LoadClick(Sender: TObject);
    procedure CleanClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormPaint(Sender: TObject);
    procedure TablePrepareCanvas(sender: TObject; aCol, aRow: Integer;
      aState: TGridDrawState);
  private
    FirstStart: boolean;
  public

  end;

var
  SignaForm: TSignaForm;

implementation

{$R *.lfm}

{ TSignaForm }

function CheckPath(path:string):boolean;
var
    res:boolean;
    i:integer;
begin
   if SignaForm.ListDir.Lines.Count=-1 then Exit;
   res:=false;
   for i := 0 to SignaForm.ListDir.Lines.Count - 1 do
       if  SignaForm.ListDir.Lines.Strings[i]=path then res:=true;
   Result:=res;
end;

procedure ReadFolder(FolderName: String);
var
    sr: TSearchRec;
begin
     if CheckPath(FolderName) then
        begin
             ShowMessage('The list plots from "'+FolderName+'" is already loaded');
             Exit;
        end;
     SignaForm.ListDir.Lines.Add(FolderName);
     if FindFirst(FolderName+'\*_*_*', faAnyFile, sr)=0  then
        repeat
            SignaForm.PlotList.Lines.Add(sr.Name);
            SignaForm.PlotToDir.Lines.Add(FolderName);
        until FindNext(sr)<>0;
      FindClose(sr);
end;

procedure ReadConfig(FileName:string);
var
    f: TextFile;
    buf: string[80];
    str:string;
    btdex:string;
begin
   AssignFile(f, FileName);
   Reset(f);
   while not EOF(f) do
   begin
      readln(f, buf);
      btdex:=Copy(buf,0,8);
      if btdex='plotPath' then
         begin
            str:=Copy(buf,Pos('=', buf)+1,100);
            str:=StringReplace(str,'\\','/',[rfReplaceAll]);
            str:=StringReplace(str,'\','',[rfReplaceAll]);
            str:=StringReplace(str,'/','\',[rfReplaceAll]);
            str:=Trim(str);
            ReadFolder(str);
         end;
      if Pos(' - ', buf) > 0 then
            begin
                 while Pos(chr(39), buf)>0 do Delete(buf, Pos(chr(39), buf), 1);
                 Delete(buf, Pos(' - ', buf), 3);
                 str:=Trim(buf);
                 if str[2]=':' then ReadFolder(str);
            end;
   end;
end;

procedure CheckFoxy();
var
    path:string;
    buttonSelected : Integer;
begin
   path:=GetEnvironmentVariable('USERPROFILE')+'\.config\foxy-miner\foxy-miner.yaml';
   if FileExists(path) then
      begin
      buttonSelected:= MessageDlg('Foxy-miner found, load plot list from config?',mtConfirmation,mbYesNo, 0);
      if buttonSelected = mrYes then ReadConfig(path);
      end;
end;



procedure CheckScav();
var
    path:string;
    buttonSelected : Integer;
begin
   path:=GetCurrentDir+'\config.yaml';
   if FileExists(path) then
      begin
      buttonSelected:= MessageDlg('Scavanger found, load plot list from config?',mtConfirmation,mbYesNo, 0);
      if buttonSelected = mrYes then ReadConfig(path);
      end;
   path:=GetCurrentDir+'\config.properties';
   if FileExists(path) then
      begin
      buttonSelected:= MessageDlg('BTDEX found, load plot list from config?',mtConfirmation,mbYesNo, 0);
      if buttonSelected = mrYes then ReadConfig(path);
      end;
end;



procedure TSignaForm.SelectFolderClick(Sender: TObject);
var FolderName: String;
begin
  if SelectD.Execute then
    begin
      FolderName:= SelectD.FileName;
      ReadFolder(FolderName);
    end;
end;



procedure TSignaForm.CheckCrossClick(Sender: TObject);
const
  nonce=262144;
var i: Integer;
    j: Integer;
    pos1_1,pos1_2:integer;
    pos2_1,pos2_2:integer;
    x_1,x_2:int64;
    y_1,y_2:int64;
    row:integer;
    p_len,s_len:int64;
    n_p_t: real;
begin
     //Считваем плотты
     n_p_t:=nonce/1024/1024/1024/1024*100;
     row:=1;
     p_len:=0;
     s_len:=0;
     x_1:=0;
     x_2:=0;
     y_1:=0;
     y_2:=0;
     Table.RowCount:=row;
     if PlotList.Lines.Count=-1 then Exit;
     for i := 0 to PlotList.Lines.Count - 2 do
         begin
             pos1_1:=Pos('_',PlotList.Lines.Strings[i]);
             pos1_2:=PosEx('_',PlotList.Lines.Strings[i],pos1_1+1);
             x_1:=StrToInt64(Copy(PlotList.Lines.Strings[i],pos1_1+1,pos1_2-pos1_1-1));
             x_2:=x_1+StrToInt64(Copy(PlotList.Lines.Strings[i],pos1_2+1,100))-1;
             p_len:=p_len+(x_2-x_1+1);
             for j := i+1 to PlotList.Lines.Count - 1 do
             begin
                 pos2_1:=Pos('_',PlotList.Lines.Strings[j]);
                 pos2_2:=PosEx('_',PlotList.Lines.Strings[j],pos2_1+1);
                 y_1:=StrToInt64(Copy(PlotList.Lines.Strings[j],pos2_1+1,pos2_2-pos1_1-1));
                 y_2:=y_1+StrToInt64(Copy(PlotList.Lines.Strings[j],pos2_2+1,100))-1;

                 if x_1<=y_1 then
                    begin
                        if x_2>=y_1 then
                           begin
                                row:=row+1;
                                Table.RowCount:=row;
                                Table.Cells[0,row-1]:=PlotToDir.Lines.Strings[i];
                                Table.Cells[1,row-1]:=PlotList.Lines.Strings[i];
                                Table.Cells[2,row-1]:=PlotToDir.Lines.Strings[j];
                                Table.Cells[3,row-1]:=PlotList.Lines.Strings[j];
                                Table.Cells[4,row-1]:=IntToStr(y_1);

                                if y_2<x_2 then
                                   begin
                                        Table.Cells[5,row-1]:=IntToStr(y_2);
                                        s_len:=s_len+y_2-y_1+1;
                                   end
                                else
                                    begin
                                        Table.Cells[5,row-1]:=IntToStr(x_2);
                                        s_len:=s_len+x_2-y_1+1;

                                   end;
                               Table.Cells[6,row-1]:=IntToStr(s_len);
                               Table.Cells[7,row-1]:=FloatToStr(Round(s_len*n_p_t)/100)+' TiB';
                           end;
                    end
                 else
                     begin
                        if y_2>=x_1 then
                           begin
                                row:=row+1;
                                Table.RowCount:=row;
                                Table.Cells[0,row-1]:=PlotToDir.Lines.Strings[i];
                                Table.Cells[1,row-1]:=PlotList.Lines.Strings[i];
                                Table.Cells[2,row-1]:=PlotToDir.Lines.Strings[j];
                                Table.Cells[3,row-1]:=PlotList.Lines.Strings[j];
                                Table.Cells[4,row-1]:=IntToStr(x_1);

                                if y_2<x_2 then
                                   begin
                                        Table.Cells[5,row-1]:=IntToStr(y_2);
                                        s_len:=s_len+y_2-x_1+1;
                                   end
                                else
                                    begin
                                        Table.Cells[5,row-1]:=IntToStr(x_2);
                                        s_len:=s_len+x_2-x_1+1;
                                   end;
                               Table.Cells[6,row-1]:=IntToStr(s_len);
                               Table.Cells[7,row-1]:=FloatToStr(Round(s_len*n_p_t)/100)+' TiB';
                           end;
                     end;
             end;
         end;
     p_len:=p_len+(y_2-y_1+1);
     Phys.Text:=FloatToStr(Round(p_len*n_p_t)/100);
     Share.Text:=FloatToStr(Round((p_len-s_len)*n_p_t)/100);
     if s_len=0 then
        begin
        Share.Font.Color:=clGreen;
        Share.EditLabel.Font.Color:=clDefault;
        end
     else
       begin
       Share.Font.Color:=clRed;
       Share.EditLabel.Font.Color:=clRed;
       end;


     if row=1 then ShowMessage('No plots crossing detected')
     else  ShowMessage('Plots crossing detected');

end;

procedure TSignaForm.SaveClick(Sender: TObject);
begin
  SaveD.InitialDir:=GetCurrentDir;
  if SaveD.Execute then
     PlotList.Lines.SaveToFile(SaveD.Filename);
end;

procedure TSignaForm.LoadClick(Sender: TObject);
var
    i:integer;
begin
  OpenD.InitialDir:=GetCurrentDir;
  if OpenD.Execute then
     if fileExists(OpenD.Filename) then
        begin
             TmpFile.Lines.LoadFromFile(OpenD.Filename);
             for i := 0 to TmpFile.Lines.Count - 1 do
                 begin
                   PlotList.Lines.Add(TmpFile.Lines.Strings[i]);
                   PlotToDir.Lines.Add('From file');
                 end;
        end;
end;

procedure TSignaForm.CleanClick(Sender: TObject);
var
  buttonSelected : Integer;
begin
   buttonSelected:= MessageDlg('Clear plot list?',mtConfirmation,mbYesNo, 0);
   if buttonSelected = mrYes then
      begin
           PlotList.Lines.Clear;
           ListDir.Lines.Clear;
           PlotToDir.Lines.Clear;

           Table.RowCount:=1;
           Phys.Text:='';
           Share.Text:='';
           Share.Font.Color:=clGreen;
           Share.EditLabel.Font.Color:=clDefault;
      end;
end;

procedure TSignaForm.FormCreate(Sender: TObject);
begin
   FirstStart := true;
end;

procedure TSignaForm.FormPaint(Sender: TObject);
begin
     if not FirstStart then Exit;
     FirstStart := false;
     CheckFoxy();
     CheckScav();
end;

procedure TSignaForm.TablePrepareCanvas(sender: TObject; aCol,
  aRow: Integer; aState: TGridDrawState);
var
  MyTextStyle: TTextStyle;
begin
   MyTextStyle := Table.Canvas.TextStyle;
   If (ARow = 0) OR (ACol>3) then MyTextStyle.Alignment := taCenter;
   Table.Canvas.TextStyle := MyTextStyle;
end;

end.

