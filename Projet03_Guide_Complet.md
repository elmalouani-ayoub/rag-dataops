# Projet 3 — Pipeline DataOps industrialisé (dbt + CI/CD + IaC) : le guide complet

> **À qui s'adresse ce document ?** À tout le monde. Un lecteur non technique doit
> pouvoir comprendre *l'intuition* et *le pourquoi* ; un lecteur technique doit y
> trouver la *rigueur* (modélisation, variables, limites). On avance du simple au précis.

---

## Comment lire ce document

Chaque concept important est expliqué en **trois temps**, toujours dans le même ordre :

1. **L'intuition** — une image mentale, sans jargon. « De quoi on parle, au fond ? »
2. **L'explication (périmètre & variables)** — la définition rigoureuse, les paramètres
   qui la font varier, le fonctionnement précis.
3. **Les limites** — ce que le concept ne fait *pas*, ses angles morts, ses pièges.

> Ce projet **industrialise les deux précédents**. Il ne demande pas de comprendre le RAG en
> détail : ici, les résultats du Projet 1 sont simplement **des données** qu'on va traiter
> comme un ingénieur data traiterait des ventes ou des transactions.

**Table des matières**

1. [L'intuition du projet](#1-lintuition-du-projet)
2. [Ce que fait le projet, concrètement](#2-ce-que-fait-le-projet-concrètement)
3. [Les prérequis pratiques](#3-les-prérequis-pratiques)
4. [Tous les concepts, expliqués](#4-tous-les-concepts-expliqués)
5. [Pourquoi ces choix techniques](#5-pourquoi-ces-choix-techniques)
6. [Le déroulé du pipeline, étape par étape](#6-le-déroulé-du-pipeline-étape-par-étape)
7. [Les ressources externes à rassembler](#7-les-ressources-externes-à-rassembler)
8. [Déposer le projet sur GitHub, pas à pas](#8-déposer-le-projet-sur-github-pas-à-pas)
9. [Comment le valoriser (CV / entretien)](#9-comment-le-valoriser-cv--entretien)
10. [Glossaire express](#10-glossaire-express)

---

## 1. L'intuition du projet

### Le problème de départ

Le Projet 1 a produit un tableau de résultats : 88 configurations testées, des chiffres, des
graphiques. C'est une **analyse ponctuelle**. Elle vit dans un fichier CSV sur un ordinateur.

Trois questions embarrassantes se posent :

- Si quelqu'un modifie le code du RAG, **comment savoir** si les résultats se dégradent ?
- Si un chiffre est aberrant (un taux de réussite de 1,5, ce qui est impossible), **qui
  s'en aperçoit** ?
- Si on veut brancher un outil de visualisation (Power BI), **où va-t-il chercher** les
  données proprement structurées ?

Une analyse ponctuelle ne répond à aucune de ces questions. Il lui manque
l'**industrialisation**.

### L'idée du projet

Transformer cette analyse en un **actif de données gouverné** :

- les données sont **chargées** et **transformées** de façon systématique ;
- elles sont **organisées** dans une structure standard, compréhensible par n'importe quel
  analyste (le « schéma en étoile ») ;
- elles sont **testées** automatiquement (une valeur impossible fait échouer le pipeline) ;
- tout est **rejoué automatiquement** à chaque modification du code (CI/CD) ;
- le tout est **portable** : ça tourne sur votre laptop comme dans le cloud.

C'est ça, le **DataOps** : appliquer aux données la discipline que les développeurs
appliquent au code (tests, automatisation, versionnage, reproductibilité).

### Pourquoi c'est malin

Trois offres d'emploi demandent exactement ce vocabulaire : *pipelines CI/CD* (Michelin),
*qualité de données et transformation ELT* (Ofi Invest), *industrialisation et IaC*
(Doctolib). Ce projet coche les trois cases avec un **seul** pipeline.

Et surtout : il **boucle la trilogie**. Le Projet 1 produit les données, le Projet 2 les
expose, le Projet 3 les industrialise. Un seul produit cohérent, pas trois exercices isolés.

---

## 2. Ce que fait le projet, concrètement

En une phrase : **le projet prend les 1 760 lignes de résultats du Projet 1, les charge dans
un entrepôt de données, les transforme en un modèle en étoile propre, applique 37 tests de
qualité, et rejoue tout automatiquement à chaque modification.**

Le déroulé :

1. **Chargement** : les résultats d'évaluation (une ligne par configuration × question) et
   deux référentiels (les questions, les documents) entrent dans l'entrepôt.
2. **Nettoyage** (couche *staging*) : typage des colonnes, création de clés d'identification.
3. **Modélisation** (couche *marts*) : construction d'un **schéma en étoile** — une table de
   faits entourée de quatre tables de dimensions.
4. **Agrégation** : une table finale prête pour la BI, qui classe les configurations par
   qualité.
5. **Tests** : 37 contrôles automatiques (clés uniques, valeurs plausibles, cohérence métier,
   intégrité entre les tables).
6. **Automatisation** : à chaque `push` sur GitHub, tout est rejoué. Si un test échoue, le
   build devient rouge.

Résultat vérifié : **49 contrôles passent, 0 erreur**. Et le pipeline retrouve, dans
l'entrepôt, exactement la meilleure configuration identifiée au Projet 1 — preuve que la
chaîne est cohérente de bout en bout.

---

## 3. Les prérequis pratiques

**Compétences utiles (pas besoin d'être expert) :**

- Des notions de **SQL** (savoir lire un `SELECT ... FROM ... WHERE`). C'est le langage
  principal du projet.
- Savoir ouvrir un **terminal**.
- Notions de **Git** (rappelées au §8).

**À installer sur votre machine :**

- **Python 3.10+** — dbt s'installe via `pip`.
- **dbt-duckdb** — une seule commande : `pip install -r requirements.txt`.
- **Git** — pour versionner et publier.
- *(optionnel)* **Docker** — pour exécuter le pipeline en conteneur.
- *(optionnel)* **Terraform** + un compte **GCP** — uniquement si vous voulez déployer sur
  BigQuery.

**Le pipeline tourne 100 % en local et gratuitement** grâce à DuckDB (§4.5). Aucun compte
cloud n'est nécessaire — c'est un choix délibéré (voir §5).

---

## 4. Tous les concepts, expliqués

Méthode en trois temps : intuition → explication/variables → limites.

### 4.1 Le DataOps

- **Intuition.** Les développeurs ont depuis longtemps des tests automatiques, du versionnage
  et des déploiements fiables. Le **DataOps**, c'est appliquer ces mêmes réflexes **aux
  données** : versionner les transformations, tester la qualité, automatiser l'exécution.
  Autrement dit : arrêter de bricoler des tableurs, commencer à faire de l'ingénierie.
- **Explication & variables.** Le DataOps combine trois cultures : le **génie logiciel**
  (tests, revue de code, Git), les **opérations** (automatisation, supervision) et la
  **gestion de données** (qualité, gouvernance, documentation). Les leviers concrets :
  transformations versionnées, tests de données, CI/CD, infrastructure décrite en code.
- **Limites.** Le DataOps est une **discipline**, pas un outil qu'on installe. Il ajoute de la
  rigueur (donc du travail initial) et ne remplace pas la compréhension métier des données.
  Un pipeline parfaitement testé peut modéliser une réalité fausse.

### 4.2 L'entrepôt de données (data warehouse)

- **Intuition.** Un **entrepôt de données** est une base conçue pour **analyser**, pas pour
  faire fonctionner une application. La différence : une caisse de supermarché enregistre les
  ventes une par une (base transactionnelle) ; l'entrepôt sert à répondre à « quelles sont mes
  meilleures ventes par région et par mois ? ».
- **Explication & variables.** Un entrepôt est optimisé pour lire beaucoup de lignes et
  agréger (sommes, moyennes, classements). Il stocke souvent les données **en colonnes**
  plutôt qu'en lignes, ce qui accélère énormément ces calculs. Variables : le moteur choisi
  (DuckDB, BigQuery, Snowflake…), le volume, la fréquence de rafraîchissement.
- **Limites.** Un entrepôt n'est pas fait pour les écritures unitaires rapides ni pour servir
  une application en temps réel. Ce n'est pas une base « à tout faire ».

### 4.3 ETL et ELT

- **Intuition.** Il faut Extraire les données, les Transformer et les Charger. La question est
  **dans quel ordre**. L'ancienne façon (**ETL**) transforme *avant* de charger : on cuisine
  puis on range au frigo. La façon moderne (**ELT**) charge *d'abord* les données brutes, puis
  transforme **dans l'entrepôt** : on range au frigo, puis on cuisine sur place.
- **Explication & variables.** L'ELT tire parti de la puissance des entrepôts modernes : la
  transformation se fait en SQL, directement là où sont les données. Avantage majeur : la
  donnée brute est **conservée**, on peut donc rejouer une transformation différemment sans
  ré-extraire quoi que ce soit. C'est le mode de fonctionnement de dbt (§4.4), et le terme
  exact employé dans l'offre Ofi Invest.
- **Limites.** L'ELT suppose un entrepôt capable d'encaisser la transformation. Charger des
  données brutes très volumineuses ou très sales peut coûter cher en stockage et en calcul.

### 4.4 dbt (l'outil de transformation)

- **Intuition.** **dbt** (*data build tool*) permet d'écrire ses transformations en **SQL
  simple**, et s'occupe de tout le reste : l'ordre d'exécution, les dépendances entre les
  tables, les tests, la documentation. Écrire une transformation revient à écrire un
  `SELECT` ; dbt le transforme en table ou en vue dans l'entrepôt.
- **Explication & variables.** Chaque **modèle** dbt est un fichier `.sql` contenant un
  `SELECT`. Quand un modèle en référence un autre (avec la fonction `ref()`), dbt **déduit
  automatiquement l'ordre d'exécution** et construit un graphe de dépendances (§4.11). Un
  fichier `.yml` accompagne les modèles pour les **documenter** et les **tester** (§4.10).
- **Limites.** dbt **transforme** les données, il ne les **extrait** pas (il ne va pas
  chercher les données dans une API ou un site web) et ne les **orchestronne** pas dans le
  temps (pas de planification horaire native). Il fait une chose, et il la fait bien.

### 4.5 DuckDB et BigQuery (où vivent les données)

- **Intuition.** **DuckDB** est un entrepôt analytique qui tient dans un simple fichier sur
  votre ordinateur — pensez à « SQLite pour l'analyse ». **BigQuery** est l'entrepôt de Google
  dans le cloud, capable de traiter des téraoctets. Le projet fonctionne avec les deux.
- **Explication & variables.** Le fichier `profiles.yml` définit deux **cibles** : `dev`
  (DuckDB, local, gratuit) et `prod` (BigQuery, cloud). Le point remarquable : **les mêmes
  modèles SQL tournent sur les deux sans changer une ligne de code**. On change juste la cible
  (`--target prod`).
- **Limites.** DuckDB est mono-machine : il ne convient pas à des volumes massifs ni à
  plusieurs utilisateurs simultanés. BigQuery, lui, est puissant mais **payant** et nécessite
  un compte GCP. D'où le choix de DuckDB par défaut.

### 4.6 L'architecture en couches (seeds → staging → marts)

- **Intuition.** On ne passe pas de la donnée brute au tableau de bord d'un coup. On procède
  par **étages**, chacun avec un rôle clair : les données arrivent brutes (rez-de-chaussée),
  on les nettoie (premier étage), puis on les organise pour l'analyse (deuxième étage).
- **Explication & variables.** Les trois couches du projet :
  - **seeds** — les données brutes telles quelles (fichiers CSV chargés dans l'entrepôt).
  - **staging** — nettoyage, typage des colonnes, création de clés. Un modèle de staging par
    source. Matérialisés en **vues** (§4.9).
  - **marts** — la modélisation métier prête à l'usage (schéma en étoile). Matérialisés en
    **tables**.
- **Limites.** Cette séparation multiplie le nombre de fichiers. Sur un tout petit projet, elle
  peut sembler excessive — mais c'est justement la convention qui rend un projet lisible par
  quelqu'un d'autre, et donc **professionnel**.

### 4.7 La modélisation dimensionnelle : le schéma en étoile

- **Intuition.** Comment ranger des données pour qu'un analyste s'y retrouve ? On sépare **ce
  qu'on mesure** (les *faits* : un score, un montant) de **ce qui décrit** (les *dimensions* :
  quelle configuration, quelle question, quel document). Sur un schéma, la table de faits est
  au centre et les dimensions rayonnent autour : d'où le nom d'**étoile**.
- **Explication & variables.**
  - La **table de faits** (`fct_retrieval`) contient les **mesures** numériques (hit, MRR,
    span_recall, precision) et des **clés étrangères** vers les dimensions.
  - Les **dimensions** (`dim_config`, `dim_question`, `dim_document`, `dim_embedding`)
    contiennent les attributs descriptifs.
  - Le **grain** est la notion la plus importante : c'est « ce que représente une ligne ».
    Ici, le grain de la table de faits est **une configuration × une question**. D'où
    88 × 20 = **1 760 lignes**. Définir le grain avant tout est la règle d'or de la
    modélisation.
- **Limites.** Le schéma en étoile est adapté à l'**analyse**, pas à toutes les situations
  (relations complexes, graphes). Il implique une certaine redondance (assumée : elle rend les
  requêtes simples et rapides).

### 4.8 Les clés de substitution (surrogate keys)

- **Intuition.** Pour relier deux tables, il faut un identifiant unique et stable. Plutôt que
  d'utiliser une combinaison bancale (« tfidf | 80 | 40 | 3 »), on fabrique une **clé
  technique** : une empreinte unique calculée à partir de ces valeurs.
- **Explication & variables.** Le projet crée `config_key` et `retrieval_key` en appliquant une
  fonction de hachage (`md5`) à la concaténation des colonnes qui définissent la ligne. Cette
  clé est **déterministe** : les mêmes valeurs donnent toujours la même clé (donc le pipeline
  est rejouable à l'identique).
- **Limites.** Une clé de substitution n'a **aucun sens métier** : on ne peut pas la lire. Elle
  sert uniquement à joindre les tables. Il faut donc garder à côté les colonnes lisibles.

### 4.9 Les matérialisations (vue vs table)

- **Intuition.** Un modèle dbt peut exister de deux façons dans l'entrepôt. Une **vue** est une
  requête enregistrée : elle ne stocke rien, elle se recalcule à chaque consultation (comme une
  recette). Une **table** stocke réellement les résultats (comme le plat déjà cuisiné).
- **Explication & variables.** Le projet matérialise le **staging en vues** (léger, toujours
  frais) et les **marts en tables** (rapides à interroger, car pré-calculés). C'est un
  compromis classique entre **coût de stockage** et **vitesse de lecture**.
- **Limites.** Une table est rapide mais peut devenir **périmée** si la source change sans
  qu'on relance le pipeline. Une vue est toujours à jour mais peut être lente sur de gros
  volumes.

### 4.10 Les tests de qualité de données

- **Intuition.** Un test de données pose une question à laquelle la réponse doit être « aucune
  ligne ». Par exemple : « montre-moi les lignes où le taux de réussite dépasse 100 % ». S'il
  en existe une, quelque chose est cassé, et le pipeline s'arrête.
- **Explication & variables.** Le projet utilise quatre familles :
  - **Tests génériques standards** : `unique` (pas de doublon), `not_null` (pas de trou),
    `accepted_values` (la colonne `hit` ne peut valoir que 0 ou 1).
  - **Intégrité référentielle** (`relationships`) : chaque clé de la table de faits doit
    exister dans la dimension correspondante. **Aucune ligne orpheline.**
  - **Test générique personnalisé** (`accepted_range`, écrit pour le projet) : une valeur doit
    rester dans un intervalle, par exemple `hit_rate` ∈ [0, 1].
  - **Test singulier** (une règle métier écrite en SQL) : le rang réciproque doit valoir 0
    exactement quand le document n'a pas été trouvé, et être strictement positif sinon.
- **Limites.** Les tests vérifient ce qu'on a **pensé à vérifier**. Ils attrapent les
  incohérences structurelles, pas les erreurs de conception. Un test passant ne prouve pas que
  la donnée est *juste*, seulement qu'elle est *plausible*.

### 4.11 Le lignage et le graphe de dépendances (DAG)

- **Intuition.** Le **lignage** répond à : « d'où vient cette colonne, et qu'est-ce qui casse
  si je la modifie ? ». dbt le construit tout seul : en voyant qu'un modèle en référence un
  autre, il déduit l'ordre et dessine la carte complète des dépendances.
- **Explication & variables.** Cette carte est un **DAG** (*graphe orienté acyclique*) :
  orienté parce que les flèches vont dans un sens (source → transformation), acyclique parce
  qu'un modèle ne peut pas dépendre de lui-même. dbt s'en sert pour exécuter les modèles dans
  le bon ordre et en parallèle quand c'est possible. La commande `dbt docs` génère une
  documentation navigable avec ce graphe.
- **Limites.** Le lignage de dbt s'arrête aux frontières de dbt : il ne sait pas d'où venaient
  les données *avant* d'entrer dans le pipeline, ni ce qu'un tableau de bord en fait *après*.

### 4.12 L'idempotence et la reproductibilité

- **Intuition.** **Idempotent** signifie : « lancer une fois ou dix fois donne le même
  résultat ». Un pipeline idempotent peut être relancé sans crainte, sans dupliquer ni
  corrompre les données. C'est ce qui permet de dormir tranquille.
- **Explication & variables.** Dans le projet, `dbt build` reconstruit les modèles à partir des
  sources : mêmes entrées → mêmes sorties. Les clés de substitution étant déterministes (§4.8),
  rien ne dérive d'une exécution à l'autre. C'est ce qui rend l'exécution en CI (§4.13) fiable.
- **Limites.** L'idempotence devient plus délicate quand on construit des tables
  **incrémentales** (on ajoute seulement les nouvelles lignes) ou quand la source change entre
  deux exécutions. Le projet reste sur des reconstructions complètes, plus simples et sûres.

### 4.13 L'intégration continue (CI) et les tests de non-régression

- **Intuition.** À chaque fois que quelqu'un modifie le code, un robot rejoue **tout le
  pipeline** et **tous les tests**. Si quelque chose casse, on le sait immédiatement, avant que
  ça n'atteigne quiconque. Le badge du dépôt passe au rouge.
- **Explication & variables.** Le projet utilise **GitHub Actions** : un fichier décrit les
  étapes (installer dbt, lancer `dbt build`, générer la doc, sauvegarder les artefacts). Comme
  tout tourne sur DuckDB, la CI n'a besoin **d'aucun secret ni compte cloud** — elle est
  déterministe. C'est un véritable **test de non-régression** sur les données *et* sur leurs
  transformations, exactement le vocabulaire de l'offre Michelin.
- **Limites.** La CI valide ce qui est testé. Elle consomme aussi du temps de calcul : sur de
  très gros pipelines, on ne rejoue qu'une partie (les modèles modifiés et leurs descendants).

### 4.14 Docker (la reproductibilité de l'environnement)

- **Intuition.** Les tests peuvent passer chez vous et échouer ailleurs si les versions
  diffèrent. **Docker** empaquette le pipeline **avec son environnement complet** (Python, dbt,
  dépendances) dans une boîte autonome qui s'exécute à l'identique partout.
- **Explication & variables.** Le `Dockerfile` décrit la recette de l'image ; `docker run`
  exécute `dbt build` dans le conteneur. C'est la même brique que celle du Projet 2 :
  l'application *et* le pipeline sont conteneurisés.
- **Limites.** Docker garantit la reproductibilité de l'**environnement**, pas celle des
  **données** (si la source change, le résultat change, à juste titre).

### 4.15 L'Infrastructure as Code (Terraform)

- **Intuition.** Créer un entrepôt cloud « à la main » en cliquant dans une console web est
  fragile : personne ne sait ce qui a été fait, ni comment le refaire. L'**IaC** consiste à
  **écrire l'infrastructure dans des fichiers**, versionnés comme du code. On peut alors la
  recréer à l'identique, la relire, la revoir.
- **Explication & variables.** **Terraform** décrit les ressources souhaitées (ici : un dataset
  BigQuery, un compte de service, ses droits) dans des fichiers `.tf`. La commande
  `terraform plan` montre ce qui *va* changer ; `terraform apply` l'applique. Terraform tient à
  jour un « état » pour savoir ce qui existe déjà.
- **Limites.** Terraform nécessite un compte cloud (donc potentiellement des coûts) et une
  gestion soigneuse de son fichier d'état. Dans ce projet, il est **optionnel** : une vitrine
  crédible de la compétence, pas une dépendance.

### 4.16 La documentation et la gouvernance

- **Intuition.** Une donnée que personne ne comprend est une donnée inutilisable. **Documenter**
  chaque table et chaque colonne, c'est permettre à un collègue (ou à vous, dans six mois) de
  savoir ce que signifie `span_recall_rate` sans lire le code.
- **Explication & variables.** Dans dbt, la documentation vit dans les fichiers `.yml`, **à
  côté des tests** — donc elle vieillit moins vite que le code. `dbt docs generate` produit un
  site navigable avec les descriptions, les colonnes, les tests et le graphe de lignage.
- **Limites.** La documentation générée décrit la **structure**, pas les **décisions**. Le
  « pourquoi » (pourquoi ce grain, pourquoi cette métrique) reste à écrire à la main — c'est le
  rôle du README et de ce guide.

---

## 5. Pourquoi ces choix techniques

- **dbt comme outil de transformation.** C'est le **standard du marché** pour l'ELT, il est
  gratuit, et il apporte gratuitement ce que le projet doit démontrer : tests, documentation,
  lignage, ordre d'exécution automatique.
- **DuckDB par défaut.** Le pipeline tourne **sans compte cloud, sans secret, sans coût**.
  Conséquence directe et essentielle : la **CI peut rejouer tout le pipeline** à chaque push.
  Avec BigQuery, il aurait fallu des identifiants — donc pas de CI publique reproductible.
- **BigQuery comme cible optionnelle.** Elle démontre la **portabilité** : mêmes modèles, autre
  entrepôt. C'est exactement ce que demandent les offres Ofi Invest et Doctolib.
- **Schéma en étoile.** C'est la modélisation attendue dans un poste Data/BI. Elle rend les
  données lisibles par un analyste et directement branchables sur Power BI (offre Michelin).
- **Un test générique maison plutôt que la librairie `dbt_utils`.** Éviter une dépendance
  externe garde la CI **légère et hors-ligne**, et démontre au passage qu'on sait **écrire ses
  propres tests** — plus impressionnant que d'en importer.
- **Alimenter le pipeline avec les résultats du Projet 1.** Les données ne sortent pas de nulle
  part : elles viennent de votre propre travail. C'est ce qui transforme trois projets en un
  seul produit cohérent.
- **Docker + Terraform.** Ils cochent les cases « reproductibilité » et « cloud/IaC » sans
  imposer d'installation lourde pour lancer le projet.

En résumé : **chaque choix protège la propriété la plus précieuse d'un pipeline — pouvoir être
rejoué par n'importe qui, n'importe où, avec le même résultat.**

---

## 6. Le déroulé du pipeline, étape par étape

Une seule commande orchestre tout : `dbt build` (qui enchaîne *seed*, *run* et *test*).

1. **Seed** — les trois fichiers CSV (résultats d'évaluation, questions, documents) sont
   chargés dans l'entrepôt.
2. **Staging** — trois vues nettoient et typent les données, et créent les clés de
   substitution.
3. **Marts** — quatre dimensions et une table de faits sont matérialisées en tables ; puis
   l'agrégat `agg_config_performance` calcule les métriques par configuration et les classe.
4. **Tests** — 37 contrôles s'exécutent au fil de la construction. Un échec arrête tout.
5. **Documentation** — `dbt docs generate` produit le catalogue et le graphe de lignage.

**Ce que démontre l'exécution réelle :**

- `PASS=49  WARN=0  ERROR=0` — tout passe.
- La table de faits contient **1 760 lignes** = 88 configurations × 20 questions : le **grain**
  annoncé est respecté (une vérification, pas une déclaration).
- Le mart d'agrégation classe en tête la configuration `tfidf · chunk_size=80 · overlap=40`,
  soit **exactement la conclusion du Projet 1**. La chaîne complète est cohérente.

---

## 7. Les ressources externes à rassembler

**Indispensable :**

- **Python 3.10+** — [python.org](https://www.python.org).
- **dbt-duckdb** — installé via `pip install -r requirements.txt`. Il embarque DuckDB : rien
  d'autre à installer, aucune base à configurer.
- **Les données sources** — déjà présentes dans le dossier `seeds/` du dépôt. Elles ont été
  générées à partir du moteur du Projet 1. Si vous modifiez le Projet 1, régénérez-les pour
  garder la chaîne cohérente.

**Optionnel :**

- **Docker** — [docker.com](https://www.docker.com) — pour exécuter le pipeline en conteneur.
- **Terraform** — [terraform.io](https://www.terraform.io) — et un **compte Google Cloud**
  ([cloud.google.com](https://cloud.google.com)) si vous voulez déployer sur BigQuery. Attention :
  BigQuery a un palier gratuit, mais **surveillez vos coûts**.
- **dbt-bigquery** (`pip install dbt-bigquery`) pour la cible cloud.

**Un compte GitHub** — [github.com](https://github.com) — pour publier et activer la CI (§8).

**Pour approfondir (lecture) :** la documentation officielle de **dbt** et de **DuckDB**. Sur la
modélisation en étoile, la référence historique est l'approche dite « de Kimball » (méthode de
modélisation dimensionnelle) : cherchez « dimensional modeling » dans la documentation dbt.

---

## 8. Déposer le projet sur GitHub, pas à pas

**Prérequis :** compte GitHub + Git installé. Configurez votre identité une fois :

```bash
git config --global user.name "Votre Nom"
git config --global user.email "votre.email@example.com"
```

**Étape 1 — Dépôt local.**

```bash
cd rag-dataops
git init
```

**Étape 2 — Vérifier le `.gitignore`.** Il exclut `target/` (les artefacts générés par dbt),
`logs/` et les fichiers `*.duckdb` (la base de données elle-même). **Ne jamais publier la base
ni les artefacts** : ils se régénèrent avec `dbt build`. Publier des sorties générées est une
erreur classique qui alourdit un dépôt.

**Étape 3 — Commits progressifs.**

```bash
git add seeds/ dbt_project.yml profiles.yml
git commit -m "Configuration dbt et chargement des données sources"

git add models/staging/
git commit -m "Couche staging : nettoyage, typage et clés de substitution"

git add models/marts/
git commit -m "Couche marts : schéma en étoile et agrégat de performance"

git add tests/ macros/
git commit -m "Tests de qualité : test générique maison et règle métier"

git add .github/ Dockerfile Makefile terraform/ README.md
git commit -m "CI/CD GitHub Actions, conteneurisation et IaC Terraform"
```

**Étape 4 — Créer le dépôt distant** sur github.com (*New repository*, nommé `rag-dataops`,
laissé vide), puis :

```bash
git remote add origin https://github.com/VOTRE-UTILISATEUR/rag-dataops.git
git branch -M main
git push -u origin main
```

**Étape 5 — Le badge vert (le détail qui compte).**

Dès le premier `push`, GitHub Actions exécute le pipeline. Remplacez `<ton-user>` par votre
identifiant dans le badge du `README.md` : un **badge de build vert** apparaît alors en haut du
dépôt. C'est la preuve visuelle, en un coup d'œil, que votre pipeline **passe ses tests**.
Pour un recruteur DataOps, ce badge vaut mille phrases.

---

## 9. Comment le valoriser (CV / entretien)

**Sur le CV**, les lignes « Cloud & DataOps / CI/CD » passent du déclaratif au démontré :

- Avant : *« Intérêt pour le CI/CD »*.
- Après : *« Projet : pipeline de données industrialisé (dbt, schéma en étoile, 37 tests de
  qualité, CI/CD GitHub Actions, Docker, Terraform/BigQuery). »*

**En entretien**, vous pouvez parler concrètement — et ce sont les mots exacts des annonces :

- **Standardisation** : une architecture en couches et une modélisation en étoile
  reconnaissables par n'importe quel data engineer.
- **Tests de non-régression** : la CI rejoue tout le pipeline à chaque modification ; un
  chiffre aberrant fait échouer le build.
- **Reproductibilité** : DuckDB + Docker + clés déterministes → même entrée, même sortie,
  partout.
- **Qualité de données** : intégrité référentielle, valeurs acceptées, règles métier.

**L'argument le plus fort** : *« les données que j'industrialise viennent de mon propre projet
d'évaluation RAG. Le pipeline retrouve, dans l'entrepôt, exactement la conclusion de mon
analyse initiale — je peux vous montrer la chaîne complète, de la donnée brute au classement
final. »*

**Restez honnête sur l'échelle.** Entrepôt local, volumes modestes, cible cloud non déployée
par défaut. Présentez-le comme la démonstration d'une **maîtrise du socle DataOps**, pas d'une
plateforme de production.

---

## 10. Glossaire express

| Terme | En une phrase |
|-------|---------------|
| **DataOps** | Appliquer aux données la discipline du génie logiciel : tests, versionnage, automatisation. |
| **Entrepôt de données** | Base optimisée pour analyser et agréger, pas pour faire tourner une application. |
| **ETL / ELT** | Transformer avant de charger / charger d'abord, transformer ensuite dans l'entrepôt. |
| **dbt** | Outil qui transforme les données en SQL, avec tests, doc et ordre d'exécution automatiques. |
| **DuckDB** | Entrepôt analytique local, dans un simple fichier ; gratuit et rapide. |
| **BigQuery** | Entrepôt de Google dans le cloud, pour de gros volumes. |
| **Seed** | Un fichier de données brutes chargé tel quel dans l'entrepôt. |
| **Staging** | La couche de nettoyage et de typage, juste après les données brutes. |
| **Mart** | La couche finale, modélisée pour l'analyse et la BI. |
| **Schéma en étoile** | Une table de faits au centre, des dimensions descriptives autour. |
| **Table de faits** | Contient les mesures numériques et les clés vers les dimensions. |
| **Dimension** | Contient les attributs qui décrivent (quelle config, quelle question…). |
| **Grain** | Ce que représente **une ligne** d'une table de faits. La règle d'or. |
| **Clé de substitution** | Identifiant technique fabriqué (hachage), sans sens métier, pour joindre les tables. |
| **Matérialisation** | Un modèle existe en **vue** (recalculée) ou en **table** (stockée). |
| **Test générique / singulier** | Test réutilisable sur une colonne / test SQL spécifique à une règle métier. |
| **Intégrité référentielle** | Toute clé de la table de faits existe bien dans sa dimension. |
| **Lignage / DAG** | La carte des dépendances entre modèles ; dbt la déduit et la dessine. |
| **Idempotence** | Rejouer le pipeline dix fois donne le même résultat qu'une fois. |
| **CI/CD** | Un robot rejoue le pipeline et les tests à chaque modification du code. |
| **Non-régression** | Vérifier qu'une modification n'a rien cassé de ce qui marchait. |
| **Docker** | Empaqueter le pipeline avec son environnement pour qu'il tourne partout à l'identique. |
| **IaC / Terraform** | Décrire l'infrastructure cloud dans des fichiers versionnés, plutôt qu'en cliquant. |

---

*Ce document accompagne le dépôt `rag-dataops` (Projet 3). Pour les commandes exactes, voir le
`README.md` du dépôt. Pour comprendre l'origine des données traitées ici, voir le guide du
Projet 1. Pour comprendre comment les trois projets s'articulent, voir le document sur la
synergie.*
