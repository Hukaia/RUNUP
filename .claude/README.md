# Ce que Claude peut faire sans redemander

Charlotte, le 19 novembre 2026 : « Valide les sql tout seul », puis
« les deux » — ce fichier vit donc à l'identique dans les deux dépôts,
Haizo et Hukaia.

## Pourquoi un fichier, et pas une autorisation donnée au clavier

Une autorisation accordée dans une conversation ne vit que dans la
mémoire de la session. Le 17 novembre au soir, le processus de la session
a redémarré une dizaine de fois, et à chaque redémarrage la demande
revenait : « autoriser l'exécution SQL ? ». Vingt-quatre fois par jour,
une question finit par être refusée sans être lue — c'est arrivé, et un
contrôle de surveillance est passé à la trappe.

Aucun fichier de réglages n'existait, nulle part. C'était la cause, pas
le symptôme.

## Ce qui est autorisé

`mcp__Supabase__execute_sql`, et les lectures qui l'accompagnent :
tables, migrations, extensions, fonctions, journaux, conseils de santé.
C'est ce qui sert à regarder la base — compter les voyages, relever un
accès, lire une trace.

## Ce qui reste derrière une demande

Les migrations (`apply_migration`), les déploiements de fonctions, les
secrets de fonction, les branches de base et tout ce qui touche au projet
lui-même. C'est la règle de Charlotte du 10 novembre, inchangée : « ne
corrige rien en production et ne déploie rien sans mon accord ».

## Ce que ce fichier ne sait PAS faire, et qu'il faut savoir

**`execute_sql` ne se coupe pas en deux.** Une règle de permission ne
distingue pas un `select` d'un `delete` : autoriser la lecture autorise
l'écriture sur la base de production. Ce qui reste entre une faute de
frappe et les données des voyageurs, c'est la règle de conduite
ci-dessus — pas le logiciel. Le connecteur Supabase redemande
confirmation sur certaines instructions destructrices, mais ce n'est pas
une garantie et il ne faut pas compter dessus.

Si cet arbitrage ne convient plus, retirer `mcp__Supabase__execute_sql`
de la liste `allow` suffit : on revient à une demande par requête, et la
frontière redevient tenue par le logiciel.

## Un réglage personnel ne va pas ici

`settings.json` est versionné : il s'applique à toute session ouverte sur
ce dépôt. Pour un réglage qui ne regarde qu'une machine, utiliser
`.claude/settings.local.json`, qui n'est pas suivi par git.
