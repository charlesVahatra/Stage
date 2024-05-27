#!/bin/bash

ExitProcess () {
        status=$1
        if [ ${status} -ne 0 ]
        then
                echo -e $usage
                echo -e $error
        fi
        find ${work_dir}/ -type f -name "*.$$" -exec rm -f {} \;
        exit ${status}
}

function download_pages () {
curl "${url}"  \
	-H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7' \
	-H 'accept-language: fr-FR,fr;q=0.9,en-US;q=0.8,en;q=0.7' \
	-H 'cache-control: max-age=0' \
	-H 'priority: u=0, i' \
	-H 'sec-ch-ua: "Chromium";v="124", "Google Chrome";v="124", "Not-A.Brand";v="99"' \
	-H 'sec-ch-ua-mobile: ?1' \
	-H 'sec-ch-ua-platform: "Android"' \
	-H 'sec-fetch-dest: document' \
	-H 'sec-fetch-mode: navigate' \
	-H 'sec-fetch-site: none' \
	-H 'sec-fetch-user: ?1' \
	-H 'upgrade-insecure-requests: 1' \
	-H 'user-agent: Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36'  > ${output}
}
#
# MAIN
#
usage="download_site.sh \n\
\t-a no download - just process what's in the directory\n\
\t-d [date] (default today)\n\
\t-h help\n\
\t-i id start de la region default : 1\n\
\t-I id end de la region default : max_region\n\
\t-M [region]\n\
\t-m [modele]\n\
\t-r retrieve only, do not download the detailed adds\n\
\t-R reset : delete files to redownload\n\
\t-t table name \n\
\t-T valeurs : new used certified ex: -T\"used new\"\n\
\t-x debug mode\n\
"

date
typeset -i lynx_ind=1
typeset -i get_detail_mod=1
typeset -i get_all_ind=1
typeset -i get_list_ind=1
typeset -i nb_retrieve_per_page=20
typeset -i max_retrieve=30000
typeset -i nb_processus=5
typeset -i max_loop_1=5
typeset -i max_loop=3
Y=`date "+%Y"  --date="-366 days ago"`

while getopts :-ad:rht:xz: name
do
  case $name in

    a)  lynx_ind=0
        let "shift=shift+1"
        ;;

    d)  d=$OPTARG
        let "shift=shift+1"
        ;;

        i)      MIN_REGION_ID=$OPTARG
        let "shift=shift+1"
        ;;

    I)  MAX_REGION_ID=$OPTARG
        let "shift=shift+1"
        ;;

    M)  my_region=`echo ${OPTARG} | tr '[:lower:]' '[:upper:]' `
        let "shift=shift+1"
        ;;

        m)      my_modele=`echo $OPTARG | tr '[:lower:]' '[:upper:]' `
        let "shift=shift+1"
        ;;

    h)  echo -e ${usage}
        ExitProcess 0
        ;;

    r)  get_all_ind=0
        let "shift=shift+1"
        ;;

    t)  table=$OPTARG
        let "shift=shift+1"
        ;;

    x)  set -x
        let "shift=shift+1"
        ;;

    z)  let "shift=shift+1"
        ;;

    --) break
        ;;

        esac
done
shift ${shift}

if [ $# -ne 0 ]
        then
    error="Bad arguments, $@"
    ExitProcess 1
fi

if [ "${d}X" = "X" ]
        then
        d=`date +"%Y%m%d"`
fi
if [ "${table}X" = "X" ]
        then
        mois=$(date --date "today + `date +%d`days" +%Y_%m)
        table="QUATTRORUOTE_"`date +"%Y_%m"`
fi
if [ "${grand_table}X" = "X" ]
        then
        grand_table="VO_UK_"`date +"%Y_%m"`
fi

debut=`date +"%Y-%m-%d %H:%M:%S"`
dir=`pwd`
mkdir -p ${dir}/DONNEE  ${dir}/DONNEE/ANNONCE ${dir}/DONNEE/RESULT_PARS

echo "list $nb_status" > ${work_dir}/${d}/MONTHLY/status

if [ ${get_list_ind} -eq 1 ]; then

for type in "km-0" "nuovo" "usato"
		do 
			echo "ETAPES: ${type}"
			#creation de la repertoire
			mkdir -p ${dir}/DONNEE/${type}
			# https://www.quattroruote.it/auto-usate/annunci/tipologia-km-0 
			#url pour telecharger le type
			url=${url_base}tipologia-${type}
			output=${dir}/DONNEE/${type}/page-0.html
			download_pages
			nb_site=$(awk -f ${dir}/nb_annonce.awk ${output})
			echo "nombre_site=${nb_site}"
			let "max_page=$nb_site/$nb_retrieve_per_page"
			echo "max_page=${max_page}"
			max_page=3
				# TELECHARGEMENT DE 3 PAGES_LISTE
				for (( page=1; page <=${max_page}; page++ ))
				do 
					# https://www.quattroruote.it/auto-usate/annunci/tipologia-[TYPE]?page=2
					url=https://www.quattroruote.it/auto-usate/annunci/tipologia-${type}?page=${page}
					output=${dir}/DONNEE/${type}/page-${page}.html
					download_pages 
					echo "PARSING_LISTES"
					awk -f ${dir}/liste_tab.awk -f ${dir}/put_html_into_tab.awk ${dir}/DONNEE/${type}/page-${page}.html >> ${dir}/DONNEE/${type}/${type}.$$
					echo "parsing effectué"										
				done 
				# FIN DE 3 TELECHARGEMENT DE PAGES_LISTE	
			
				#2- PAR MARQUE
				# liste_marque
				awk -f ${dir}/liste_marque.awk ${output} > ${dir}/DONNEE/${type}/liste_marque.sql
				. ${dir}/DONNEE/${type}/liste_marque.sql
				echo "max_marques=${max_marque}"
				# for (( marque=1 ; marque<=${max_marque}; marque++ ))
					for marque in 8 13
					do 
						echo "on est dans le marque ${marque_id[$marque]}"
						m_url=${marque_id[$marque]}
						m_rep=${marque_id[$marque]}
						mkdir -p ${dir}/DONNEE/${type}/${m_rep} 
						
						url=https://www.quattroruote.it/auto-usate/annunci/marca-${m_url}/tipologia-${type}
						output=${dir}/DONNEE/${type}/${m_rep}/page-0.html
						download_pages
						nb_site=$(awk -f ${dir}/nb_annonce.awk ${output})
						echo "nombre_site=${nb_site}"
						let "max_page=$nb_site/$nb_retrieve_per_page"
						echo "max_page=${max_page}"
						max_page=5
							# Crawl page list
							for (( page=1; page <=${max_page}; page++ ))
							do 
								# https://www.quattroruote.it/auto-usate/annunci/tipologia-[TYPE]?page=2
								url=https://www.quattroruote.it/auto-usate/annunci/marca-${m_url}/tipologia-${type}?page=${page}
								output=${dir}/DONNEE/${type}/${m_rep}/page-${page}.html
								download_pages 
								
								echo "PARSING_LISTES"
								awk -f ${dir}/liste_tab.awk -f ${dir}/put_html_into_tab.awk ${dir}/DONNEE/${type}/${m_rep}/page-${page}.html >> ${dir}/DONNEE/${type}/${m_rep}/${m_rep}.$$
								echo "parsing effectué"										
							done 
					
							cat  ${dir}/DONNEE/${type}/${m_rep}/${m_rep}.$$  | sort -u -k1,1 >  ${dir}/DONNEE/${type}/${m_rep}/${m_rep}.tab
							nb_observe=`wc -l  ${dir}/DONNEE/${type}/${m_rep}/${m_rep}.tab | awk '{print $1; }'`
							cat ${dir}/DONNEE/${type}/${m_rep}/${m_rep}.tab  >> ${dir}/DONNEE/extract.$$
							echo -e "${m_url}\t${nb_site}\t${nb_observe}\tMARQUE"
						
						#3-PAR MODELE
						echo "modele"
						echo "parsing liste_modele"
						awk -f ${dir}/liste_modele.awk ${output} > ${dir}/DONNEE/${type}/liste_modele.sql
						. ${dir}/DONNEE/${type}/liste_modele.sql
						echo "parsing liste_modele terminé"
						echo "max_model=${max_model}"
						max_model=3
							for (( modele=1; modele <${max_model}; modele++ ))
							do 
								echo "${modele_name[$modele]}"
								m_ref=${model_name[$modele]}
								mkdir -p ${dir}/DONNEE/${type}/${m_rep}/${m_ref}
								# https://www.quattroruote.it/auto-usate/annunci/marca-bmw/modello-i4/tipologia-km-0
								output=${dir}/DONNEE/${type}/${m_rep}/${m_ref}/page-0.html
								url=https://www.quattroruote.it/auto-usate/annunci/marca-${m_url}/modello-${m_ref}/tipologia-${type}
								download_pages
								nb_site=$(awk -f ${dir}/nb_annonce.awk ${output})
								echo "nombre_site=${nb_site}"
								let "max_page=$nb_site/$nb_retrieve_per_page"
								echo "max_page=${max_page}"
								max_page=2
								echo "le nombre de page_listes est limité a 2 ici"
									for (( page=1; page <=${max_page}; page++ ))
									do 
										# https://www.quattroruote.it/auto-usate/annunci/marca-bmw/modello-serie-1/tipologia-usato?page=2
										url=https://www.quattroruote.it/auto-usate/annunci/marca-${m_url}/modello-${m_ref}/tipologia-${type}?page=${page}
										output=${dir}/DONNEE/${type}/${m_rep}/${m_ref}/page-${page}.html
										download_pages 
										echo "PARSING_LISTES"
										awk -f ${dir}/liste_tab.awk -f ${dir}/put_html_into_tab.awk ${dir}/DONNEE/${type}/${m_rep}/${m_ref/}/page-${page}.html >> ${dir}/DONNEE/${type}/${m_rep}/${m_ref}/${m_ref}.$$
										echo "parsing effectué"										
									done
									 
							done 
							cat  ${dir}/DONNEE/${type}/${m_rep}/${m_ref}/${m_ref}.$$  | sort -u -k1,1 >  ${dir}/DONNEE/${type}/${m_rep}/${m_ref}/${m_ref}.tab
							nb_observe=`wc -l  ${dir}/DONNEE/${type}/${m_rep}/${m_ref}/${m_ref}.tab | awk '{print $1; }'`
							cat ${dir}/DONNEE/${type}/${m_rep}/${m_ref}/${m_ref}.tab  >> ${dir}/DONNEE/extract.$$
							echo -e "${m_ref}\t${nb_site}\t${nb_observe}\tMODELE"
							
					done 
		done 
	wait 
	# Supression des doublons
	cat ${dir}/DONNEE/extract.$$ | sort -u -k1,1 >  ${dir}/DONNEE/extract.tab 		
fi 	
awk -vtable=${table} -f ${dir}/liste_tab.awk -f ${dir}/put_tab_into_db.awk  ${dir}/DONNEE/RESULT_PARS/extract.tab > ${dir}/DONNEE/RESULT_PARS/VO_ANNONCE_insert.sql 

if [ ${get_detail_mod} -eq 1 ]; then 
	max_i=`cat ${dir}/DONNEE/extract.tab | wc -l`
	echo "${max_i}"
	max_i=2
		for (( i=1; i <=${max_i} ; i++ ))
		do
			# cat extract.tab | awk "NR == 1" | awk '{print $3}'
			url=`cat ${dir}/DONNEE/extract.tab | awk "NR==$i" | awk '{print $2}'`
			echo ${url}
			id_client=`cat ${dir}/DONNEE/extract.tab | awk "NR==$i" | awk '{print $3}'`
			output=${dir}/DONNEE/ANNONCE/annonce-${id_client}.html
			download_pages
			
			# awk -f ${dir}/all_html.awk ${dir}/DONNEE/ANNONCE/annonce-${id_client}.html >> ${dir}/DONNEE/RESULT_PARS/resultat.sql 
			
		done		
		awk -f ${dir}/liste_tab.awk -f ${dir}/put_into_db.awk ${dir}/DONNEE/extract.tab  > ${dir}/DONNEE/insertion.sql
fi 
echo -e "FIN DU TELECHARGEMENT!"
ExitProcess 0
