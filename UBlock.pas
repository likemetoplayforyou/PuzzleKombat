unit UBlock;

interface

uses
  StdCtrls, Classes;

type
  TCell = class(TObject)
  private
    FCol: integer;
    FRow: integer;
  public
    constructor Create(ACol, ARow: integer);

    property Col: integer read FCol;
    property Row: integer read FRow;
  end;


  TBlock = class;


  TBlockEvent = procedure(ABlock: TBlock) of object;


  TBlock = class(TButton)
  private
    FCell: TCell;
    FDestCell: TCell;

    FLinkBlock: TBlock;
    FMarkedRemoved: boolean;

    FOnMovedToCell: TBlockEvent;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure ClearDestCell;
    procedure MoveToNearestCell;
    procedure MoveToCell(ACol, ARow: integer);
    procedure ReturnToOrigin;
    function GetCorrectPos(
      ACurrentPos: integer; ACellEdge1, ACellEdge2: integer): integer;
    function MayMoveByPix(X, Y: integer): boolean;
    procedure MoveByPix(X, Y: integer; AStrictCell: boolean = false);
    procedure MoveByPix1(X, Y: integer; AStrictCell: boolean = false);
    function IsReady: boolean;
    procedure GetNearestCell(out ACol, ARow: integer);
    function GetDestinationCell(out ACol, ARow: integer): boolean;
    procedure CalcDestinationCell(ADX, ADY: integer; out ACol, ARow: integer);
    procedure LinkWithBlock(ABlock: TBlock);
    procedure UnLinkBlock;

//    property Col: integer read FCol;
//    property Row: integer read FRow;

    property Cell: TCell read FCell;
    property DestCell: TCell read FDestCell write FDestCell;

    property LinkBlock: TBlock read FLinkBlock;
    property MarkedRemoved: boolean read FMarkedRemoved write FMarkedRemoved;

    property OnMovedToCell: TBlockEvent
      read FOnMovedToCell write FOnMovedToCell;
  end;


implementation

uses
  Math, SysUtils;

{ TBlock }

procedure TBlock.CalcDestinationCell(
  ADX, ADY: integer; out ACol, ARow: integer);
begin
//  Result := not IsReady;
//  if not Result then
//    Exit;

  ACol := FCell.Col + Sign(ADX);
  ARow := FCell.Row + Sign(ADY);
end;


procedure TBlock.ClearDestCell;
begin
  FreeAndNil(FDestCell);
end;


constructor TBlock.Create(AOwner: TComponent);
begin
  inherited;
  FCell := TCell.Create(0, 0);
end;


destructor TBlock.Destroy;
begin
  FCell.Free;
  inherited;
end;


function TBlock.GetCorrectPos(
  ACurrentPos: integer; ACellEdge1, ACellEdge2: integer): integer;
var
  minEdge, maxEdge: integer;
begin
  Result := ACurrentPos;
  minEdge := Min(ACellEdge1, ACellEdge2) * Width;
  maxEdge := Max(ACellEdge1, ACellEdge2) * Width;
  if Result < minEdge then
    Result := minEdge
  else if Result > maxEdge then
    Result := maxEdge;
end;


function TBlock.GetDestinationCell(out ACol, ARow: integer): boolean;
begin
  Result := not IsReady;
  if not Result then
    Exit;

  if Left < (FCell.FCol * Width) then
    ACol := FCell.FCol - 1
  else if Left > (FCell.FCol * Width) then
    ACol := FCell.FCol + 1
  else
    ACol := FCell.FCol;

  if Top < (FCell.FRow * Height) then
    ARow := FCell.FRow - 1
  else if Top > (FCell.FRow * Height) then
    ARow := FCell.FRow + 1
  else
    ARow := FCell.FRow;
end;


procedure TBlock.GetNearestCell(out ACol, ARow: integer);
begin
  if Left < (FCell.FCol * Width - Width div 2) then
    ACol := FCell.FCol - 1
  else if Left > (FCell.FCol * Width + Width div 2) then
    ACol := FCell.FCol + 1
  else
    ACol := FCell.FCol;

  if Top < (FCell.FRow * Height - Height div 2) then
    ARow := FCell.FRow - 1
  else if Top > (FCell.FRow * Height + Height div 2) then
    ARow := FCell.FRow + 1
  else
    ARow := FCell.FRow;
end;


function TBlock.IsReady: boolean;
begin
  Result := (Left = FCell.FCol * Width) and (Top = FCell.FRow * Height);
end;


procedure TBlock.LinkWithBlock(ABlock: TBlock);
begin
  FLinkBlock := ABlock;
  FLinkBlock.FLinkBlock := Self;
end;


function TBlock.MayMoveByPix(X, Y: integer): boolean;
var
  newX: integer;
  newY: integer;
  minX: integer;
  maxX: integer;
  minY: integer;
  maxY: integer;
begin
  Result := DestCell <> nil;
  if Result then begin
    newX := Left + X;
    newY := Top + Y;
    minX := Min(Cell.Col, DestCell.Col) * Width;
    maxX := Max(Cell.Col, DestCell.Col) * Width;
    minY := Min(Cell.Row, DestCell.Row) * Height;
    maxY := Max(Cell.Row, DestCell.Row) * Height;
    Result :=
      (minX <= newX) and (newX <= maxX) and (minY <= newY) and (newY <= maxY);
  end;
end;


procedure TBlock.MoveByPix(X, Y: integer; AStrictCell: boolean);
var
  newLeft: integer;
  newTop: integer;
begin
  newLeft := Left + X;
  newTop := Top + Y;

  if not AStrictCell then begin
    Left := Left + X;
    Top := Top + Y;
    Exit;
  end;

  if DestCell <> nil then begin
    Left := GetCorrectPos(newLeft, FCell.FCol, DestCell.FCol);
    Top := GetCorrectPos(newTop, FCell.FRow, DestCell.FRow);
  end
  else begin
    Left := FCell.FCol * Width;
    Top := FCell.FRow * Height;
  end;
end;


procedure TBlock.MoveByPix1(X, Y: integer; AStrictCell: boolean);
var
  hasDest: boolean;
  dstCol, dstRow: integer;
begin
  hasDest := GetDestinationCell(dstCol, dstRow);

  Left := Left + X;
  Top := Top + Y;
  if not AStrictCell then
    Exit;

  if (X < 0) and (Left mod Width = 0) then
    sleep(5);

//  if not hasDest then
//    Exit;
//
//  if X <> 0 then begin
//    if FCol < dstCol then begin
//      if Left >= dstCol * Width then
//        MoveToCell(dstCol, FRow)
//      else if Left <= FCol * Width then
//        MoveToCell(FCol, FRow);
//    end
//    else begin
//      if Left >= FCol * Width then
//        MoveToCell(FCol, FRow)
//      else if Left <= dstCol * Width then
//        MoveToCell(dstCol, FRow);
//    end;
//  end;
//
//  if Y <> 0 then begin
//    if FRow < dstRow then begin
//      if Top >= dstRow * Height then
//        MoveToCell(FCol, dstRow)
//      else if Top <= FCol * Height then
//        MoveToCell(FCol, FRow);
//    end
//    else begin
//      if Top >= FCol * Height then
//        MoveToCell(FCol, FRow)
//      else if Top <= dstCol * Height then
//        MoveToCell(FCol, dstRow);
//    end;
//  end;


//  if Left >= (FCol + 1) * Width then
//    MoveToCell(FCol + 1, FRow)
//  else if Left <= (FCol - 1) * Width then
//    MoveToCell(FCol - 1, FRow);
//
//  if Top >= (FRow + 1) * Height then
//    MoveToCell(FCol, FRow + 1)
//  else if Top < (FRow - 1) * Height then
//    MoveToCell(FCol, FRow - 1);

end;


procedure TBlock.MoveToCell(ACol, ARow: integer);
begin
  Left := ACol * Width;
  Top := ARow * Height;
  FCell.FCol := ACol;
  FCell.FRow := ARow;
//  if Assigned(FOnMovedToCell) then
//    FOnMovedToCell(Self);
end;


procedure TBlock.MoveToNearestCell;
var
  col, row: integer;
begin
  GetNearestCell(col, row);
  MoveToCell(col, row);
end;


procedure TBlock.ReturnToOrigin;
begin
  MoveToCell(FCell.Col, FCell.Row);
end;


procedure TBlock.UnLinkBlock;
begin
  if FLinkBlock <> nil then
    FLinkBlock.FLinkBlock := nil;
  FLinkBlock := nil;
end;

{ TCell }

constructor TCell.Create(ACol, ARow: integer);
begin
  inherited Create;
  FCol := ACol;
  FRow := ARow;
end;


end.
