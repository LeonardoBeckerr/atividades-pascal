var
  i: integer;
  nome: string;
begin
  if not OperacaoHabilitada() then
  begin
    AdicionarLog('Execução cancelada: CheckBox desmarcado.');
    MostrarMensagem('Marque "Habilitar operação"!');
    Exit;
  end;

  nome := LerNome();
  HabilitarBotao(False);
  DefinirStatus('Processando');
  AdicionarLog('Iniciando processamento para: ' + nome);

  if nome = '' then
   begin
   MostrarMensagem('Nome invalido ou em branco!');
   Exit;
   end;

  for i := 1 to 100 do
  begin
    DefinirProgresso(i);
    if (i mod 10) = 0 then
      AdicionarLog('Etapa ' + IntToStr(i) + '% concluída');
    Pausar(15);
  end;

  if nome <> '' then
    GravarNomeNoBanco(nome);

  DefinirStatus('Concluído');
  HabilitarBotao(True);
  MostrarMensagem('Processamento concluído para ' + nome + '!');
end;
