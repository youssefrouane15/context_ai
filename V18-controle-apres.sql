-- Contrôle APRÈS démarrage d'utilisateurs-ci (V18 appliquée)
set search_path to qf_admin;
select version, description, success, installed_on from flyway_schema_history order by installed_rank desc limit 3;

select o.code, o.name, z.code as zone, o.prestataire, o.cout_deplacement
from orga_unit o left join zone_distribution z on z.id = o.zone_distribution_id
where o.type = 'AGENCE' order by o.code;

-- agences_sans_zone doit être égal au nombre de lignes de la liste B du contrôle avant
select count(*) filter (where zone_distribution_id is null) as agences_sans_zone,
       count(*) filter (where prestataire is null)          as agences_sans_prestataire,
       count(*) filter (where cout_deplacement is null)     as agences_sans_cout,
       count(*) as total
from orga_unit where type = 'AGENCE';

select * from zone_distribution order by code;
