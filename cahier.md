# CAHIER DES CHARGES
## Application de gestion des points de vente — Transferts d’argent (UV) & crédit téléphonique
### CreditTrak — version cible (successeur de CreditTrack)

*Registre numérique pour agents et commerçants : stocks UV, crédit, commissions, journal, caisse et pilotage*

| Élément | Détail |
|---|---|
| Produit | CreditTrak |
| Référence existant | Projet CreditTrack (Flutter + Supabase) |
| Secteur | Mobile money, crédit téléphonique, points de vente / kiosques |
| Nature du document | Cahier des charges fonctionnel et technique |
| Version | 2.0 — Mise à jour |
| Date | Août 2026 |
| Statut | Document de travail |
| Périmètre volontairement exclu | Interface utilisateur (écrans, navigation, charte graphique) |

---

## Sommaire

1. [Contexte et présentation du projet](#1-contexte-et-présentation-du-projet)
   - 1.1 Présentation de l’activité
   - 1.2 Constat de l’existant (CreditTrack)
   - 1.3 Objectifs de la version cible
2. [Périmètre du projet](#2-périmètre-du-projet)
   - 2.1 Ce qui est couvert
   - 2.2 Ce qui est hors périmètre
   - 2.3 Organisation métier
   - 2.4 Utilisateurs cibles et rôles
3. [Spécifications fonctionnelles détaillées](#3-spécifications-fonctionnelles-détaillées)
   - 3.1 Authentification et comptes
   - 3.2 Établissement (commerce)
   - 3.3 Catalogue d’opérations
   - 3.4 Portefeuilles et stocks
   - 3.5 Enregistrement des opérations
   - 3.6 Clients
   - 3.7 Commissions et bénéfices
   - 3.8 Journal, historique et recherche
   - 3.9 Reçus, impression et exports
   - 3.10 Rapports et clôture
   - 3.11 Paramétrage métier
   - 3.12 Caisse physique
   - 3.13 Alertes et contrôles
4. [Règles métier](#4-règles-métier)
5. [Sécurité, rôles et gouvernance des données](#5-sécurité-rôles-et-gouvernance-des-données)
6. [Exigences techniques](#6-exigences-techniques)
7. [Modèle de données cible](#7-modèle-de-données-cible)
8. [Livrables attendus](#8-livrables-attendus)
9. [Phasage du projet](#9-phasage-du-projet)
10. [Critères de réception](#10-critères-de-réception)
11. [Annexes](#11-annexes)

---

## 1. Contexte et présentation du projet

### 1.1 Présentation de l’activité

CreditTrak s’adresse aux **agents et commerçants** qui tiennent un point de vente de services financiers de proximité, principalement en Afrique de l’Ouest (devise de référence : **FCFA**).

L’activité repose sur deux stocks distincts :

| Stock | Nom métier | Rôle |
|---|---|---|
| UV | Unités de valeur / float mobile money | Solde opérateur utilisé pour dépôts, retraits, Nafama, transferts UV / C2C |
| CRÉDIT | Crédit téléphonique | Stock de crédit / forfaits / Sewa / transferts de crédit |

Le commerçant travaille avec **un ou plusieurs numéros d’opération** (SIM / comptes agent). Chaque numéro a ses propres soldes et ses propres bénéfices cumulés. Le client du kiosque est identifié par un nom et un numéro de téléphone. Chaque opération génère une **commission** (ou non, selon le type), un **numéro de journal**, et éventuellement un **reçu**.

> **À retenir**
> L’application n’est pas un portefeuille grand public. C’est un **registre de caisse et de stocks** pour le commerçant : elle doit garantir que les soldes, commissions et historiques restent exacts, même avec plusieurs numéros, plusieurs employés et un volume élevé d’opérations.

### 1.2 Constat de l’existant (CreditTrack)

L’application actuelle (CreditTrack) couvre déjà le cœur métier. Elle sert de base. Les limites ci-dessous justifient une **mise à jour du cahier des charges**, pas un abandon du produit.

| Constat observé dans CreditTrack | Conséquence |
|---|---|
| Un seul compte utilisateur = un commerce entier | Impossible d’avoir un caissier distinct du patron, ni de tracer qui a saisi quoi |
| Types d’opérations figés dans le code et dans un ENUM SQL | Ajouter Wave, Moov, Free, un nouveau produit ou un palier de commission exige une modification applicative |
| Soldes dupliqués (`profiles`, `wallets`, `operation_phone_wallets`) | Risque d’écart entre totaux affichés et réalité par numéro |
| Table `clients` prévue mais peu utilisée (nom/téléphone recopiés sur chaque transaction) | Pas de fiche client, pas d’historique consolidé, doublons de numéros |
| Statuts `pending / success / failed / cancelled` existent mais presque tout est enregistré en `success` immédiat | Pas de file d’attente, pas d’échec métier, pas d’annulation propre |
| Modification et suppression d’une transaction **recalculent** les soldes | Utile en correction, dangereux sans journal d’audit immuable ni motif obligatoire |
| Taux de commission parfois calculés côté serveur avec des constantes, parfois lus dans `business_settings` | Écart possible entre l’estimation affichée et le montant réellement enregistré |
| Rapports calculés uniquement côté client, à partir d’un flux de transactions | Indicateurs peu fiables (périodes incomplètes, agrégats approximatifs) |
| Pas de caisse espèces (cash) | Le commerçant sait son stock UV/crédit, pas l’argent liquide réellement en tiroir |
| Pas de clôture journalière | Impossible de comparer « ce que le système dit » et « ce qu’il y a en caisse » en fin de journée |
| Pas de mode hors-ligne | Coupure réseau = arrêt de l’activité ou saisie sur papier puis ressaisie |
| Secrets d’API dans le code source | Risque de fuite ; mauvaise pratique pour une version production |
| Plafond de 6 numéros d’opération, opérateurs non modélisés | Un kiosque multi-réseaux n’est pas représenté correctement |
| Impression Bluetooth / PDF de reçu et export historique existent | À conserver, mais à rattacher à un journal et à un format de reçu stable |

### 1.3 Objectifs de la version cible

1. **Fiabiliser** les soldes UV, crédit, bénéfices et caisse : une seule source de vérité, calculs exclusivement côté serveur, refus des soldes négatifs.
2. **Paramétrer** le métier : types d’opérations, opérateurs, taux et paliers de commission sans modifier le code.
3. **Tracer** chaque action (création, correction, annulation, clôture, export) avec auteur, horodatage et motif.
4. **Séparer les rôles** : propriétaire, caissier, éventuellement superviseur — un commerce, plusieurs utilisateurs.
5. **Centraliser le client** : fiche unique par numéro, historique, suggestions, statistiques.
6. **Piloter** l’activité par des rapports serveur (jour, semaine, mois, numéro, type, opérateur) et une **clôture journalière**.
7. **Résister au terrain** : file d’opérations hors-ligne, reprise à la reconnexion, pas de double enregistrement.
8. **Sécuriser** l’accès, les données et les secrets (aucune clé dans le dépôt).

---

## 2. Périmètre du projet

### 2.1 Ce qui est couvert

- Gestion d’un ou plusieurs commerces (établissements).
- Gestion des utilisateurs rattachés à un établissement.
- Portefeuilles par **numéro d’opération** et par **catégorie de stock** (UV, CRÉDIT) + **caisse espèces**.
- Catalogue d’opérations paramétrable (dépôt, retrait, Nafama, transferts, achat crédit, forfait, Sewa, etc.).
- Enregistrement, correction contrôlée et annulation des opérations.
- Clients du kiosque.
- Commissions, bénéfices, alertes de solde.
- Journal séquentiel, reçus, exports PDF/CSV.
- Rapports et clôture de journée.
- Impression thermique et partage de documents.
- Audit, sauvegarde, isolation des données par établissement.

### 2.2 Ce qui est hors périmètre

| Exclu | Précision |
|---|---|
| Interface utilisateur | Aucun écran, flux de navigation, composant visuel ou charte graphique n’est spécifié ici |
| Connexion directe aux API opérateurs (Orange, Wave, etc.) | L’app enregistre ce que l’agent a fait ; elle ne déclenche pas le transfert chez l’opérateur en v1 cible |
| Comptabilité légale complète (plan comptable, TVA, liasse) | Exports et journaux suffisent ; pas un logiciel d’expert-comptable |
| Crédit / scoring / prêt aux clients | Hors métier kiosque de base |
| Marketplace, réseau social, chat client | Hors sujet |

### 2.3 Organisation métier

Le modèle cible a **trois niveaux** :

| Niveau | Description |
|---|---|
| Établissement | Le commerce (nom, devise, fuseau, pays) |
| Point d’opération | Un numéro / SIM / compte agent, rattaché à un opérateur (Orange, Wave, …) et à des stocks |
| Utilisateur | Personne qui se connecte et saisit (propriétaire ou caissier) |

Toute opération est rattachée à : un établissement, un utilisateur, un numéro d’opération, un type, un client (sauf opérations internes).

> **Règle de cloisonnement**
> Un utilisateur ne voit que les données de son établissement. Un caissier ne voit que ce que son rôle autorise. Aucun filtre d’affichage ne remplace l’isolation en base (RLS / politiques serveur).

### 2.4 Utilisateurs cibles et rôles

| Rôle | Périmètre | Droits principaux |
|---|---|---|
| Propriétaire (admin établissement) | Tout l’établissement | Utilisateurs, taux, opérateurs, numéros, clôture, exports, corrections, audit, reset métier |
| Superviseur (optionnel) | Établissement | Rapports, historique, clôture, pas de paramétrage des taux ni de suppression |
| Caissier | Ses sessions / éventuellement tous les numéros autorisés | Saisir des opérations, imprimer un reçu, consulter l’historique du jour |
| Système | — | Triggers, calculs de soldes, numérotation journal, jobs de sync hors-ligne |

---

## 3. Spécifications fonctionnelles détaillées

Cette section décrit le **comportement métier**. Elle ne prescrit aucun écran.

### 3.1 Authentification et comptes

- Inscription d’un propriétaire : e-mail, mot de passe, nom du commerce, nom du responsable.
- Connexion / déconnexion, session persistante, expiration de session.
- Invitation d’un caissier par le propriétaire (e-mail ou identifiant local), rattachement à l’établissement.
- Mot de passe oublié (flux e-mail).
- Révocation d’un utilisateur (désactivation, pas forcément suppression physique).
- Chaque action métier est signée par `user_id` (auteur), distinct de `establishment_id`.

**Amélioration par rapport à l’existant** : aujourd’hui un compte = tout le commerce. La cible sépare **identité** et **établissement**.

### 3.2 Établissement (commerce)

Fiche établissement :

- Nom commercial, nom du responsable, téléphone du commerce.
- Devise (`XOF` / libellé CFA), locale, fuseau (`Africa/Dakar` par défaut).
- Pays / opérateur principal (informatif).
- Liste des **numéros d’opération** (plus de plafond figé à 6 ; une limite paramétrable, ex. 20).
- Pour chaque numéro : libellé, opérateur, actif/inactif, soldes UV / crédit, bénéfices UV / crédit.

Ajustement manuel des soldes UV / crédit d’un numéro :

- Autorisé au propriétaire uniquement.
- N’altère **pas** les bénéfices cumulés.
- Écrit une ligne d’audit (`balance_adjusted`) avec ancien/nouveau solde et motif obligatoire.
- Interdit les valeurs négatives.

### 3.3 Catalogue d’opérations

Les types ne sont plus un ENUM applicatif figé. Ils sont des **enregistrements paramétrables**.

Chaque type d’opération définit :

| Attribut | Exemple |
|---|---|
| Code stable | `depot`, `retrait`, `nafama`, … |
| Libellé | Dépôt, Retrait, Nafama |
| Catégorie de stock impacté | `UV` ou `CREDIT` ou `NONE` (interne) |
| Sens du stock | débit / crédit / aucun |
| Impact caisse espèces | entrée / sortie / aucun |
| Mode de commission | aucun, % du montant, palier, montant fixe |
| Exige un client | oui / non |
| Exige un numéro d’opération | oui (sauf exception documentée) |
| Autorise un solde résultant à 0 | oui |
| Actif | oui / non |

**Jeu initial à reprendre de CreditTrack** (valeurs par défaut à l’ouverture d’un établissement) :

| Code | Catégorie | Effet sur le stock | Commission par défaut |
|---|---|---|---|
| `depot` | UV | − montant | 0,14 % |
| `retrait` | UV | + montant | 0,28 % |
| `nafama` | UV | − montant | 4,55 % |
| `transfert_uv` | UV | + montant | 0 |
| `transfert_c2c` | UV | − montant | 0 |
| `transfert_profit_uv` | UV | + montant (prélevé sur bénéfice UV) | 0 |
| `achat` | CREDIT | + montant | 0 |
| `forfait` | CREDIT | − montant | 10 % |
| `sewa` | CREDIT | − montant | 10 % |
| `transfert_credit` | CREDIT | − montant | 10 % |

Le propriétaire peut **créer** un type (ex. `wave_depot`, `moov_retrait`) sans déploiement applicatif, tant que les attributs ci-dessus sont renseignés.

### 3.4 Portefeuilles et stocks

#### 3.4.1 Portefeuille par numéro d’opération

Une ligne par couple `(établissement, numéro)` :

- `solde_uv` ≥ 0
- `solde_credit` ≥ 0
- `profit_uv` ≥ 0
- `profit_credit` ≥ 0

Les totaux établissement = **somme** des lignes. Ils ne sont jamais saisis à part ; ils sont dérivés.

#### 3.4.2 Caisse espèces (nouveau)

Un stock `CASH` par établissement (et optionnellement par numéro / par caissier en phase 2) :

- Dépôt client → la caisse **augmente** du montant reçu.
- Retrait client → la caisse **diminue** du montant versé.
- Achat de crédit / recharge UV chez l’opérateur → la caisse **diminue**.
- Le système refuse une opération qui rendrait la caisse négative, sauf option propriétaire « autoriser découvert caisse » (désactivée par défaut).

#### 3.4.3 Transfert de bénéfice UV

Opération interne :

- Débite `profit_uv` du numéro.
- Crédite `solde_uv` du même numéro.
- Montant > 0 et ≤ `profit_uv` disponible.
- Pas de commission.
- Client facultatif (libellé système « Transfert interne »).

### 3.5 Enregistrement des opérations

#### 3.5.1 Données obligatoires

- Type d’opération (du catalogue).
- Numéro d’opération (merchant / SIM) — **obligatoire** pour tout type qui impacte un stock numéro.
- Montant > 0.
- Client : nom + téléphone, si le type l’exige.
- Auteur (utilisateur connecté).
- Horodatage serveur (pas l’horloge du téléphone comme source de vérité).

Données optionnelles : note, référence externe (ID opérateur), identifiant appareil.

#### 3.5.2 Traitement serveur (unique chemin)

Toute création passe par une **fonction / RPC serveur** unique, qui dans une transaction SQL :

1. Verrouille le portefeuille du numéro (`FOR UPDATE`).
2. Recalcule la commission à partir des **taux de l’établissement** (jamais des constantes du client).
3. Applique le delta de stock.
4. Refuse si solde UV, crédit, bénéfice ou caisse deviendrait négatif (`SOLDE_INSUFFISANT` ou message métier équivalent).
5. Attribue `journal_seq` (compteur atomique par établissement, éventuellement préfixe année).
6. Enregistre `balance_before` / `balance_after`.
7. Met à jour les totaux dérivés.
8. Écrit l’audit `transaction_created`.
9. Retourne l’opération complète.

Le client ne calcule **jamais** le solde final. Il peut afficher une **estimation** de commission, clairement marquée comme non contractuelle jusqu’à confirmation serveur.

#### 3.5.3 Statuts

| Statut | Usage |
|---|---|
| `pending` | Opération saisie hors-ligne ou en attente d’accusé |
| `success` | Soldes appliqués |
| `failed` | Rejetée (solde, validation, conflit) — n’a pas bougé les stocks |
| `cancelled` | Annulée après succès, via contre-passation |

#### 3.5.4 Correction

- Réservée au propriétaire (ou superviseur si activé).
- Motif obligatoire.
- Annule l’effet de l’ancienne ligne puis applique la nouvelle (même logique que l’existant `update_transaction`), **dans une seule transaction**.
- Conserve l’`id` et le `journal_seq` d’origine ; historise l’avant/après dans l’audit.
- Interdite sur une journée **clôturée**, sauf dé-clôture explicite.

#### 3.5.5 Annulation (remplace la suppression silencieuse)

- Pas de `DELETE` métier par défaut.
- Annulation = contre-passation : inverse les deltas de stock et de bénéfice, statut `cancelled`.
- Motif obligatoire.
- Le reçu d’origine reste consultable, marqué annulé.
- La suppression physique n’existe que via une procédure d’effacement global (voir 3.11), pas opération par opération.

**Amélioration** : l’existant permet `delete_transaction` qui efface la ligne. La cible conserve la traçabilité.

#### 3.5.6 Idempotence

Toute création accepte une `client_request_id` (UUID généré sur l’appareil). Un second envoi avec le même id **ne crée pas** une seconde opération (réseau instable, double tap, sync hors-ligne).

### 3.6 Clients

- Fiche unique par `(établissement, téléphone normalisé)`.
- Nom, téléphone, date de dernière opération, compteur d’opérations, volume cumulé.
- À chaque opération « avec client », upsert automatique de la fiche.
- Historique des opérations du client.
- Suggestion des numéros récemment utilisés (comme aujourd’hui), **en excluant** les opérations internes (`transfert_profit_uv`).
- Normalisation des numéros (espaces, préfixe pays) pour limiter les doublons.

### 3.7 Commissions et bénéfices

- Taux stockés par établissement (JSON ou table `commission_rules`).
- Support **pourcentage**, **montant fixe** et **paliers** (ex. 0–10 000 : x %, au-delà : y %).
- Arrondi à 2 décimales, règle unique documentée (arrondi moitié supérieure, FCFA souvent entier : option « arrondir à l’unité »).
- `commission` et `net_profit` enregistrés sur l’opération (snapshot), même si les taux changent ensuite.
- Bénéfice UV / crédit du numéro = cumul des commissions de la catégorie, diminué des transferts de bénéfice.
- La commission **n’est jamais déduite du stock** UV ou crédit (comportement actuel à conserver).

### 3.8 Journal, historique et recherche

- Numéro de journal lisible, unique par établissement, croissant, sans trou en fonctionnement normal (les annulations conservent le numéro).
- Historique filtrable par : période, catégorie, type, numéro d’opération, statut, téléphone client, auteur, montant min/max.
- Pagination serveur (ne plus charger « tout le flux » pour les rapports).
- Temps réel possible pour le journal du jour ; les historiques longs passent par requête paginée.

### 3.9 Reçus, impression et exports

Reçu d’opération (données, pas mise en page) :

- Nom du commerce, n° journal, date/heure serveur, type, client, téléphone client, numéro d’opération, montant, commission, solde après (si le rôle l’autorise), note, mention annulé le cas échéant.

Canaux :

- PDF (format ticket thermique et format A4).
- Impression Bluetooth (imprimante déjà prévue dans l’existant).
- Partage fichier (Android / iOS / web).
- Option « impression automatique après succès ».
- En-tête / pied de reçu paramétrables (textes, pas design).

Exports :

- Historique filtré → PDF et CSV.
- Rapport de période → PDF et CSV.
- Chaque export est journalisé (`report_exports` : type, dates, auteur, URL ou hash).

### 3.10 Rapports et clôture

Indicateurs **calculés côté serveur**, pour une période et un filtre (numéro, opérateur, utilisateur) :

- Volume et nombre par type.
- Total commissions UV, commissions crédit, commission globale.
- Entrées / sorties de stock UV et crédit.
- Mouvements de caisse.
- Top clients (volume).
- Comparaison période N vs N-1 (vrai calcul, pas de pourcentage fictif).

**Clôture journalière** (nouveau) :

1. L’utilisateur déclenche la clôture pour une date et un établissement (et optionnellement un numéro).
2. Le système fige : totaux opérations, commissions, soldes de fin, caisse théorique.
3. Saisie de la **caisse réelle comptée** ; écart = réel − théorique.
4. Écart mémorisé, commenté, visible dans l’audit.
5. Après clôture : plus de création / correction sur cette date sans dé-clôture propriétaire.

### 3.11 Paramétrage métier

- Taux de commission par type / palier.
- Numéros d’opération, opérateurs, activation.
- Textes de reçu, langue par défaut (`fr`), auto-impression.
- Devise et arrondi.
- Option découvert caisse.
- **Effacement métier** : RPC scopée à l’utilisateur/établissement connecté. Conserve le profil, les numéros et les taux. Remet à zéro transactions, clients, portefeuilles, compteur journal, exports, logs optionnels. Confirmation forte (saisie d’une phrase, pas un simple tap).

Hors paramétrage métier de ce document : thème clair/sombre, disposition des menus.

### 3.12 Caisse physique

- Solde caisse dérivé des règles d’impact du catalogue + ajustements propriétaire.
- Ajustement de caisse (fond de caisse, erreur de rendu) = écriture d’audit + motif.
- Lien avec la clôture (3.10).

### 3.13 Alertes et contrôles

- Seuil de solde UV / crédit / caisse par numéro (paramétrable) → événement `low_balance`.
- Refus explicite : `SOLDE_INSUFFISANT`, `MERCHANT_PHONE_REQUIRED`, `BENEFICE_UV_INSUFFISANT`, `JOURNEE_CLOTUREE`, `DROIT_INSUFFISANT`.
- Messages métier stables (codes) pour que le client les traduise, sans parser le texte SQL brut.

---

## 4. Règles métier

Les deltas ci-dessous sont le **comportement de référence** du catalogue initial. Ils doivent rester identiques à CreditTrack sauf mention contraire.

### 4.1 Impact sur le stock UV

| Type | Δ solde UV | Δ profit UV |
|---|---|---|
| Dépôt | − montant | + commission |
| Retrait | + montant | + commission |
| Nafama | − montant | + commission |
| Transfert UV | + montant | 0 |
| Transfert C2C | − montant | 0 |
| Transfert profit UV | + montant | − montant |

### 4.2 Impact sur le stock crédit

| Type | Δ solde crédit | Δ profit crédit |
|---|---|---|
| Achat crédit | + montant | 0 |
| Forfait | − montant | + commission |
| Sewa | − montant | + commission |
| Transfert de crédit | − montant | + commission |

### 4.3 Impact caisse espèces (cible, nouveau)

Proposition par défaut, modifiable dans le catalogue :

| Type | Δ caisse |
|---|---|
| Dépôt | + montant |
| Retrait | − montant |
| Nafama | + montant (si le client paie en espèces) |
| Achat crédit | − montant (le commerçant paie le stock) |
| Forfait / Sewa / Transfert crédit | + montant (vente au client) |
| Transfert UV / C2C / profit UV | 0 (sauf paramétrage contraire) |

### 4.4 Invariants

1. Aucun solde UV, crédit, profit ou caisse (si découvert interdit) ne passe sous 0.
2. `montant > 0`.
3. Commission ≥ 0.
4. `net_profit` de l’opération = commission snapshot (sauf transfert profit UV : 0).
5. Toute opération success a un `journal_seq` non nul, unique dans l’établissement.
6. Les totaux établissement = somme des portefeuilles numéros.
7. Une journée clôturée est immuable sans dé-clôture.
8. Idempotence par `client_request_id`.

### 4.5 Taux par défaut (ouverture d’établissement)

| Type | Multiplicateur | Équivalent |
|---|---|---|
| Dépôt | 0,0014 | 0,14 % |
| Retrait | 0,0028 | 0,28 % |
| Nafama | 0,0455 | 4,55 % |
| Forfait | 0,10 | 10 % |
| Sewa | 0,10 | 10 % |
| Transfert de crédit | 0,10 | 10 % |
| Autres types initiaux | 0 | — |

---

## 5. Sécurité, rôles et gouvernance des données

La sécurité n’est pas un module optionnel : l’application manipule de l’argent et des stocks.

### 5.1 Exigences de sécurité

- Authentification individuelle (e-mail / mot de passe) ; 2FA recommandé en phase 2.
- Aucune clé API, URL de projet ou secret dans le dépôt git ; configuration par variables d’environnement.
- Isolation des données par établissement au niveau base (RLS), pas seulement dans l’app.
- Les fonctions de mise à jour des soldes sont `security definer` **avec** contrôle `auth.uid()` / appartenance à l’établissement.
- Journal d’audit append-only : création, correction, annulation, ajustement de solde, clôture, export, effacement métier, invitation utilisateur.
- Pas de politique `UPDATE/DELETE` publique sur `audit_logs`.
- Sauvegardes automatiques du backend ; export complet propriétaire à tout moment.
- Sessions révocables (déconnexion globale).
- Chiffrement en transit (HTTPS). Données au repos selon l’hébergeur.

### 5.2 Matrice des droits

| Capacité | Propriétaire | Superviseur | Caissier |
|---|---|---|---|
| Saisir une opération | Oui | Oui | Oui |
| Imprimer / exporter un reçu | Oui | Oui | Oui |
| Corriger une opération | Oui | Configurable | Non |
| Annuler une opération | Oui | Configurable | Non |
| Ajuster un solde / la caisse | Oui | Non | Non |
| Modifier les taux | Oui | Non | Non |
| Gérer les utilisateurs | Oui | Non | Non |
| Clôturer la journée | Oui | Oui | Non |
| Dé-clôturer | Oui | Non | Non |
| Effacer toutes les données métier | Oui | Non | Non |
| Lire l’audit | Oui | Oui | Non |
| Voir les bénéfices | Oui | Oui | Configurable |

### 5.3 Données personnelles

- Clients = données personnelles (téléphone, nom) : accès limité à l’établissement.
- Droit à l’effacement : procédure `clear_all_data` / suppression de compte propriétaire.
- Pas de partage inter-établissements.

---

## 6. Exigences techniques

### 6.1 Architecture générale

- Client mobile (et éventuellement web) consommant une **API / backend** (Supabase ou équivalent : Auth, Postgres, Realtime, Storage).
- Toute règle d’argent s’exécute **en base** (fonctions SQL ou service backend), jamais uniquement dans le client.
- Temps réel : journal du jour et soldes du numéro sélectionné.
- File hors-ligne : file locale chiffrée, sync FIFO, idempotence.
- Exports PDF/CSV générés sur l’appareil ou via une fonction backend pour les gros volumes.

### 6.2 Qualité et non-fonctionnel

| Exigence | Cible |
|---|---|
| Exactitude monétaire | `numeric(16,2)` (ou entier FCFA si option arrondi activée) |
| Concurrence | Un seul writer à la fois par portefeuille (verrou ligne) |
| Volume | Pagination ; un kiosque : milliers d’opérations / mois sans dégrader la saisie |
| Disponibilité | Backend managé ; mode dégradé = file hors-ligne |
| Observabilité | Journaux applicatifs + codes d’erreur métier stables |
| Tests | Jeux de tests des deltas (création, correction, annulation, transfert profit, solde insuffisant, double envoi) |

### 6.3 Reprise depuis CreditTrack

| Source actuelle | Traitement |
|---|---|
| `profiles`, numéros, soldes | Migration vers établissement + portefeuilles ; totaux recalculés par somme |
| `transactions` | Conservées ; backfill `client_id`, `establishment_id`, `author_id`, `client_request_id` |
| `business_settings.commission_rates` | Repris tels quels comme taux v1 |
| `journal_seq` | Conservé ; compteur aligné sur `max(journal_seq)` |
| `operation_phone_wallets` | Devient le modèle canonique (plus de soldes maîtres dans `profiles`) |
| ENUM `transaction_type` | Migré vers table `operation_types` ; codes identiques pour compatibilité |

---

## 7. Modèle de données cible

Vue logique (noms indicatifs). L’interface n’est pas concernée.

| Entité | Responsabilité |
|---|---|
| `establishments` | Commerce : nom, devise, fuseau, options |
| `memberships` | Lien user ↔ établissement + rôle |
| `profiles` / `users` | Identité de connexion (Auth) |
| `operators` | Orange, Wave, … (catalogue) |
| `operation_phones` | Numéros / SIM du commerce |
| `wallets` | Soldes UV, CREDIT, CASH, profits par numéro (ou par établissement pour CASH v1) |
| `operation_types` | Catalogue paramétrable |
| `commission_rules` | Taux / paliers par établissement et type |
| `clients` | Fiche unique par téléphone |
| `transactions` | Opérations + snapshots (montant, commission, soldes, journal_seq, statut, request_id) |
| `transaction_revisions` | Historique des corrections |
| `receipts` | Preuve d’édition / impression |
| `day_closings` | Clôture journalière + écart de caisse |
| `report_exports` | Métadonnées d’export |
| `audit_logs` | Événements immuables |
| `journal_counters` | Compteur atomique |

**Principe** : une seule écriture de solde, un seul endroit. `profiles.solde_uv` / `solde_credit` de l’existant deviennent des **vues** ou sont supprimés après migration.

---

## 8. Livrables attendus

- Backend (schéma, RLS, fonctions métier, migrations depuis CreditTrack).
- Client applicatif implémentant ces contrats (sans prescription d’UI dans ce document).
- Jeu de tests des règles d’argent (création, correction, annulation, hors-ligne, clôture).
- Script / procédure de migration des données existantes.
- Documentation technique : codes d’erreur, catalogue d’opérations, procédures d’effacement et de clôture.
- Documentation utilisateur métier (procédures : ouverture de journée, saisie, clôture) — indépendante de la maquette.

---

## 9. Phasage du projet

| Phase | Contenu | Objectif |
|---|---|---|
| Phase 1 — Cœur fiable | Un établissement, un utilisateur, catalogue initial, portefeuilles par numéro, RPC unique, idempotence, annulation, clients, journal, reçus/exports, taux paramétrables, secrets hors code | Remplacer CreditTrack sans régression métier |
| Phase 2 — Équipe et caisse | Rôles, invitations, caisse espèces, clôture journalière, alertes de solde, pagination / rapports serveur | Tenir un vrai kiosque à plusieurs personnes |
| Phase 3 — Terrain | Hors-ligne, multi-opérateurs, paliers de commission, types custom, écarts de clôture | Tenir sans réseau et sans nouveau déploiement pour un produit |
| Phase 4 — Pilotage | Rapports avancés, comparaison de périodes, exports comptables, 2FA, révisions d’opérations enrichies | Diriger plusieurs numéros / plusieurs caissiers |

---

## 10. Critères de réception

La recette se fait sur des **données et des règles**, pas sur l’apparence.

- **Exactitude** : pour un jeu d’opérations réel (dépôt, retrait, Nafama, achat, forfait, transfert profit), les soldes UV, crédit et bénéfices coincidents au centime près avec un calcul manuel.
- **Refus** : une opération qui ferait un solde négatif est rejetée ; aucune ligne `success` n’est créée.
- **Idempotence** : deux envois avec le même `client_request_id` = une seule opération.
- **Cohérence des totaux** : somme des portefeuilles numéros = totaux établissement, après chaque écriture.
- **Taux** : modifier un taux ne change pas les commissions déjà enregistrées ; les nouvelles opérations utilisent le nouveau taux.
- **Annulation** : restaure les soldes ; l’opération reste consultable en `cancelled`.
- **Cloisonnement** : un utilisateur d’un établissement A n’accède à aucune ligne de B.
- **Journal** : numéros séquentiels, uniques, présents sur le reçu.
- **Migration** : un dump CreditTrack v1 rejoué produit les mêmes soldes finaux que l’app actuelle.
- **Secrets** : le dépôt ne contient aucune clé d’environnement.

Hors recette de ce cahier : couleurs, animations, disposition des boutons, thème sombre.

---

## 11. Annexes

### 11.1 Lexique

| Terme | Signification |
|---|---|
| UV | Unité de valeur — float / stock mobile money de l’agent |
| Crédit | Stock de crédit téléphonique (unités, forfaits, Sewa) |
| Numéro d’opération | SIM ou compte agent utilisé pour exécuter le service chez l’opérateur |
| Nafama | Produit / opération UV spécifique (catalogue initial, commission élevée) |
| Sewa | Produit crédit du catalogue initial |
| C2C | Transfert client à client via l’agent |
| Transfert profit UV | Conversion du bénéfice UV cumulé en stock UV |
| Journal | Numérotation séquentielle des opérations d’un établissement |
| Clôture | Figement des totaux d’une date et comparaison à la caisse réelle |
| RPC | Procédure exécutée côté serveur (source de vérité des soldes) |

### 11.2 Codes d’erreur métier (contrat)

| Code | Signification |
|---|---|
| `SOLDE_INSUFFISANT` | L’opération rendrait un stock négatif |
| `MERCHANT_PHONE_REQUIRED` | Numéro d’opération manquant |
| `BENEFICE_UV_INSUFFISANT` | Transfert profit supérieur au bénéfice UV |
| `MONTANT_INVALIDE` | Montant ≤ 0 ou non numérique |
| `JOURNEE_CLOTUREE` | Écriture refusée sur une date clôturée |
| `DROIT_INSUFFISANT` | Rôle non autorisé |
| `DUPLICATE_REQUEST` | `client_request_id` déjà consommé (succès silencieux : renvoyer l’opération existante) |
| `TYPE_INACTIF` | Type d’opération désactivé |

### 11.3 Écarts volontaires avec CreditTrack v1

| Sujet | v1 | Cible |
|---|---|---|
| Soldes | 3 endroits possibles | 1 portefeuille canonique + totaux dérivés |
| Types | ENUM code + SQL | Table catalogue |
| Suppression | Effacement de ligne | Annulation / contre-passation |
| Rapports | Agrégats client, parfois indicatifs | Agrégats serveur |
| Utilisateurs | 1 compte = 1 commerce | Établissement + rôles |
| Caisse | Absente | Stock CASH + clôture |
| Hors-ligne | Absent | File + idempotence |
| Commission serveur | Parfois constantes | Toujours règles de l’établissement |

### 11.4 Note méthodologique

*Ce cahier des charges est une mise à jour rédigée à partir du code, du schéma SQL et des migrations du projet CreditTrack (auth, transactions, portefeuilles par numéro, commissions, journal, reçus, exports, impression). Il reprend l’organisation type d’un cahier des charges fonctionnel et technique (contexte, constat, périmètre, modules, sécurité, exigences techniques, livrables, phasage, recette, annexes). L’interface utilisateur est volontairement hors périmètre : ce document doit pouvoir servir à reconstruire une application **meilleure sur le métier**, quel que soit le futur client (mobile, web ou autre).*
