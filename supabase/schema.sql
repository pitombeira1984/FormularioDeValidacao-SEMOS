-- ═══════════════════════════════════════════════════════════
-- SEMOS – Validação FINEP | Setup do banco (Supabase/Postgres)
-- Rode este script inteiro no SQL Editor de um projeto Supabase novo.
-- ═══════════════════════════════════════════════════════════

create table respostas (
  empresa_id     integer primary key,
  codigo_acesso  text not null,
  dados          jsonb not null default '{}',
  updated_at     timestamptz not null default now()
);

alter table respostas enable row level security;

-- Leitura aberta (mantém o comportamento atual do Painel Geral,
-- que já mostra todas as empresas para quem tem o arquivo).
create policy "leitura publica" on respostas
  for select using (true);

-- Nenhuma policy de insert/update é criada para o role anon:
-- toda escrita passa obrigatoriamente pela função abaixo,
-- que valida o código de acesso antes de gravar.
create or replace function salvar_empresa(p_empresa_id int, p_codigo text, p_dados jsonb)
returns void
language plpgsql
security definer
as $$
begin
  if not exists (
    select 1 from respostas
    where empresa_id = p_empresa_id and codigo_acesso = p_codigo
  ) then
    raise exception 'codigo_invalido';
  end if;

  update respostas
    set dados = p_dados, updated_at = now()
    where empresa_id = p_empresa_id;
end;
$$;

-- Seed: 36 empresas com código de acesso inicial.
-- IMPORTANTE: trocar os códigos abaixo (ou gerar novos) antes de
-- distribuir o link/arquivo às empresas validadoras.
insert into respostas (empresa_id, codigo_acesso)
select i, 'SEMOS' || lpad(i::text, 2, '0')
from generate_series(1, 36) as i;
