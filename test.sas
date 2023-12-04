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
/* Calcul de l'age des societaires  et des tranches d'age*/
data societaire_age;
	set societaire;
	age = year(today()) - year(societaire_naissance_dt);
	
	if age >= 18 and age < 30 then tranche_age = '18-29';
    else if age >= 30 and age < 40 then tranche_age = '30-39';
    else if age >= 40 and age < 50 then tranche_age = '40-49';
    else if age >= 50 and age < 60 then tranche_age = '50-59';
    else if age >= 60 and age < 70 then tranche_age = '60-69';
    else if age >= 70 and age < 200 then tranche_age = '70 +';
run;

/*Stats sur l'age*/
proc univariate data= societaire_age;
	var age;
run;

/* Répartition des ages par tranches */
proc freq data=societaire_age;
	tables tranche_age / norow nocol ;
run;
	
/* Répartition des sexes */
proc freq data=societaire;
	tables societaire_sexe_cd;
run; 

/* Pyramide des ages */
proc freq data=societaire_age;
	tables age * societaire_sexe_cd / norow nocol nopercent;
	output out=test;
run;




/* Repartition geographique */
data societaire_dep;
    set societaire;
    
    departement = substr(code_postal_cd, 1,2); /* substr(variable, position_de_debut, longueur) */
   	
	if code_postal_cd >= '20000' and code_postal_cd < '20200' then departement = '2A';
    else if code_postal_cd >= '20200' and code_postal_cd < '20300' then departement = '2B';
    
    else if code_postal_cd =: '97' or code_postal_cd =: '98' then do; /* DOM-TOM */
        departement = substr(code_postal_cd, 1, 3); /* Les trois premiers chiffres pour les DOM-TOM */
    end;
    
run;
 
proc freq data=societaire_dep;
    tables departement;
run;

/* Repartition des CSP */
proc freq data = societaire;
	tables societaire_csp_cd;
run;

 

/* Anciennete des societaires*/
data societaire_anc;
  set societaire;
  anciennete = year(today()) - year(societaire_anciennete_dt);
  
  if anciennete >= 0 and anciennete < 5 then tranche_anc = '00-05';
  else if anciennete >= 5 and anciennete < 10 then tranche_anc = '05-09';
  else if anciennete >= 10 and anciennete < 15 then tranche_anc = '10-14';
  else if anciennete >= 15 and anciennete < 20 then tranche_anc = '15-19';
  else if anciennete >= 25 and anciennete < 30 then tranche_anc = '25-29';
  else if anciennete >= 30 and anciennete < 300 then tranche_anc = '30 ou +';
run;

proc freq data=societaire_anc;
	tables tranche_anc;
run;

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

/* Date de mise en circulation */
data mise_cirulation;
	set vehicule;
	
	circulation = year(today()) - year(mise_circulation_dt);
	if 		circulation >= 0  and circulation < 10  then tranche_circ = '[00-10[';
  	else if circulation >= 10 and circulation < 20 then tranche_circ = '[10-20[';
  	else if circulation >= 20 and circulation < 30 then tranche_circ = '[20-30[';
  	else if circulation >= 30 and circulation < 300 then tranche_circ = '[30 +';
run;

proc univariate data=mise_cirulation;
	var circulation;
run;
proc freq data=mise_cirulation;
	tables tranche_circ;
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
/* Repartition des catégories produits */
proc freq data=contrat;
    tables categorie_produit_cd;
run;

/* Repartition des formules */
proc freq data=contrat;
    tables formule_courte_cd;
run;

/* Repartition des fractionnement */
proc freq data=contrat;
    tables prime_annuelle_ht_mt;
run;

/* Part des fractionnements par prime */
proc freq data=contrat;
    tables prime_annuelle_ht_mt*fractionnement_cd / out=prime_frac OUTPCT nofreq nocol;
run;

/* Canaux de souscription */
proc freq data=contrat;
  tables canal_souscription_cd ;
run;
 
/* Canaux de distribution */
proc freq data=contrat;
  tables contrat_distrib_lb;
run;
 
/* Statistiques sur la prime annuelle */
proc univariate data=contrat;
  var prime_annuelle_ht_mt;
run;

/*Chiffre d'affaire*/
proc means data=contrat sum;
    var prime_annuelle_ht_mt;
run;
 
/* Repartition des PRO PART */
proc freq data=contrat;
  tables gamme_produit_cd;
run;

/* Produits vendus aux PRO PART */
proc freq data=contrat;
  tables gamme_produit_cd *  produit_cd;
run;

 
/* Durée moyenne de souscription */
data contrat_date_souscription;
    set contrat;
    /*Calcul de la durée en jours depuis la souscription jusqu'à aujourd'hui*/
    /*duree_souscription = year(today()) - year(saisie_contrat_dt);*/
    duree_souscription = intck('month', saisie_contrat_dt, today());
    
    if duree_souscription >= 0 and duree_souscription < 5 then tranche_sous = '[00-05[';
    else if duree_souscription >= 5 and duree_souscription < 10 then tranche_sous = '[05-10[';
    else if duree_souscription >= 10 and duree_souscription < 15 then tranche_sous = '[10-15[';
    else if duree_souscription >= 15 and duree_souscription < 20 then tranche_sous = '[15-20[';
    else if duree_souscription >= 20 and duree_souscription < 25 then tranche_sous = '[20-25[';
    else if duree_souscription >= 25 and duree_souscription < 30 then tranche_sous = '[25-30[';
   	else if duree_souscription >= 30 and duree_souscription < 35 then tranche_sous = '[30-35[';
    else if duree_souscription >= 35 and duree_souscription < 40 then tranche_sous = '[35-40[';
run;

proc freq data=contrat_date_souscription;
	tables tranche_sous;
run;

proc univariate data=contrat_date_souscription;
    var duree_souscription;
run;


/*----------------------------------
		TABLE FUSIONNEE
----------------------------------*/

proc freq data=contrat_vehicule_societaire;
  tables marque_vehicule_lb*contrat_distrib_lb / out=test OUTPCT noprint;
run;

data filtered_data;
  set test; /* Remplacer 'test_sorted' par votre dataset */
  if contrat_distrib_lb = "Partenariat"; /* Condition de filtrage */
run;

proc sort data=filtered_data out=test_freq_values;
  by descending PCT_COL;
run;


/* Nombre de contrat Moyen par societaires */
proc freq data=contrat_vehicule_societaire noprint;
   tables societaire_nu / out=nb_contrats (drop=percent);
run;

proc means data=nb_contrats mean maxdec=2;
   var count;
run;

proc univariate data=nb_contrats;
   var count;
run;



/* Relation sexe gamme produit */
proc freq data=contrat_vehicule_societaire;
	tables societaire_sexe_cd*gamme_produit_cd /  nocol nopercent nofreq;
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
    
    age = year(today()) - year(societaire_naissance_dt);
	
    if age < 30 then tranche_age = '01-29';
    else if age < 40 then tranche_age = '30-39';
    else if age < 50 then tranche_age = '40-49';
    else if age < 60 then tranche_age = '50-59';
    else if age < 70 then tranche_age = '60-69';
    else tranche_age = '70 +';
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

/* Durée moyenne de souscription par tranche d'age*/
proc means data=souscription_dep mean;
	class tranche_age;
    var duree_souscription;
    output out=sous_moy_age;
run;

proc means data=souscription_dep mean;
	class tranche_age;
    var duree_souscription;
    output out=sous_moy_age;
run;
/*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

		AUGMENTER LES PARTS DE MARCHE

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*/

/* Nombre de contrat par ans et par mois*/
data tendances;
    set contrat_vehicule_societaire;


    annee_souscription = year(saisie_contrat_dt);
    mois_souscription = month(saisie_contrat_dt);
run;

/* Nombre de contrat par ans*/
proc freq data=tendances; 
	tables annee_souscription;
run;

/* Nombre de contrat par mois*/
proc freq data=tendances; 
	tables mois_souscription;
run;

/* CA par ans*/
proc means data=tendances sum; 
	class annee_souscription;
	var prime_annuelle_ht_mt;
run;

/* CA par mois*/
proc means data=tendances; 
	class mois_souscription;
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
proc means data=formule_dep mean ;
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



data age;
	set formule_dep;
	age = year(today()) - year(societaire_naissance_dt);
	
    if age < 30 then tranche_age = '01-29';
    else if age < 40 then tranche_age = '30-59';
    else tranche_age = '60 +';

run;

data age;
	set formule_dep;
	age = year(today()) - year(societaire_naissance_dt);
	
	if age < 30 then tranche_age = '00-29';

run;

proc means data=age mean ;
    class departement tranche_age;
    var prime_annuelle_ht_mt;
    output out=ca_dep_age;
run;


/*age moyen par departement*/
proc means data=age mean ;
    class departement;
    var age;
    output out=dep_age;
run;

/*age moyen par canal*/
data age_canal; 
	set age; 
	if canal_souscription_cd = "BU" then canal = "Bureau"; 
	else if canal_souscription_cd = "CP" 
		or canal_souscription_cd = "CR" 
		or canal_souscription_cd = "CT" 
		or canal_souscription_cd = "IN" 
		or canal_souscription_cd = "WW" then canal = "Internet"; 
	else if canal_souscription_cd = "OUT" or canal_souscription_cd = "SA" then canal = "Salon"; 
	else if canal_souscription_cd = "TE" then canal = "Téléphone"; 
run; 
 
proc means data=age_canal mean ; 
    class canal; 
    var age; 
    output out=dep_age; 
run;

/*age moyen par formule*/
proc means data=age mean ;
    class formule_courte_cd ;
    var age;
    output out=form_age;
run;

/*prime moyenne par tranche d'age*/
proc means data=age mean;
	class tranche_age;
	var prime_annuelle_ht_mt;
	output out=prime_tranche_age;
run;
