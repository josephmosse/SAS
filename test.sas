libname biblio "/home/u63112220/M2";
options locale=FR;
options DATASTMTCHK=NONE;

PROC IMPORT OUT= BIBLIO.contrat 
            DATAFILE= "/home/u63112220/M2/BDD_CONTRAT.txt" 
            DBMS=TAB REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;
 
PROC IMPORT OUT= BIBLIO.SOC 
            DATAFILE= "/home/u63112220/M2/BDD_SOC.txt" 
            DBMS=TAB REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;
 
 
PROC IMPORT OUT= BIBLIO.VEHICULE 
            DATAFILE= "/home/u63112220/M2/BDD_VEHICULE.txt" 
            DBMS=TAB REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;

/*----------------------------------
		NETTOYAGE ET FUSION
----------------------------------*/
data vehicule;
	set biblio.vehicule;
	if contrat_id = 1 then delete;
Run;
 
data societaire;
	set biblio.soc;
	if societaire_nu = 1 then delete;
Run;
data contrat;
	set biblio.contrat;
Run;
 
/* Tri des tables contrat et vehicule par contrat_id*/
proc sort data=contrat;
	by contrat_id;
run;
proc sort data=vehicule nodupkey;
	by contrat_id;
run;
 
/* Fusion des tables contrat et vehicule*/
data contrat_vehicule;
 	merge contrat (in=a) vehicule (in=b);
	by contrat_id; 
	if a and b;
run;
 
/* Tri des tables contrat_vehicule et societaire par societaire_nu */
proc sort data=contrat_vehicule;
	by societaire_nu;
run;
proc sort data=societaire;
	by societaire_nu;
run;
/* Fusion des tables contrat_vehicule et societaire*/
data contrat_vehicule_societaire;
	merge contrat_vehicule (in=a) societaire (in=b);
	by societaire_nu;
	if a;
run;

/*----------------------------------
		TABLE SOCIETAIRES
----------------------------------*/
/*Stats sur l'age des societaires*/
/* Calcul de l'age des societaires */
data societaire_age;
	set societaire;
	age = year(today()) - year(societaire_naissance_dt);
run;

proc freq data=societaire_age;
	tables age;
run;
	
/* Répartition des sexes */
proc format;
	value $sexeFmt
		'01'='Femme'
		'02'='Homme';
run;

proc freq data=societaire;
	tables societaire_sexe_cd;
	format societaire_sexe_cd $sexeFmt.;
run; 

/* Repartition geographique */

data societaire_dep;
    set societaire;
    departement = substr(code_postal_cd, 1, 2); /* substr(variable, position_de_debut, longueur) */
run;
 
proc freq data=societaire_dep;
    tables departement;
run;


/* Repartition des CSP */
data societaire_csp;
	set contrat_vehicule_societaire;
 
	/* Sup les obs sans csp */
	if length(trim(societaire_csp_cd)) < 3 then do ; societaire_csp_cd = "000"; 
											end;
 
	/* Variable qui recupere le second caractere de societaire_csp_cd et le transforme en valeur numerique*/
	csp = int(substr(societaire_csp_cd,2,2));
run;
 
proc format;
	value cspFmt
		11 = "Agriculteurs exploitants"
		12 = "Artisans commer�ants"
		13 = "Chef d'entreprises de plus de 10 salari�s"
		14 = "Professions lib�rales et artistiques"
		20 = "Cadres"
		30 = "Professions interm�diaires"
		40 = "Employ�s"
		50 = "Ouvriers"
		61 = "Retrait�s"
		62 = "Etudiants"
		63 = "En recherche d'emploi"
		64 = "Sans activit� professionnelle"
		70 = "Personnes morales"
		80 = "Non connu"
		0  = "Pas de csp";
run;
 
proc freq data = societaire_csp;
	tables csp;
	format csp cspFmt.;
run; 

/* Anciennete des societaires*/
DATA societaire_anc;
  SET societaire;
  anciennete = YEAR(TODAY()) - YEAR(societaire_anciennete_dt);
RUN;
 
PROC UNIVARIATE DATA=societaire_anc;
  VAR anciennete;
RUN;

/*----------------------------------
		TABLE VEHICULE
----------------------------------*/
/*Type de vehicule*/
proc freq data=vehicule;
  tables vocation_cd;
run;

/* Marques les plus assurées */
proc freq data=vehicule noprint;
  tables marque_vehicule_lb / out=freq_values (keep=marque_vehicule_lb count) noprint;
run;
 
proc sort data=freq_values out=sorted_freq_values;
  by descending count;
run;
 
proc print data=sorted_freq_values(obs=10);
run;
 
/* Repartition des cylindrees */

proc freq data=vehicule;
  tables cylindree_nu;
run;
 
/* expliquer les -1 electrique*/
proc freq data=vehicule;
	tables cylindree_nu * energie_cd;
run;


/*----------------------------------
		TABLE CONTRAT
----------------------------------*/
/* Repartition des produits */
proc freq data=contrat;
    tables produit_cd;
run;

/* Repartition des formules */
proc freq data=contrat;
    tables formule_courte_cd;
run;

/* Cannaux de souscription */
proc freq data=contrat;
  tables canal_souscription_cd ;
run;
 
/* Prime annuelle moyenne */
proc means data=contrat mean;
  var prime_annuelle_ht_mt;
run;
 
/* Repartition des PRO PART */
proc freq data=contrat;
  tables gamme_produit_cd ;
run;

/* Durée moyenne de souscription */
data contrat_date_souscription;
    set contrat;
    /*Calcul de la durée en jours depuis la souscription jusqu'à aujourd'hui*/
    /*duree_souscription = year(today()) - year(saisie_contrat_dt);*/
    duree_souscription = intck('month', saisie_contrat_dt, today());
run;

proc means data=contrat_date_souscription mean;
    var duree_souscription;
run;


/*----------------------------------
		TABLE FUSIONNEE
----------------------------------*/

/* Nombre de contrat Moyen par societaires */
proc freq data=contrat_vehicule_societaire noprint;
   tables societaire_nu / out=nb_contrats (drop=percent);
run;

proc means data=nb_contrats mean maxdec=2;
   var count;
run;


/* Relation sexe gamme produit */
proc freq data=contrat_vehicule_societaire;
	tables societaire_sexe_cd*gamme_produit_cd;
run;

/* Tableau croisé formule par département */
data formule_dep;
    set contrat_vehicule_societaire;
    departement = substr(code_postal_cd, 1, 2); /* substr(variable, position_de_debut, longueur) */
run;

proc freq data=formule_dep;
    tables formule_courte_cd*departement;
run;

/*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

		DIMINUER LE TAUX DE RESILIATION

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*/

/* Durée moyenne de souscription par départements*/
data souscription_dep;
    set formule_dep;
    /*Calcul de la durée en jours depuis la souscription jusqu'à aujourd'hui*/
    duree_souscription = intck('day', saisie_contrat_dt, today())/365.25;
run;

proc means data=souscription_dep mean;
	class departement;
    var duree_souscription;
    output out=sous_moy_dep;
run;

/* Durée moyenne de souscription par formule*/
proc means data=souscription_dep mean;
	class formule_courte_cd;
    var duree_souscription;
    output out=sous_moy_form;
run;


/*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

		AUGMENTER LES PARTS DE MARCHE

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*/

/*Chiffre d'affaire*/
proc means data=contrat sum;
    var prime_annuelle_ht_mt;
run;


/* Chiffre d'affaire par formule et fractionnement*/
proc means data=contrat_vehicule_societaire sum ;
    class formule_courte_cd fractionnement_cd;
    var prime_annuelle_ht_mt;
    output out=ca_formule;
run;

/* Chiffre d'affaire par formule*/
proc means data=contrat_vehicule_societaire sum ;
    class formule_courte_cd;
    var prime_annuelle_ht_mt;
    output out=ca_par_formule;
run;

/* Chiffre d'affaire par departements*/
proc means data=formule_dep sum ;
    class departement;
    var prime_annuelle_ht_mt;
    output out=ca_dep ;
run;

/* Chiffre d'affaire par type de vehicule*/
proc means data=contrat_vehicule_societaire mean ;
    class categorie_produit_cd;
    var prime_annuelle_ht_mt;
    output out=ca_dep;
run;

/* Chiffre d'affaire par cannaux de souscription*/
proc means data=contrat_vehicule_societaire sum ;
    class canal_souscription_cd;
    var prime_annuelle_ht_mt;
    output out=ca_dep;
run;

/* Chiffre d'affaire par departement et formule*/
proc means data=formule_dep sum ;
    class departement formule_courte_cd;
    var prime_annuelle_ht_mt;
    output out=ca_dep_formule;
run;


/* Chiffre d'affaire par departement et sexe*/
proc means data=formule_dep sum ;
    class departement societaire_sexe_cd;
    var prime_annuelle_ht_mt;
    output out=ca_dep_formule;
run;


/* Chiffre d'affaire par departement et age*/
data age;
	set formule_dep;
	age = year(today()) - year(societaire_naissance_dt);
	
	if age < 18 then tranche_age = '00-18';
    else if age < 30 then tranche_age = '18-29';
    else if age < 40 then tranche_age = '30-39';
    else if age < 50 then tranche_age = '40-49';
    else if age < 60 then tranche_age = '50-59';
    else if age < 70 then tranche_age = '60-69';
    else tranche_age = '70 +';

run;

proc means data=age sum ;
    class departement tranche_age;
    var prime_annuelle_ht_mt;
    output out=ca_dep_age;
run;

