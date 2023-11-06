libname biblio "P:/SAS";

PROC IMPORT OUT= BIBLIO.contrat 
            DATAFILE= "P:\SAS\BDD_CONTRAT.txt" 
            DBMS=TAB REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;
 
PROC IMPORT OUT= BIBLIO.SOC 
            DATAFILE= "P:\SAS\BDD_SOC.txt" 
            DBMS=TAB REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;
 
 
PROC IMPORT OUT= BIBLIO.VEHICULE 
            DATAFILE= "P:\SAS\BDD_VEHICULE.txt" 
            DBMS=TAB REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;
 
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
 
/* On tri les tables contrat et vehicule par contrat_id*/
proc sort data=contrat;
	by contrat_id;
run;
proc sort data=vehicule nodupkey;
	by contrat_id;
run;
 
/* On fusionne les tables contrat et vehicule*/
data contrat_vehicule;
 	merge contrat (in=a) vehicule (in=b);
	by contrat_id; 
	if a and b;
run;
 
/* On tri les tables contrat_vehicule et societaire par societaire_nu */
proc sort data=contrat_vehicule;
	by societaire_nu;
run;
proc sort data=societaire;
	by societaire_nu;
run;
/* On fusionne les tables contrat_vehicule et societaire*/
data contrat_vehicule_societaire;
	merge contrat_vehicule (in=a) societaire (in=b);
	by societaire_nu;
	if a;
run;
/*Stats sur l'age des sociétaires*/ 
 

/* Calcul de l'age des societaires */
options DATASTMTCHK=NONE;
data societaire2;
	set societaire;
	age = year(today()) - year(societaire_naissance_dt);
run;

proc freq data=societaire2;
	tables age;
run;
	
 
/*Stat sur les CSP*/
data societaire_csp;
	set societaire;
 
	/* Sup les obs sans csp */
	if length(trim(societaire_csp_cd)) < 3 then do ; societaire_csp_cd = "000"; 
											end;
 
	/* Variable qui récupère le second caractère de societaire_csp_cd et le transforme en valeur numérique*/
	csp = int(substr(societaire_csp_cd,2,2));
run;
 
proc format;
	value cspFmt
		11 = "Agriculteurs exploitants"
		12 = "Artisans commerçants"
		13 = "Chef d'entreprises de plus de 10 salariés"
		14 = "Professions libérales et artistiques"
		20 = "Cadres"
		30 = "Professions intermédiaires"
		40 = "Employés"
		50 = "Ouvriers"
		61 = "Retraités"
		62 = "Etudiants"
		63 = "En recherche d'emploi"
		64 = "Sans activité professionnelle"
		70 = "Personnes morales"
		80 = "Non connu"
		0  = "Pas de csp";
run;
 
proc freq data = societaire_csp;
	tables csp;
	format csp cspFmt.;
run;

/* Statistiques sur les ages */
proc format;
	value $sexeFmt
		'01'='Femme'
		'02'='Homme';
RUN;

proc freq data=biblio.soc;
	tables societaire_sexe_cd;
	format societaire_sexe_cd $sexeFmt.;
run;

/* Distribution département sociétaires d'habitation  */
 
data societaire_dep;
    set societaire;
    departement = substr(code_postal_cd, 1, 2); /* substr(variable, position_de_début, longueur) */
run;
 
proc freq data=societaire_dep;
    tables departement;
run;
 
/* Ancienneté des sociétaires*/
DATA societaire_anc;
  SET societaire;
  anciennete = YEAR(TODAY()) - YEAR(societaire_anciennete_dt);
RUN;
 
PROC UNIVARIATE DATA=societaire_anc;
  VAR anciennete;
RUN;


/* Nombre de contrat Moyen par societaires */
proc freq data=contrat_vehicule_societaire noprint;
   tables societaire_nu / out=nb_contrats (drop=percent);
run;

proc means data=nb_contrats mean maxdec=2;
   var count;
   title "Nombre moyen de contrats par sociétaire";
run;

/* Relation sexe gamme produit */
proc freq data=contrat_vehicule_societaire;
	tables societaire_sexe_cd*gamme_produit_cd;
run;


proc freq data=vehicule;
  tables vocation_cd / out=tableau_frequence;
run;
 
proc print data=tableau_frequence;
run;


/* Étape 1 : Utiliser PROC FREQ pour générer les fréquences des valeurs de la variable marque_vehicule_lb */
proc freq data=vehicule noprint;
  tables marque_vehicule_lb / out=freq_values (keep=marque_vehicule_lb count) noprint;
run;
 
/* Étape 2 : Utiliser PROC SORT pour trier les fréquences par ordre décroissant */
proc sort data=freq_values out=sorted_freq_values;
  by descending count;
run;
 
/* Étape 3 : Utiliser PROC PRINT pour afficher les cinq valeurs les plus fréquentes */
proc print data=sorted_freq_values(obs=10);
  title 'Top 10 des fréquences les plus élevées pour la variable marque_vehicule_lb';
run;

 
/* Étape 1 : Utiliser PROC FREQ pour générer les fréquences des valeurs de la variable marque_vehicule_lb */
proc freq data=vehicule noprint;
  tables marque_vehicule_lb / out=freq_values (keep=marque_vehicule_lb count) noprint;
run;
 
/* Étape 2 : Filtrer les fréquences supérieures à 100 */
data freq_over_100;
  set freq_values;
  where count > 100;
run;
 
/* Étape 3 : Utiliser PROC SORT pour trier les fréquences supérieures à 100 dans l'ordre décroissant */
proc sort data=freq_over_100 out=sorted_freq_over_100;
  by descending count;
run;
 
/* Étape 4 : Utiliser PROC PRINT pour afficher les valeurs avec des fréquences supérieures à 100 dans l'ordre décroissant */
proc print data=sorted_freq_over_100;
  title 'Fréquences supérieures à 100 pour la variable marque_vehicule_lb (ordre décroissant)';
run;
 
 
proc freq data=vehicule;
  tables cylindree_nu / out=tableau_frequence;
run;
 
proc print data=tableau_frequence;
run;
 
/* expliquer les -1 électrique*/
proc freq data=vehicule;
	tables cylindree_nu * energie_cd;
run;


/* Utilisez la procédure PROC FREQ pour calculer la fréquence */
proc freq data=contrat;
  tables canal_souscription_cd ;
run;
 
 
/* Utilisez la procédure PROC MEANS pour calculer la moyenne */
proc means data=contrat mean;
  var prime_annuelle_ht_mt;
run;
 
/* Utilisez la procédure PROC FREQ pour calculer la fréquence */
proc freq data=contrat;
  tables gamme_produit_cd ;
run;
 
/* Utilisez la procédure PROC FREQ pour calculer la fréquence en tenant compte de la variable gamme_produit_cd */
proc freq data=Contrat_vehicule_societaire;
  tables societaire_sexe_cd * gamme_produit_cd / out=sexpro;
 
run;
 
data sexpro1; set sexpro;
where societaire_sexe_cd ="-1";
run;
