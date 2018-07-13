program PuzzleKombat;

uses
  Forms,
  UPuzzleKombatForm in 'UPuzzleKombatForm.pas' {frmPuzzleKombat},
  UBlockMatrix in 'UBlockMatrix.pas',
  UBlock in 'UBlock.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmPuzzleKombat, frmPuzzleKombat);
  Application.Run;
end.
