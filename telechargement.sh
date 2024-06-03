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
curl "${url}" \
  -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7' \
  -H 'accept-language: fr-FR,fr;q=0.9,en-US;q=0.8,en;q=0.7' \
  -H 'cache-control: max-age=0' \
  -H 'if-modified-since: Fri, 31 May 2024 12:57:31 GMT' \
  -H 'priority: u=0, i' \
  -H 'sec-ch-ua: "Google Chrome";v="125", "Chromium";v="125", "Not.A/Brand";v="24"' \
  -H 'sec-ch-ua-mobile: ?0' \
  -H 'sec-ch-ua-platform: "Windows"' \
  -H 'sec-fetch-dest: document' \
  -H 'sec-fetch-mode: navigate' \
  -H 'sec-fetch-site: none' \
  -H 'sec-fetch-user: ?1' \
  -H 'upgrade-insecure-requests: 1' \
  -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36' > ${output} 
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
        table="bazos"`date +"%Y_%m"`
fi
if [ "${grand_table}X" = "X" ]
        then
        grand_table="VO_UK_"`date +"%Y_%m"`
fi

debut=`date +"%Y-%m-%d %H:%M:%S"`
dir=`pwd`
mkdir -p ${dir}/DONNEE  ${dir}/DONNEE/ANNONCE ${dir}/DONNEE/RESULT_PARS ${dir}/DONNEE/PAGES_LISTE

if [ ${get_list_ind} -eq 11 ]; then
			url='https://auto.bazos.cz/'
			output=${dir}/DONNEE/page-0.html
			download_pages
			nb_site=$(awk -f ${dir}/nb_annonce.awk ${output})
			echo "nombre_site=${nb_site}"
			let "max_page=$nb_site/$nb_retrieve_per_page"
			echo "max_page=${max_page}"
			nbr=10
			max_page=${max_page}*${nbr}
			echo "page_max=${max_page}"
			max_page=60
				
                # TELECHARGEMENT DE 3 PAGES_LISTE
				for (( page=20; page <= ${max_page}; page+=20 ))
				do 
					# https://auto.bazos.cz/20/
					output=${dir}/DONNEE/PAGES_LISTE/page-${page}.html
					url=https://auto.bazos.cz/${page}/
					download_pages 
					echo "PARSING_LISTES"
					awk -f ${dir}/liste_tab.awk -f ${dir}/put_html_into_tab.awk ${dir}/DONNEE/PAGES_LISTE/page-${page}.html >> ${dir}/DONNEE/extract.$$
					echo "parsing effectué"										
				done
				
				awk -f ${dir}/liste_marque.awk ${dir}/DONNEE/PAGES_LISTE/page-20.html > ${dir}/DONNEE/liste_marque.sql
				. ${dir}/DONNEE/liste_marque.sql
				echo "max_marques=${max_marque}"
				# for (( marque=1 ; marque<=${max_marque}; marque++ ))
					for marque in 1 3
					do 
						echo "on est dans le marque ${marque_name[$marque]}"
						m_rep=${marque_name[$marque]}
						mkdir -p ${dir}/DONNEE/${m_rep} 
						# https://auto.bazos.cz/bmw/
						output=${dir}/DONNEE/${m_rep}/page_0.html
						url=https://auto.bazos.cz/${m_rep}/
						download_pages
						nb_site=$(awk -f ${dir}/nb_annonce.awk ${output})
						echo "nombre_site=${nb_site}"
						let "max_page=$nb_site/$nb_retrieve_per_page"
						echo "max_page=${max_page}"
						
							# Crawl page list
							max_page=60
							for (( page=20; page <= ${max_page}; page+=20 ))
							do 
								# https://auto.bazos.cz/alfa/20/
								output=${dir}/DONNEE/${m_rep}/page-${page}.html
								url=https://auto.bazos.cz/${m_rep}/${page}/
								download_pages
								echo "PARSING_LISTES"
								awk -f ${dir}/liste_tab.awk -f ${dir}/put_html_into_tab.awk ${dir}/DONNEE/${m_rep}/page-${page}.html >> ${dir}/DONNEE/${m_rep}/${m_rep}.$$
								echo "parsing effectué"		
							done
							
                            cat  ${dir}/DONNEE/${m_rep}/${m_rep}.$$  | sort -u -k1,1 >  ${dir}/DONNEE/${m_rep}/${m_rep}.tab
							nb_observe=`wc -l  ${dir}/DONNEE/${m_rep}/${m_rep}.tab | awk '{print $1}'`
							cat ${dir}/DONNEE/${m_rep}/${m_rep}.tab  >> ${dir}/DONNEE/extract.$$
							echo -e "${m_rep}\t${nb_site}\t${nb_observe}\tMARQUE"
                    done
						cat ${dir}/DONNEE/extract.$$ | sort -u -k1,1 >  ${dir}/DONNEE/extract.tab
fi	
    awk -vtable=${table} -f ${dir}/liste_tab.awk -f ${dir}/put_tab_into_db.awk  ${dir}/DONNEE/extract.tab >> ${dir}/DONNEE/VO_ANNONCE_insert.sql 

if [ ${get_detail_mod} -eq 1 ]; then 
	max_i=`cat ${dir}/DONNEE/extract.tab | wc -l`
	echo "${max_i}"
	max_i=20
		for (( i=1; i <=${max_i} ; i++ ))
		do
			# cat extract.tab | awk "NR == 1" | awk '{print $3}'
			id_client=`cat ${dir}/DONNEE/extract.tab | awk "NR==$i" | awk '{print $2}'`
			output=${dir}/DONNEE/ANNONCE/annonce-${id_client}.html
			url=`cat ${dir}/DONNEE/extract.tab | awk "NR==$i" | awk '{print $1}'`
			download_page
			awk -f ${dir}/all_html.awk ${dir}/DONNEE/ANNONCE/annonce-${id_client}.html >> ${dir}/DONNEE/RESULT_PARS/resultat.sql 	
		done		
fi

echo -e "FIN DU TELECHARGEMENT!"
ExitProcess 0