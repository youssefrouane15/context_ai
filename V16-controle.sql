-- Avant : colonnes de retail.currency (attendu : id uuid, iso_code, currency_name — si une colonne NOT NULL de plus existe, me le dire)
select column_name, data_type, is_nullable, column_default
from information_schema.columns where table_schema = 'retail' and table_name = 'currency' order by ordinal_position;

-- Avant / après : contenu (après V16 : 13 lignes dont MAD)
select iso_code, currency_name from retail.currency order by iso_code;
