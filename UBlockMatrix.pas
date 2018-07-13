unit UBlockMatrix;

interface

uses
  Controls, StdCtrls, Classes, Generics.Collections, ExtCtrls,
  UBlock;

type
  TDirection = (dNone, dHorizontal, dVertical);

  TDimentionType = (dtRow, dtCol);

  TBlockMatrix = class(TObject)
  private
    FContainer: TWinControl;
    FBlockWidth: integer;
    FColCount: integer;
    FRowCount: integer;
    FBlockChainCount: integer;

    FMatrix: array of array of TBlock;
    FBlockCache: TDictionary<integer, TBlock>;

    FMovingBlock: TBlock;
    FBlockDownX0: integer;
    FBlockDownY0: integer;
    FDirection: TDirection;
    FPixelsToMove: integer;

    FRemoveBlocksTimer: TTimer;
    FRemovePixStep: integer;
    FRemoveMoveInterval: integer;

    procedure BlockMouseDown(
      Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure BlockMouseUp(
      Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure BlockMouseMove(
      Sender: TObject; Shift: TShiftState; X, Y: Integer);

    function CreateRandomBlock(ACol, ARow: integer): TBlock;
    function GetBlockKey(ACol, ARow: integer): integer;
    procedure AddBlockToCache(ABlock: TBlock);
    function GetBlock(ACol, ARow: integer): TBlock;

    procedure SetDestCell(ABlock: TBlock; ADX, ADY: integer);
    function IsCellExist(ACol, ARow: integer): boolean;
    procedure MoveBlock(X, Y: integer);
    procedure EndMoving;

    procedure MarkBlocksToMove;
    procedure RemoveBlockChains;
    procedure AddChainToList(ABlockChain, ABlockList: TList<TBlock>);
    procedure AddChainsFromDimention(
      ADimentionType: TDimentionType; APos: integer;
      ABlockList: TList<TBlock>);

    procedure CheckMatrixCell(ABlock: TBlock);

    procedure Log(const AMsg: string; const AArgs: array of const);
  public
    constructor Create(
      AContainer: TWinControl; ABlockImages: TImageList; ABlockWidth: integer;
      ACols, ARows: integer; ABlockChainCount: integer);
    destructor Destroy; override;
  end;


var
  _Log: TStrings;


implementation

uses
  SysUtils, Math, Forms;


{ TBlockMatrix }

procedure TBlockMatrix.AddChainToList(ABlockChain, ABlockList: TList<TBlock>);
var
  block: TBlock;
begin
  if ABlockChain.Count >= FBlockChainCount then begin
    for block in ABlockChain do begin
      block.MarkedRemoved := true;
      if not ABlockList.Contains(block) then
        ABlockList.Add(block);
    end;
  end;
end;


procedure TBlockMatrix.BlockMouseDown(
  Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Sender is TBlock then begin
    FMovingBlock := Sender as TBlock;
    FBlockDownX0 := X;
    FBlockDownY0 := Y;
  end;
end;


procedure TBlockMatrix.BlockMouseMove(
  Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  linkBlock: TBlock;
begin
  if FMovingBlock = nil then
    Exit;

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
  end;
  if (FMovingBlock.DestCell = nil) and (FDirection <> dNone) then begin
    if FDirection = dHorizontal then
      SetDestCell(FMovingBlock, X - FBlockDownX0, 0)
    else
      SetDestCell(FMovingBlock, 0, Y - FBlockDownY0);
  end;
  MoveBlock(X, Y);
end;


procedure TBlockMatrix.BlockMouseUp(
  Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  col, row: integer;
  srcCol, srcRow: integer;
  block: TBlock;
  linkBlock: TBlock;
  nearBlock: TBlock;
begin
  if Sender = FMovingBlock then begin
    block := FMovingBlock;
    linkBlock := block.LinkBlock;
    if linkBlock <> nil then begin
      block.MoveToNearestCell;
      linkBlock.MoveToNearestCell;
      CheckMatrixCell(block);
      CheckMatrixCell(linkBlock);
      FMatrix[block.Cell.Row, block.Cell.col] := block;
      FMatrix[linkBlock.Cell.Row, linkBlock.Cell.col] := linkBlock;
      block.ClearDestCell;
      linkBlock.ClearDestCell;
    end;

    EndMoving;
  end;
end;


procedure TBlockMatrix.CheckMatrixCell(ABlock: TBlock);
var
  cell: TCell;
begin
  cell := ABlock.Cell;
  if (cell.Row < 0) or (Length(FMatrix) <= cell.Row) then
    raise Exception.CreateFmt(
      'Row = %d; Matrix.RowCount = %d', [cell.Row, Length(FMatrix)]);
  if (cell.Col < 0) or (Length(FMatrix[cell.Row]) <= cell.Col) then
    raise Exception.CreateFmt(
      'Col = %d; Matrix.ColCount = %d', [cell.Col, Length(FMatrix[cell.Row])]);
end;


procedure TBlockMatrix.AddBlockToCache(ABlock: TBlock);
begin
  FBlockCache.Add(GetBlockKey(ABlock.Cell.Col, ABlock.Cell.Row), ABlock);
end;


procedure TBlockMatrix.AddChainsFromDimention(
  ADimentionType: TDimentionType; APos: integer; ABlockList: TList<TBlock>);
var
  blockChain: TList<TBlock>;
  cellCount: integer;
  i: integer;
  block: TBlock;
begin
  blockChain := TObjectList<TBlock>.Create(false);
  try
    if ADimentionType = dtRow then
      cellCount := FColCount
    else
      cellCount := FRowCount;

    for i := 0 to cellCount - 1 do begin
      if ADimentionType = dtRow then
        block := FMatrix[APos, i]
      else
        block := FMatrix[i, APos];
      if
        (blockChain.Count > 0) and
        (block.ImageIndex <> blockChain.Last.ImageIndex)
      then begin
        AddChainToList(blockChain, ABlockList);
        blockChain.Clear;
      end;
      blockChain.Add(block);
    end;
    AddChainToList(blockChain, ABlockList);
  finally
    blockChain.Free;
  end;
end;


constructor TBlockMatrix.Create(
  AContainer: TWinControl; ABlockImages: TImageList;
  ABlockWidth, ACols, ARows, ABlockChainCount: integer);
var
  i, j: integer;
  btnBlock: TBlock;
begin
  inherited Create;
  FContainer := AContainer;
  FBlockWidth := ABlockWidth;
  FPixelsToMove := FBlockWidth div 4;
  FColCount := ACols;
  FRowCount := ARows;
  FBlockChainCount := ABlockChainCount;
  FDirection := dNone;

  FBlockCache := TObjectDictionary<integer, TBlock>.Create([]);
  SetLength(FMatrix, FRowCount);
  for i := 0 to FRowCount - 1 do begin
    SetLength(FMatrix[i], FColCount);
    for j := 0 to FColCount - 1 do begin
      FMatrix[i, j] := CreateRandomBlock(j, i);
    end;
  end;

  FRemoveMoveInterval := 1000 div 200;
  FRemovePixStep := 8;
  FRemoveBlocksTimer := TTimer.Create(nil);
  FRemoveBlocksTimer.Enabled := false;
  FRemoveBlocksTimer.Interval := FRemoveMoveInterval;
end;


function TBlockMatrix.CreateRandomBlock(ACol, ARow: integer): TBlock;
begin
  Result := TBlock.Create(FContainer);
  Result.Parent := FContainer;
  //btnBlock.Images := ABlockImages;
  Result.ImageIndex := Random(5{ABlockImages.Count});
  Result.Caption := IntToStr(Result.ImageIndex);

  Result.Width := FBlockWidth;
  Result.Height := FBlockWidth;
  Result.MoveToCell(ACol, ARow);

  Result.OnMouseDown := BlockMouseDown;
  Result.OnMouseUp := BlockMouseUp;
  Result.OnMouseMove := BlockMouseMove;

  AddBlockToCache(Result);
end;


destructor TBlockMatrix.Destroy;
begin
  FRemoveBlocksTimer.Free;
  FBlockCache.Free;
  inherited;
end;


procedure TBlockMatrix.EndMoving;
begin
  FMovingBlock.UnLinkBlock;
  FMovingBlock := nil;
  FDirection := dNone;

  RemoveBlockChains;
end;


function TBlockMatrix.GetBlock(ACol, ARow: integer): TBlock;
begin
  Result := FBlockCache[GetBlockKey(ACol, ARow)];
end;


function TBlockMatrix.GetBlockKey(ACol, ARow: integer): integer;
begin
  Result := ARow * FColCount + ACol;
end;


function TBlockMatrix.IsCellExist(ACol, ARow: integer): boolean;
begin
  Result :=
    (0 <= ACol) and (ACol < FColCount) and (0 <= ARow) and (ARow < FRowCount);
end;


procedure TBlockMatrix.Log(const AMsg: string; const AArgs: array of const);
begin
  if _Log <> nil then
    _Log.Add(Format(AMsg, AArgs));
end;


procedure TBlockMatrix.MarkBlocksToMove;
var
  i, j: integer;
  doMark: boolean;
  block: TBlock;
  destRow: integer;
begin
  for j := 0 to FColCount - 1 do begin
    destRow := -1;
    for i := 0 to FRowCount - 1 do begin
      block := FMatrix[i, j];
      if block.MarkedRemoved then begin
        if destRow = -1 then
          destRow := block.Cell.Row
      end
      else if destRow >= 0 then begin
        block.DestCell := TCell.Create(j, destRow);
        Inc(destRow);
      end;
    end;
  end;
end;


procedure TBlockMatrix.MoveBlock(X, Y: integer);
var
  block: TBlock;
  dx, dy: integer;
  linkBlock: TBlock;
begin
  if (FMovingBlock = nil) or (FMovingBlock.LinkBlock = nil) then
    Exit;

  // find strict cell bug
  block := FMovingBlock;
  linkBlock := FMovingBlock.LinkBlock;
  if FDirection = dHorizontal then begin
    dx := X - FBlockDownX0;

    Log('*MoveBlock*', []);
    Log('block.Row = %d', [block.Cell.Row]);
    Log('FBlockDownX0 = %d', [FBlockDownX0]);
    Log('X = %d', [X]);
    Log('dx = %d', [dx]);
    Log('block.Col = %d', [block.Cell.Col]);
    Log('block.Left = %d', [block.Left]);
    Log('linkBlock.Left = %d', [linkBlock.Left]);
    if (dx <> 0) then begin
      if dx > 0 then begin
        block.MoveByPix(dx, 0, true);
        linkBlock.MoveByPix(-dx, 0, true);
      end
      else begin
        block.MoveByPix(dx, 0, true);
        linkBlock.MoveByPix(-dx, 0, true);
      end;
      Log('[after move] block.Left = %d', [block.Left]);
      Log('[after move] linkBlock.Left = %d', [linkBlock.Left]);
    end;
  end
  else if FDirection = dVertical then begin
    dy := Y - FBlockDownY0;
    if (dy <> 0) then begin
      block.MoveByPix(0, dy, true);
      linkBlock.MoveByPix(0, -dy, true);
    end;
  end;
  block.Refresh;
  linkBlock.Refresh;
  Log('', []);
end;


procedure TBlockMatrix.RemoveBlockChains;
var
  blockList: TList<TBlock>;
  newBlocks: TList<TBlock>;
  i, j: integer;
  col: integer;
  block: TBlock;
  newBlock: TBlock;
  prevBlock: TBlock;
  edgeBlock: TBlock;
  cellsInCols: array of integer;
begin
  FContainer.Enabled := false;
  try
    blockList := TObjectList<TBlock>.Create(false);
    try
      for i := 0 to FRowCount - 1 do
        AddChainsFromDimention(dtRow, i, blockList);
      for i := 0 to FColCount - 1 do
        AddChainsFromDimention(dtCol, i, blockList);

      if blockList.Count = 0 then
        Exit;

      MarkBlocksToMove;

      newBlocks := TObjectList<TBlock>.Create(false);
      try
        SetLength(cellsInCols, FColCount);
        for block in blockList do begin
          col := block.Cell.Col;
          newBlock := CreateRandomBlock(col, cellsInCols[col] + FRowCount);
          prevBlock := GetBlock(col, newBlock.Cell.Row - 1);
          if prevBlock.DestCell <> nil then
            newBlock.DestCell := TCell.Create(col, prevBlock.DestCell.Row + 1)
          else
            newBlock.DestCell := TCell.Create(col, newBlock.Cell.Row - 1);
          newBlocks.Add(newBlock);
          Inc(cellsInCols[block.Cell.Col]);
        end;

        edgeBlock := blockList.First;
        for block in blockList do
          if block.Top > edgeBlock.Top then
            edgeBlock := block;

        while edgeBlock.Top + edgeBlock.Height > 0 do begin
          for i := 0 to FRowCount - 1 do begin
            for j := 0 to FColCount - 1 do begin
              block := FMatrix[i, j];
              if block.MarkedRemoved then begin
                block.Top := block.Top + -FRemovePixStep;
                block.Refresh;
              end
              else if block.DestCell <> nil then begin
                if block.MayMoveByPix(0, -FRemovePixStep) then
                  block.MoveByPix(0, -FRemovePixStep, true);
              end;
            end;
          end;


//          for block in blockList do begin
//            block.Top := block.Top + -FRemovePixStep;
//            block.Refresh;
//          end;

          for block in newBlocks do begin
            block.Top := block.Top + -FRemovePixStep;
            block.Refresh;
          end;
          Sleep(FRemoveMoveInterval);
          Application.ProcessMessages;
        end;
        // Update FMatrix
        for block in blockList do
          block.Free;
          //block.ReturnToOrigin;
      finally
        newBlocks.Free;
      end;
    finally
      blockList.Free;
    end;
  finally
    FContainer.Enabled := true;
  end;
end;


procedure TBlockMatrix.SetDestCell(ABlock: TBlock; ADX, ADY: integer);
var
  col, row: integer;
  linkBlock: TBlock;
begin
  ABlock.CalcDestinationCell(ADX, ADY, col, row);
  if IsCellExist(col, row) then begin
    linkBlock := FMatrix[row, col];
    ABlock.DestCell := TCell.Create(col, row);
    linkBlock.DestCell := TCell.Create(ABlock.Cell.Col, ABlock.Cell.Row);
    ABlock.LinkWithBlock(linkBlock);
  end;
end;


end.
