program contarestaurante;

const
  taxa = 0.10;

var
  valor, valorTotal, valorPessoa: real;
  pessoas: integer;

begin
  writeln('Digite o valor da conta:');
  readln(valor);
  writeln('Digite o numero de pessoas:');
  readln(pessoas);

  valorTotal := valor + (valor* taxa);
  valorPessoa := valorTotal / pessoas;

  writeln('Total com taxa de servico: ', valorTotal:0:2);
  writeln('Cada pessoa paga: ', ValorPessoa:0:2);

  readln;
end.


