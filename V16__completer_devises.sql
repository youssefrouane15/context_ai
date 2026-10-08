-- V16 — Référentiel des devises complété (liste PO du 08/10/2026, Teams Squad QlickFlow) : 12 devises + MAD.
-- Idempotent : n'insère que les codes ISO absents, ne modifie pas les libellés existants.
-- PostgreSQL 12 : gen_random_uuid() n'existe pas en natif → md5()::uuid.
insert into retail.currency (id, iso_code, currency_name)
select md5(random()::text || clock_timestamp()::text || d.iso_code)::uuid, d.iso_code, d.currency_name
from (values
    ('MAD', 'Dirham marocain'),
    ('EUR', 'Euro'),
    ('USD', 'Dollar américain'),
    ('SAR', 'Riyal saoudien'),
    ('AED', 'Dirham des Émirats arabes unis'),
    ('KWD', 'Dinar koweïtien'),
    ('QAR', 'Riyal qatari'),
    ('CAD', 'Dollar canadien'),
    ('GBP', 'Livre sterling'),
    ('JPY', 'Yen japonais'),
    ('CHF', 'Franc suisse'),
    ('GIP', 'Livre de Gibraltar'),
    ('OMR', 'Rial omanais')
) as d (iso_code, currency_name)
where not exists (select 1 from retail.currency c where c.iso_code = d.iso_code);
