unit UPuzzleKombatForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, ComCtrls, StdCtrls, ImgList,
  UBlockMatrix;

type
  TDirection = (dNone, dHorizontal, dVertical);

  TBlockType = (btRed, btGreen, btBlue, btYellow, btPurple);


const
  BLOCK_COLS = 9;
  BLOCK_ROWS = 5;
  BLOCK_CHAIN_COUNT = 3;

type
  TfrmPuzzleKombat = class(TForm)
    pnPlayer2: TPanel;
    pnPlayer1: TPanel;
    pnBlocks: TPanel;
    pbPlayer2: TProgressBar;
    pbPlayer1: TProgressBar;
    btnMovable: TButton;
    lblPanel: TLabel;
    lblButton: TLabel;
    ilBlocks: TImageList;
    memDebug: TMemo;
    tmTimer: TTimer;
    procedure btnMovableMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure btnMovableMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure pnBlocksMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure btnMovableMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure tmTimerTimer(Sender: TObject);
  private
    FBlockMatrix: TBlockMatrix;
    //  array [0..BLOCK_ROWS - 1] of array [0..BLOCK_COLS - 1] of TControl;
    FMovingBlock: TControl;
    FBlockDownX0: integer;
    FBlockDownY0: integer;
    FDirection: TDirection;
    FPixelsToMove: integer;
    FBlockWidth: integer;

    procedure ShowInfo(const ACaption: string; X, Y: integer);

    function PointToCell(ACoord: integer): integer;
    function MayMoveToCell(ACol, ARow: integer): boolean;
    function MayMoveToPoint(X, Y: integer): boolean;
    function GetBlockByCell(ACol, ARow: integer): TControl;
    function GetBlockByPoint(X, Y: integer): TControl;
    procedure MoveBlock(X, Y: integer);
    procedure CreateBlocks;
  public
    { Public declarations }
  end;

var
  frmPuzzleKombat: TfrmPuzzleKombat;

implementation

{$R *.dfm}

const
  PIXELS_TO_MOVE = 10;
  BLOCK_TYPE_COUNT = 5;


procedure TfrmPuzzleKombat.btnMovableMouseDown(
  Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Sender is TControl then begin
    FMovingBlock := Sender as TControl;
    FBlockDownX0 := X;
    FBlockDownY0 := Y;
  end;
  ShowInfo('btnMovableMouseDown', X, Y);
end;


procedure TfrmPuzzleKombat.btnMovableMouseMove(
  Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  if FMovingBlock = nil then
    Exit;

  ShowInfo('BUTTON_MOUSE_MOVE', X, Y);
  if FDirection = dNone then begin
    if
      (Abs(X - FBlockDownX0) >= FPixelsToMove) or
      (Abs(Y - FBlockDownY0) >= FPixelsToMove)
    then begin
      if Abs(X - FBlockDownX0) >= Abs(Y - FBlockDownY0) then
        FDirection := dHorizontal
      else
        FDirection := dVertical;
    end;

//    if X <> FBlockDownX0 then
//      FDirection := dHorizontal
//    else if Y <> FBlockDownY0 then
//      FDirection := dVertical;
  end;
  MoveBlock(X, Y);

  //pnBlocksMouseMove(pnBlocks, Shift, btnMovable.Left + X, btnMovable.Top + Y);
end;


procedure TfrmPuzzleKombat.btnMovableMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
//  pnPlayer1.Caption := Format('X:%d, Y:%d', [X, Y]);
  if Sender = FMovingBlock then begin
    FMovingBlock := nil;
    FDirection := dNone;
    //Application.MessageBox('!!!', '');
  end;
  ShowInfo('btnMovableMouseUp', X, Y);
end;


procedure TfrmPuzzleKombat.CreateBlocks;
var
   i, j: integer;
   btnBlock: TButton;
begin
  for i := 0 to BLOCK_ROWS - 1 do begin
    for j := 0 to BLOCK_COLS - 1 do begin
      btnBlock := TButton.Create(Self);
      btnBlock.Parent := pnBlocks;
      btnBlock.Images := ilBlocks;
      btnBlock.ImageIndex := Random(BLOCK_TYPE_COUNT);
      btnBlock.Width := FBlockWidth;
      btnBlock.Height := FBlockWidth;
      btnBlock.Left := j * FBlockWidth;
      btnBlock.Top := i * FBlockWidth;

      btnBlock.OnMouseDown := btnMovableMouseDown;
      btnBlock.OnMouseUp := btnMovableMouseUp;
      btnBlock.OnMouseMove := btnMovableMouseMove;
    end;
  end;
end;


procedure TfrmPuzzleKombat.FormCreate(Sender: TObject);
begin
  inherited;
  FBlockWidth := 73;
  FBlockMatrix :=
    TBlockMatrix.Create(
      pnBlocks, ilBlocks, FBlockWidth, BLOCK_COLS, BLOCK_ROWS, BLOCK_CHAIN_COUNT
    );


//  _Log := memDebug.Lines;


//  FDirection := dNone;
//  FPixelsToMove := btnMovable.Width div 4;
//
//  CreateBlocks;

//  ShowInfo('FormCreate', 0, 0);
  //TBlockMatrix.Create(pnBlocks, ilBlocks, FBlockWidth, BLOCK_COLS, BLOCK_ROWS);
end;


procedure TfrmPuzzleKombat.FormDestroy(Sender: TObject);
begin
  FBlockMatrix.Free;
  inherited;
end;


function TfrmPuzzleKombat.GetBlockByCell(ACol, ARow: integer): TControl;
begin
  Result := nil;
//  if MayMoveToCell(ACol, ARow) then
//    Result := FBlockMatrix[ACol, ARow];
end;


function TfrmPuzzleKombat.GetBlockByPoint(X, Y: integer): TControl;
var
  col: integer;
  row: integer;
begin
  Result := nil;

//  col := PointToCell(X);
//  row := PointToCell(Y);
//  if MayMoveToCell(row, col) then begin
//    Result := FBlockMatrix[row, col];
//  end;
end;


function TfrmPuzzleKombat.MayMoveToCell(ACol, ARow: integer): boolean;
begin
  Result :=
    (0 <= ACol) and (ACol < BLOCK_COLS) and (0 <= ARow) and (ARow < BLOCK_ROWS);
end;


function TfrmPuzzleKombat.MayMoveToPoint(X, Y: integer): boolean;
var
  col: integer;
  row: integer;
begin
  col := PointToCell(X);
  row := PointToCell(Y);
  Result := MayMoveToCell(col, row);
end;


procedure TfrmPuzzleKombat.MoveBlock(X, Y: integer);
var
  nearBlock: TControl;
begin
  if FMovingBlock = nil then
    Exit;

  if FDirection = dHorizontal then begin
    if
      MayMoveToPoint(FMovingBlock.Left + X - FBlockDownX0, FMovingBlock.Top)
    then begin
      FMovingBlock.Left := FMovingBlock.Left + X - FBlockDownX0;
      //nearBlock := GetBlockByCell();
    end;
  end
  else if FDirection = dVertical then begin
    FMovingBlock.Top := FMovingBlock.Top + Y - FBlockDownY0;
  end;
  FMovingBlock.Refresh;
end;


procedure TfrmPuzzleKombat.pnBlocksMouseMove(
  Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  lblPanel.Caption := Format('Panel: X:%d, Y:%d', [X, Y]);
  if FMovingBlock <> nil then begin
    FMovingBlock.Left := X - (FMovingBlock.Width div 2);
    FMovingBlock.Top := Y - (FMovingBlock.Height div 2);
  end;
  //ShowInfo('pnBlocksMouseMove', X, Y);
end;


function TfrmPuzzleKombat.PointToCell(ACoord: integer): integer;
begin
  Result := ACoord div FBlockWidth;
end;


procedure TfrmPuzzleKombat.ShowInfo(const ACaption: string; X, Y: integer);
const
  DIRECTION_STR: array [TDirection] of string = ('N', 'H', 'V');
var
  mbX: integer;
  mbY: integer;
  sl: TStringList;
begin
  mbX := 0;
  mbY := 0;
  if FMovingBlock <> nil then begin
    mbX := FMovingBlock.Left;
    mbY := FMovingBlock.Top;
  end;
  sl := TstringList.Create;
  try
    sl.Text :=
      Format(
        '***%s***'#13#10 +
        'FDirection = %s'#13#10 +
        'FMovingBlock = %d'#13#10 +
        'FMovingBlock.Left = %d'#13#10 +
        'FMovingBlock.Top = %d'#13#10 +
        'FBlockX0 = %d'#13#10 +
        'FBlockY0 = %d'#13#10 +
        'X = %d'#13#10 +
        'Y = %d'#13#10 +
        #13#10,
        [
          ACaption,
          DIRECTION_STR[FDirection],
          integer(FMovingBlock),
          mbX,
          mbY,
          FBlockDownX0,
          FBlockDownY0,
          X,
          Y
        ]
      );
//    memDebug.Lines.AddStrings(sl);
  finally
    sl.Free;
  end;
end;


procedure TfrmPuzzleKombat.tmTimerTimer(Sender: TObject);
begin
  _Log := memDebug.Lines;
  tmTimer.Enabled := false;
end;


end.
