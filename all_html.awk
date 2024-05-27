BEGIN {	
	i=1	
	title[i]="TELEPHONE";		i++;
	title[i]="KM";		i++;
	title[i]="NOM";		i++;
	title[i]="CP";		i++;
	title[i]="CYLINDRE";		i++;
	title[i]="PORTE";		i++;
	title[i]="CAROSSERIE";		i++;
	title[i]="CARBURANT";		i++;
	title[i]="ANNEE";		i++;
	title[i]="TRANSMISSION";		i++;
	title[i]="PHOTO";		i++;
	max_i=i
}
/"telephone":"/{
	split($0, ar, /"telephone":"/)
	split(ar[2], ar1, /",/)
	val["TELEPHONE"]=ar1[1]
}
/"mileageFromOdometer":/{
	split($0, ar, /"value":/)
	split(ar[2], ar1, /,/)
	val["KM"]=ar1[1]
}
/<title>/{
	split($0, ar, />/)
	split(ar[2], ar1, /</)
	val["NOM"]=ar1[1]
}
/"postalCode":"/{
	split($0, ar, /"postalCode":"/)
	split(ar[2], ar1, /",/)
	val["CP"]=ar1[1]
}

/div class="col-6 px-0 px-md-auto"><strong>Cilindrata<\/strong><\/div>/{
	getline
	split($0, ar, /<div class="col-6 px-0 px-md-auto">/)
	split(ar[2], ar1, /<\/div>/)
	val["CYLINDRE"]=ar1[1]
}
/<div class="col-6 px-0 px-md-auto"><strong>Porte<\/strong><\/div>/{
	getline
	split($0, ar, /<div class="col-6 px-0 px-md-auto">/)
	split(ar[2], ar1, /<\/div>/)
	val["PORTE"]=ar1[1]
}
/<div class="col-6 px-0 px-md-auto"><strong>Carrozzeria<\/strong><\/div>/{
	getline
	split($0, ar, /<div class="col-6 px-0 px-md-auto">/)
	split(ar[2], ar1, /<\/div>/)
	val["CAROSSERIE"]=ar1[1]
}
/<div class="col-6 px-0 px-md-auto"><strong>Alimentazione<\/strong><\/div>/{
	getline
	split($0, ar, /<div class="col-6 px-0 px-md-auto">/)
	split(ar[2], ar1, /<\/div>/)
	val["CARBURANT"]=ar1[1]
}
/<div class="col-6 px-0 px-md-auto"><strong>Cambio<\/strong><\/div>/{
	getline
	split($0, ar, /<div class="col-6 px-0 px-md-auto">/)
	split(ar[2], ar1, /<\/div>/)
	val["TRANSMISSION"]=ar1[1]
}
/"modelDate":/{
	split($0, ar, /"modelDate":/)
	split(ar[2], ar1, /,/)
	val["ANNEE"]=ar1[1]
	
}
/title="Segnala anomalia" style="font-size: small"/{
	getline
	split($0, ar, /width="/)
	split(ar[2], ar1, /" \/>/)
	val["PHOTO"]=ar1[1]
}
END {	
	for (i=1; i<max_i; i++) {		
		gsub(/"|\t|\r|\n|\\/, "", val[title[i]])			
		if (trim(val[title[i]])!="")
			upd=upd" "sprintf("%s=\"%s\",", title[i], trim(val[title[i]]))	
	}
	if (upd!="")
		printf ("update %s set %s id_client=\"%s\" where site=\"quattroruote\" and ID_CLIENT=\"%s\";\n", table, upd, val["ID_CLIENT"], val["ID_CLIENT"])
}

function ltrim(s) {
	gsub("^[ \t]+", "", s);
	return s
}

function rtrim(s) {
	gsub("[ \t]+$", "", s);
	return s
}

function trim(s) {
	return rtrim(ltrim(s));
}                        
