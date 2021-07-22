unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  ComCtrls, Buttons, ValEdit, Grids, StrUtils, Types;

type

  { TSignaForm }

  TSignaForm = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    BitBtn3: TBitBtn;
    BitBtn4: TBitBtn;
    BitBtn5: TBitBtn;
    Memo1: TMemo;
    Memo2: TMemo;
    Memo3: TMemo;
    Memo4: TMemo;
    OpenDialog1: TOpenDialog;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    Panel1: TPanel;
    Panel5: TPanel;
    Phys: TLabeledEdit;
    SaveDialog1: TSaveDialog;
    SelectDirectoryDialog1: TSelectDirectoryDialog;
    Share: TLabeledEdit;
    StringGrid1: TStringGrid;
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    procedure BitBtn3Click(Sender: TObject);
    procedure BitBtn4Click(Sender: TObject);
    procedure BitBtn5Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormPaint(Sender: TObject);
    procedure StringGrid1PrepareCanvas(sender: TObject; aCol, aRow: Integer;
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
   if SignaForm.Memo2.Lines.Count=-1 then Exit;
   res:=false;
   for i := 0 to SignaForm.Memo2.Lines.Count - 1 do
       if  SignaForm.Memo2.Lines.Strings[i]=path then res:=true;
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
     SignaForm.Memo2.Lines.Add(FolderName);
     if FindFirst(FolderName+'\*_*_*', faAnyFile, sr)=0  then
        repeat
            SignaForm.Memo1.Lines.Add(sr.Name);
            SignaForm.Memo4.Lines.Add(FolderName);
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



procedure TSignaForm.BitBtn1Click(Sender: TObject);
var FolderName: String;
begin
  if SelectDirectoryDialog1.Execute then
    begin
      FolderName:= SelectDirectoryDialog1.FileName;
      ReadFolder(FolderName);
    end;
end;



procedure TSignaForm.BitBtn2Click(Sender: TObject);
var i: Integer;
    j: Integer;
    pos1_1,pos1_2:integer;
    pos2_1,pos2_2:integer;
    x_1,x_2:int64;
    y_1,y_2:int64;
    row:integer;
    p_len,s_len:int64;
begin
     //Считваем плотты
     row:=1;
     p_len:=0;
     s_len:=0;
     x_1:=0;
     x_2:=0;
     y_1:=0;
     y_2:=0;
     StringGrid1.RowCount:=row;
     if Memo1.Lines.Count=-1 then Exit;
     for i := 0 to Memo1.Lines.Count - 2 do
         begin
             pos1_1:=Pos('_',Memo1.Lines.Strings[i]);
             pos1_2:=PosEx('_',Memo1.Lines.Strings[i],pos1_1+1);
             x_1:=StrToInt64(Copy(Memo1.Lines.Strings[i],pos1_1+1,pos1_2-pos1_1-1));
             x_2:=x_1+StrToInt64(Copy(Memo1.Lines.Strings[i],pos1_2+1,100))-1;
             p_len:=p_len+(x_2-x_1+1);
             for j := i+1 to Memo1.Lines.Count - 1 do
             begin
                 pos2_1:=Pos('_',Memo1.Lines.Strings[j]);
                 pos2_2:=PosEx('_',Memo1.Lines.Strings[j],pos2_1+1);
                 y_1:=StrToInt64(Copy(Memo1.Lines.Strings[j],pos2_1+1,pos2_2-pos1_1-1));
                 y_2:=y_1+StrToInt64(Copy(Memo1.Lines.Strings[j],pos2_2+1,100))-1;

                 if x_1<=y_1 then
                    begin
                        if x_2>=y_1 then
                           begin
                                row:=row+1;
                                StringGrid1.RowCount:=row;
                                StringGrid1.Cells[0,row-1]:=Memo4.Lines.Strings[i];
                                StringGrid1.Cells[1,row-1]:=Memo1.Lines.Strings[i];
                                StringGrid1.Cells[2,row-1]:=Memo4.Lines.Strings[j];
                                StringGrid1.Cells[3,row-1]:=Memo1.Lines.Strings[j];
                                StringGrid1.Cells[4,row-1]:=IntToStr(y_1);

                                if y_2<x_2 then
                                   begin
                                        StringGrid1.Cells[5,row-1]:=IntToStr(y_2);
                                        StringGrid1.Cells[6,row-1]:=IntToStr(y_2-y_1+1);
                                        StringGrid1.Cells[7,row-1]:=FloatToStr(Round((y_2-y_1+1)/200000*48.8/10)/100)+' TiB';
                                        s_len:=s_len+y_2-y_1+1;
                                   end
                                else
                                    begin
                                        StringGrid1.Cells[5,row-1]:=IntToStr(x_2);
                                        StringGrid1.Cells[6,row-1]:=IntToStr(x_2-y_1+1);
                                        StringGrid1.Cells[7,row-1]:=FloatToStr(Round((x_2-y_1+1)/200000*48.8/10)/100)+' TiB';
                                        s_len:=s_len+x_2-y_1+1;
                                   end;
                           end;
                    end
                 else
                     begin
                        if y_2>=x_1 then
                           begin
                                row:=row+1;
                                StringGrid1.RowCount:=row;
                                StringGrid1.Cells[0,row-1]:=Memo4.Lines.Strings[i];
                                StringGrid1.Cells[1,row-1]:=Memo1.Lines.Strings[i];
                                StringGrid1.Cells[2,row-1]:=Memo4.Lines.Strings[j];
                                StringGrid1.Cells[3,row-1]:=Memo1.Lines.Strings[j];
                                StringGrid1.Cells[4,row-1]:=IntToStr(x_1);

                                if y_2<x_2 then
                                   begin
                                        StringGrid1.Cells[5,row-1]:=IntToStr(y_2);
                                        StringGrid1.Cells[6,row-1]:=IntToStr(y_2-x_1+1);
                                        StringGrid1.Cells[7,row-1]:=FloatToStr(Round((y_2-x_1+1)/200000*48.8/10)/100)+' TiB';
                                        s_len:=s_len+y_2-x_1+1;
                                   end
                                else
                                    begin
                                        StringGrid1.Cells[5,row-1]:=IntToStr(x_2);
                                        StringGrid1.Cells[6,row-1]:=IntToStr(x_2-x_1+1);
                                        StringGrid1.Cells[7,row-1]:=FloatToStr(Round((x_2-x_1+1)/200000*48.8/10)/100)+' TiB';
                                        s_len:=s_len+x_2-x_1+1;
                                   end;
                           end;
                     end;
             end;
         end;
     p_len:=p_len+(y_2-y_1+1);
     Phys.Text:=FloatToStr(Round(p_len/200000*48.8/10)/100);
     Share.Text:=FloatToStr(Round((p_len-s_len)/200000*48.8/10)/100);
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

procedure TSignaForm.BitBtn3Click(Sender: TObject);
begin
  SaveDialog1.InitialDir:=GetCurrentDir;
  if SaveDialog1.Execute then
     Memo1.Lines.SaveToFile(SaveDialog1.Filename);
end;

procedure TSignaForm.BitBtn4Click(Sender: TObject);
var
    i:integer;
begin
  OpenDialog1.InitialDir:=GetCurrentDir;
  if OpenDialog1.Execute then
     if fileExists(OpenDialog1.Filename) then
        begin
             Memo3.Lines.LoadFromFile(OpenDialog1.Filename);
             for i := 0 to Memo3.Lines.Count - 1 do
                 begin
                   Memo1.Lines.Add(Memo3.Lines.Strings[i]);
                   Memo4.Lines.Add('From file');
                 end;
        end;
end;

procedure TSignaForm.BitBtn5Click(Sender: TObject);
var
  buttonSelected : Integer;
begin
   buttonSelected:= MessageDlg('Clear plot list?',mtConfirmation,mbYesNo, 0);
   if buttonSelected = mrYes then
      begin
           Memo1.Lines.Clear;
           Memo2.Lines.Clear;
           Memo4.Lines.Clear;
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

procedure TSignaForm.StringGrid1PrepareCanvas(sender: TObject; aCol,
  aRow: Integer; aState: TGridDrawState);
var
  MyTextStyle: TTextStyle;
begin
   // тут можно добавить проверку на конкретный столбец или строку через ACol, ARow
   MyTextStyle := StringGrid1.Canvas.TextStyle;
   If (ARow = 0) OR (ACol>3) then MyTextStyle.Alignment := taCenter;
   StringGrid1.Canvas.TextStyle := MyTextStyle;
end;

end.

