
BEGIN { j=1 }
/Seleziona Marca/ {
        split($0, ar, "Seleziona Marca")
        split(ar[2], ar_1, "\"options\":\\{\"")
        split(ar_1[2], ar_2, "\"\\}")
        nb=split(ar_2[1], ar_3, "\",\"")
        for(i=1;i<=nb;i++) {
                split(ar_3[i], ar_4, "\":\"")
                printf("marque_id[%d]=\"%s\";\n", j, ar_4[1])
                printf("marque_name[%d]=\"%s\";\n", j, ar_4[2])
                j++
        }
        exit
}
END {
        print "max_marque="j""
}