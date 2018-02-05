# Evaluate availability of cr2validate()

r <- data.frame()
for(dom in unlist(sdtmdomains())) { 
  v <- c2v("ConformanceRules.csv", dom)
  r <- rbind(r, data.frame(Domain=dom, NumRules=v$numRules, ConvedRules=length(v$exprs)))
}
r$Percent <- round(r$ConvedRules / r$NumRules * 100, 1)
