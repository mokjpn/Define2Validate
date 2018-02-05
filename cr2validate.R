# Read SDTMIG Conformance Rules file (original file is distributed as Excel file, this function needs comma-separated text file)
# https://www.cdisc.org/standards/foundational/study-data-tabulation-model-implementation-guide-sdtmig/sdtmig-v32


sdtmdomains <- function() {
  return( list(
    SPC = c("CO", "DM", "SE", "SV"),
    INT = c("CM", "EX", "EC", "PR", "SU"),
    EVT = c("AE", "CE", "DS", "DV", "HO", "MH"),
    FND = c("DA", "DD", "EG", "IE", "IS", "LB", "MB", "MS", "MI", "MO",
             "PC", "PP", "PE", "QS", "RP", "SC", "SS", "TU", "TR", "RS",
             "VS"),
    TDM = c("TE", "TA", "TV", "TD", "TS", "TI")
  ))
}


applicable <- function(domain, rule) {
  sdtmd <- sdtmdomains()
  class <- names(sdtmd)[grep(domain, sdtmd)]
  if(length(class) == 0) stop("Domain", domain, "is not supported")
  ruleclass <- strsplit(as.character(rule[1,"Class"]), c("[ ,]"))[[1]]
  ruledomain <- strsplit(as.character(rule[1,"Domain"]), c("[ ,()]"))[[1]]
  if("NOT" %in% ruledomain && grep("NOT", ruledomain) != 1) stop("'NOT' attribute for domain specification is allowed only when it is placed at the first of domain spec.") 
  if(rule["Class"] == "ALL" || class %in% ruleclass)
    if(rule["Domain"] == "ALL" || ( !("NOT" %in% ruledomain) && domain %in% ruledomain) ||
       ("NOT" %in% ruledomain && !(domain %in% ruledomain)))
      return(TRUE)
  return(FALSE)
}

cond2expr <- function(cond, domain) {
#  print(as.character(cond))
  orconds <- strsplit(as.character(cond), " or ")[[1]] 
  exprs <- vector()
  for(oc in orconds) {
    andconds <- strsplit(oc, " and ")[[1]]
    aexprs <- vector()
    for(ac in andconds) {
      preg <- "( [\\^<>]?= | not present in | present in | not in | in )"
      parammatch <- regexpr(preg , ac)
      if(parammatch == -1) {
        warning("syntax not supported: ", ac)
        next
      }
      operator <- gsub("(^ +| +$)","",regmatches(ac, parammatch))
      if(operator == "^=")
        opr <- "!="
      else if(operator == "=")
        opr <- "=="
      else if(operator == "in")
        opr <- "%in%"
      else if(operator == "not in")
        opr <- "%notin%"
      else
        opr <- operator

      params <- gsub("(^ +| +$)","",strsplit(ac, preg )[[1]])
      rparams <- vector()
      types <- vector()
      for(param in params) {
        if(regexpr("^(--[A-Z]+|[A-Z]+)$",param) == 1) {
          type <- "VARIABLE"
          param <- gsub("^--", domain, param)
        }
        else if(regexpr("^'[A-z ]+'$",param) == 1) {
          type <- "VALUE"
          param <- gsub('\'', '\"',param) 
        }
        else if(regexpr("^null$",param) == 1) {
          type <- "NULL"
        }
        else if(regexpr("^\\(['A-z ,]+\\)$", param) == 1) {
          type <- "LIST"
          param <- gsub('\'', '\"',param) 
          param <- gsub('null', 'NA', param) ## This produces valid R syntax, but "validate" package makes an error. i.e. VALUE %in% c("Y", NA) 
          param <- paste("c", param, sep="")
        } else if(param == "dataset") {
          type <- "EXIST"   
        } else {
          warning("parameter not supported: ", param)
          next
        }
        rparams <- append(rparams, param)
        types <- append(types, type)
      }
      if(length(rparams) == 2) {
        if(types[2] == "NULL" && opr == "==") {
          expr1 <- paste("is.na(",rparams[1], ")", sep="")
        } else if(types[2] == "NULL" && opr == "!=") {
          expr1 <- paste("!is.na(",rparams[1], ")", sep="")
        } else if(types[2] == "EXIST" && opr == "not present in") {
          expr1 <- paste("is.null(", rparams[1], ")",sep="")
        } else if(types[2] == "EXIST" && opr == "present in") {
          expr1 <- paste("!is.null(", rparams[1], ")", sep="")
        } else {
          expr1 <- paste(rparams[1] , opr, rparams[2])
        }
        if(expr1 != "")
          aexprs <- append(aexprs, expr1)
      } else if(length(rparams) > 2) {
        warning("number of parameters too much")
      }
    }
    aexpr <- paste(aexprs, collapse=" & ")
    if(aexpr != "")
      exprs <- append(exprs, aexpr)
  }
  return(paste(exprs, collapse=" | "))
}

cr2validate <- function(domain, file="exampleRulesC.yaml", conformance="ConformanceRules.csv", overwrite=FALSE) {
  if(file.exists(file) && overwrite == FALSE) {
    stop(paste("File", file, "exists, but overwrite option is not set."))
  }
  r <- c2v(conformance, domain)
  cat(file=file, append=FALSE, "")
  out <- function(...) cat(file=file, append=TRUE, paste(...,"\n",sep=""))
  out("rules:")
  if(length(r$exprs)>0){
    for(i in 1:length(r$exprs)) {
      out('-')
      out("  expr: '",r$exprs[i], "'")
      out('  name: ',r$descs[i])
    }
  }
  out("---")
}

c2v <- function(rulesFile, domain) {
  rules <- read.csv(rulesFile)
  if(nrow(rules) < 1 ) stop("Invalid Confomance Rules file:", rulesFile)
  apprules <- 0
  exprs <- vector()
  descs <- vector()
  for(row in 1:nrow(rules)) {
    rule <- rules[row,]
    if(!applicable(domain, rule))
      next
    if(rule[1, "Programmable"] != "Y")
      next

    apprules <- apprules + 1
    if(rule[1, "Variable"] == "GEN") {
      warning("general rule for all variables('GEN') is not supported yet:", rule[1, "Rule"])
      next
    }
    condexpr <- cond2expr(rule[1, "Condition"],domain)
    if(rule[1, "Condition"] != "" && condexpr == "") 
      next
    ruleexpr <- cond2expr(rule[1, "Rule"],domain)
    if(rule[1, "Rule"] != "" && ruleexpr == "") 
      next
    if(rule[1,"Condition"] == "") {
      exprs <- append(exprs, ruleexpr)
      descs <- append(descs, convdesc(rule[1,"Rule"]))
    } else {
      exprs <- append(exprs, paste("(!(", condexpr, ")) | (", ruleexpr, ")",sep=""))
      descs <- append(descs, paste("When ", rule[1, "Condition"], ", ", convdesc(rule[1,"Rule"]), sep=""))
    }
  }
  return(list(exprs=exprs, descs=descs, numRules=apprules))
}

convdesc <- function(d) {
  d <- gsub("\\^=", " should not be ",d)
  d <- gsub("=", " should be ", d)
  d <- gsub("null", "missing value", d)
  return(d)
}