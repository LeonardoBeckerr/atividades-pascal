# Atividades Pascal & Lazarus

Repositório com projetos de estudo e desafios desenvolvidos em **Free Pascal** e **Lazarus (LCL)**, indo de exercícios de console até aplicações desktop com scripts em tempo de execução (**JEDI `JvInterpreter`**) e persistência em **Firebird 4.0**.

---

## Projetos

| Pasta | Tipo | Descrição |
| :--- | :--- | :--- |
| [`ContaRestaurante/`](ContaRestaurante/) | Console | Calcula o valor total de uma conta com taxa de serviço de 10% e o valor por pessoa. |
| [`ConversorAlgarismosRomanos/`](ConversorAlgarismosRomanos/) | Console | Converte números inteiros positivos para algarismos romanos. |
| [`Mapa de Inserções Comerciais/`](Mapa%20de%20Inserções%20Comerciais/) | Desktop (LCL) | Sistema de agendamento de inserções comerciais em faixas de rádio, com barra de ocupação, ordenação da grade e relatório de faturamento. |
| [`Mapa de Inserções Comerciais V2/`](Mapa%20de%20Inserções%20Comerciais%20V2/) | Desktop (LCL + JvInterpreter) | Evolução do Mapa de Inserções Comerciais permitindo alterar em tempo de execução regras de cálculo (`scripts/regras_comerciais.pas`), exportação (`scripts/exportacao.pas`) e geração de relatório HTML (`scripts/relatorio_html.pas`). |
| [`PrototipoJvInterpreter/`](PrototipoJvInterpreter/) | Desktop (LCL + JvInterpreter) | Protótipo inicial para testar execução dinâmica de scripts Pascal integrados ao formulário. |
| [`DesafioJvInterpreter/`](DesafioJvInterpreter/) | Desktop (LCL + JvInterpreter + Firebird) | Aplicação completa com comunicação bidirecional entre scripts `.pas` e componentes visuais, carga/salvamento de scripts externos e integração com Firebird 4.0 (criação automática do `.fdb`, tabela `NOMES`, generator `GEN_NOMES_CODIGO`, trigger `NOMES_BI` e validação contra nomes duplicados). Veja também a [explicação detalhada do código](DesafioJvInterpreter/EXPLICACAO_CODIGO_DESAFIO_JVINTERPRETER.md). |

---

## Como compilar e executar

### 1. Projetos Console e `Mapa de Inserções Comerciais`
- Abra o arquivo `.lpi` correspondente no **Lazarus** (32 ou 64 bits) e pressione `F9`.

### 2. Projetos com `JvInterpreter` (`PrototipoJvInterpreter`, `Mapa de Inserções Comerciais V2`, `DesafioJvInterpreter`)
- Utilize **Lazarus 32 bits (`i386-win32`)**, pois o pacote `JvPascalInterpreter` do `JvclLaz` destina-se à arquitetura 32 bits.
- Instale o pacote **`JvclLaz`** (`JvPascalInterpreterR`) pelo *Online Package Manager* do Lazarus.
- Abra o `.lpi` do projeto desejado e pressione `F9`.

### 3. Requisitos extras do `DesafioJvInterpreter` (Firebird 4.0)
- Tenha o servidor **Firebird 4.0** (com biblioteca cliente `fbclient.dll` 32 bits disponível) em execução em `localhost`.
- O pacote padrão **`SQLDBLaz`** do Lazarus precisa estar instalado.
- O arquivo `.fdb` não é versionado neste repositório: ao clicar em **Conectar / Criar Base** ou executar um script, a aplicação cria automaticamente o banco, a tabela `NOMES`, o generator `GEN_NOMES_CODIGO` e a trigger `NOMES_BI`.
- As credenciais configuradas no projeto são as padrão de ambiente local de estudo (`SYSDBA` / `masterkey`).

---

## Observações sobre o repositório

- Executáveis (`*.exe`), arquivos de compilação (`lib/`, `*.o`, `*.ppu`), backups da IDE (`backup/`), arquivos de sessão local (`*.lps`), DLLs e bancos locais (`*.fdb`) são ignorados via [`.gitignore`](.gitignore).
