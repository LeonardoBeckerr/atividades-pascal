var
  nome: string;
begin
  nome := LerNome();
  AdicionarLog('Script solicitando processamento para: ' + nome);
  ExecutarProcessamento(50);
  MostrarMensagem('Rotina da aplicação finalizada!');
end;
