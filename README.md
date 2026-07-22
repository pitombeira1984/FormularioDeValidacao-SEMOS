# Formulário de Validação – SEMOS (FINEP Smart Factory)

Formulário web single-page para coleta e consolidação dos dados de validação do **SEMOS** (Sistema Embarcado Modular para Operações de Soldagem), desenvolvido pela **INOTEC – Inovação e Tecnologia** (CNPJ: 41.561.496/0001-50) no âmbito do projeto **FINEP Smart Factory**.

A aplicação é usada pelas empresas validadoras para registrar, antes e depois da adoção do SEMOS, os indicadores de **Produtividade** e **OEE**, além de uma avaliação qualitativa da solução — permitindo apurar se as metas do FINEP foram atingidas e gerar a planilha final de resultados.

## Como usar

Não há build: basta abrir o arquivo `index.html` em um navegador moderno (Chrome, Edge, Firefox).

```
start index.html   # Windows
```

Sem configurar o Supabase (veja abaixo), o formulário funciona normalmente, mas cada navegador guarda seus próprios dados isoladamente, como antes.

## Funcionalidades

- **Formulário por empresa** — suporta até 36 empresas validadoras, selecionáveis por um seletor no topo da página.
- **Identificação da empresa** — nome, CNPJ (com máscara automática), segmento, responsável, CPF do responsável (com máscara e validação dos dígitos verificadores), cargo, e-mail, nº de colaboradores e de máquinas de solda.
- **Descrição do processo** — processos de soldagem utilizados, equipamento monitorado, turno de operação, forma de controle antes do SEMOS e modo de uso do sistema.
- **Medição de Produtividade** — compara um período inicial (sem SEMOS) e final (com SEMOS), calculando `Produção Total ÷ Horas Trabalhadas` e a variação percentual. Meta FINEP: ganho ≥ 20%.
- **OEE (Eficiência Global dos Equipamentos)** — calcula Disponibilidade, Desempenho e Qualidade para os períodos inicial e final, e o OEE total (`Disponibilidade × Desempenho × Qualidade`). Meta FINEP: ganho ≥ 10%.
- **Benefícios observados** — lista de benefícios percebidos (checkboxes) e escala de impacto geral (1 a 5).
- **Avaliação funcional** — critérios fixos (facilidade de instalação, qualidade dos dados, usabilidade, confiabilidade etc.) avaliados em escala de 1 a 5.
- **Conclusão** — atendimento às expectativas, recomendação, interesse em continuidade e assinatura (nome/CPF do signatário).
- **Barra de progresso** — indica o percentual de preenchimento dos campos obrigatórios da empresa selecionada.
- **Painel Geral** — visão consolidada de todas as empresas, com contadores (preenchidas, metas atingidas, não atingidas, pendentes, sem dados) e lista navegável para cada empresa.
- **Persistência em banco de dados (Supabase)** — os dados de cada empresa são sincronizados com um banco Postgres compartilhado (via [Supabase](https://supabase.com)), permitindo que as 36 empresas preencham o formulário em máquinas diferentes e o Painel Geral mostre a visão consolidada real. Cada alteração é salva instantaneamente no `localStorage` (chave `semos_validacao_v1`, também usado como cache offline) e sincronizada com o servidor após um pequeno debounce.
- **Código de acesso por empresa** — para evitar que uma empresa sobrescreva por engano os dados de outra, cada empresa possui um código de acesso (definido no banco) solicitado na primeira gravação da sessão. Não é um sistema de login completo — a leitura dos dados (usada pelo Painel Geral) continua aberta, mas apenas através de uma view (`respostas_publicas`) que não expõe os códigos de acesso, evitando que sejam lidos pela API pública.
- **Backup / Restauração** — exportação e importação dos dados em arquivo JSON, útil para fazer backup local ou recuperar o preenchimento se o navegador ficar sem acesso ao banco.
- **Exportação para Excel (FINEP)** — gera uma planilha `.xlsx` (via [SheetJS](https://cdnjs.cloudflare.com/ajax/libs/xlsx/0.18.5/xlsx.full.min.js)) com duas abas:
  - `RESULTADOS INDICADORES`: resumo no formato exigido pela FINEP (ganho médio de produtividade, ganho médio de OEE, CNPJs das empresas validadoras).
  - `DADOS COMPLETOS`: tabela detalhada com todos os indicadores calculados por empresa.

## Estrutura do projeto

```
index.html          # Aplicação completa (HTML + CSS + JavaScript), sem build
supabase/schema.sql  # Script de setup do banco (tabela, RLS, view pública, função de gravação, seed dos códigos de acesso)
README.md
```

## Tecnologias

- HTML5, CSS3 e JavaScript puro (sem frameworks)
- [SheetJS (xlsx)](https://sheetjs.com/) para geração do relatório Excel
- [Supabase](https://supabase.com) (Postgres gerenciado) para persistência centralizada dos dados
- `localStorage` do navegador como cache local / fallback offline

## Configuração do banco de dados (Supabase)

1. Criar um projeto gratuito em [supabase.com](https://supabase.com).
2. No **SQL Editor** do projeto, rodar o script `supabase/schema.sql` — ele cria a tabela `respostas`, a RLS, a view pública `respostas_publicas` (usada para leitura, sem expor os códigos de acesso), a função `salvar_empresa` (que valida o código de acesso antes de gravar) e já popula as 36 empresas com códigos de acesso iniciais (`SEMOS01`...`SEMOS36`).
3. Em **Project Settings → API Keys**, copiar a **Project URL** e a chave pública do cliente:
   - Projetos novos: a **Publishable key** (`sb_publishable_...`).
   - Projetos no esquema legado: a chave **anon public** (formato JWT).

   ⚠️ **Nunca** use a **Secret key** (`sb_secret_...`) ou a `service_role` no `index.html` — essas chaves ignoram a RLS e dão acesso total de leitura/escrita ao banco a quem abrir o arquivo.
4. No `index.html`, preencher as constantes `SUPABASE_URL` e `SUPABASE_ANON_KEY` (próximo a `STORAGE_KEY`) com esses valores. A chave publicável/anon é pública por design do Supabase — a proteção real está na RLS, na view de leitura e na função de gravação criadas pelo script.
5. Trocar os códigos de acesso padrão (`SEMOS01`...`SEMOS36`) por códigos próprios antes de distribuir o link/arquivo às empresas validadoras, e comunicar o código de cada uma individualmente.

Sem esses passos, o app detecta a ausência de configuração e continua funcionando apenas com `localStorage`, como antes.

## Observações

- Com o Supabase configurado, os dados ficam centralizados no banco; sem ele, ficam apenas no navegador do usuário. Em ambos os casos, recomenda-se usar o botão **Backup JSON** periodicamente como cópia de segurança adicional.
- O botão **Limpar** remove apenas os dados da empresa atualmente selecionada (localmente e no servidor, se configurado), com confirmação prévia.
- Se a conexão com o servidor cair durante o preenchimento, os dados continuam sendo salvos no `localStorage` e sincronizados automaticamente assim que a conexão voltar (indicado ao lado do botão **Salvar**).


