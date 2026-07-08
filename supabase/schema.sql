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

-- Nenhuma policy de select/insert/update é criada para o role anon
-- na tabela em si: a coluna codigo_acesso não pode ficar legível pelo
-- cliente, senão qualquer um lê os códigos direto pela API REST e
-- burla a validação da função salvar_empresa. Leitura pública
-- acontece só pela view "respostas_publicas" (abaixo), que expõe
-- apenas as colunas seguras. Toda escrita passa obrigatoriamente
-- pela função abaixo, que valida o código de acesso antes de gravar.
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

-- View pública: expõe só o que o app precisa para o Painel Geral
-- (empresa_id, dados, updated_at), sem a coluna codigo_acesso.
-- Views são executadas com o papel do dono (quem rodou este script),
-- por isso enxergam todas as linhas mesmo sem policy de select na
-- tabela — é o mecanismo padrão do Postgres/Supabase para expor um
-- subconjunto de colunas com segurança.
create or replace view respostas_publicas as
  select empresa_id, dados, updated_at from respostas;

grant select on respostas_publicas to anon, authenticated;

-- Seed: 36 empresas com código de acesso inicial.
-- IMPORTANTE: trocar os códigos abaixo (ou gerar novos) antes de
-- distribuir o link/arquivo às empresas validadoras.
insert into respostas (empresa_id, codigo_acesso)
select i, 'SEMOS' || lpad(i::text, 2, '0')
from generate_series(1, 36) as i;
