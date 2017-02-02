# Define2Validate - Validate CDISC Dataset-XML with corresponding Define-XML metadata, using R and R4DSXML. 
#     Copyright (C) 2017 Masafumi Okada
#   
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   any later version.
#   
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#   
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.

library(R4DSXML)
library(testthat)
library(validate)

getAttr <- function(Nodeset, Attr){
  sapply(Nodeset, function(el) xmlGetAttr(el, Attr, default = NA))
}

getWhereClause <- function(valueListOID, varMD, docNodeset) {
  namespaces <- c( ns='http://www.cdisc.org/ns/odm/v1.3', 
                   def='http://www.cdisc.org/ns/def/v2.0' )
  vldNodes <- getNodeSet(docNodeset, "//def:ValueListDef", namespaces)
  vld.OIDs <- getAttr( Nodeset = vldNodes, Attr = "OID" )
  if(length(vld.OIDs) < 1) return(NULL)
  vldselect <- vld.OIDs == valueListOID
  if(sum(vldselect) > 1 ) stop(paste("More than one def:ValueListDef for value list OID ", valueListOID))
  vldNode <- vldNodes[[which(vldselect)]]
  itemNodes <- getNodeSet(vldNode, "ns:ItemRef", namespaces)
  itemOIDs <- getAttr(Nodeset=itemNodes, Attr="OID")
  ## %notin% operator is not defined in R. But that can be defined as:
  ## "%notin%" <- function(x, table) !match(x, table, nomatch = 0) > 0
  compars <- c("LT"="<", "LE"="<=", "GT"=">", "GE"=">=", "EQ"="==", "NE"="!=", "IN"="%in%", "NOTIN"="%notin%")
  vldf <- NULL
  for(i in 1:length(itemNodes)) {
    vlitemOID <- xmlGetAttr(itemNodes[[i]], "ItemOID",default=NA)
    wcRefNode <- getNodeSet(itemNodes[[i]], "def:WhereClauseRef", namespaces)
    wcoid <- getAttr(Nodeset=wcRefNode, Attr="WhereClauseOID")
    rcNodes <- getNodeSet(docNodeset, paste("//def:WhereClauseDef[@OID='",wcoid, "']/ns:RangeCheck",sep=""), namespaces)
    if(length(rcNodes) > 0) {
      vlstr <- NULL
      for(j in 1:length(rcNodes)) {
        itemoid <- xmlGetAttr(rcNodes[[j]], "ItemOID", default=NA)
        comparator <- xmlGetAttr(rcNodes[[j]], "Comparator", default=NA)
        checkvalues <- getNodeSet(rcNodes[[j]], "ns:CheckValue", namespaces)
        if(length(checkvalues)>1) {
          values <- NULL
          for(k in 1:length(checkvalues)) {
            values <- append(values, xmlValue(checkvalues[[k]]))
          }
          checkstr <- paste("c(\"", paste(values, collapse="\",\""),"\")",sep="")
        } else {
          checkstr <- paste("\"", xmlValue(checkvalues[[1]]), "\"",sep="")
        }
        itemName <- subset(varMD, IR_ItemOID == itemoid)$ID_Name
        compaStr <- compars[comparator]
        vlstr <- append(vlstr, paste(itemName, compaStr, checkstr))
      }
    }
    vldf <- rbind(vldf, data.frame(IR_ItemOID=vlitemOID, WhereClause=
                                     paste("(!(", paste(vlstr, collapse=" & "), "))")))
  }
  return(vldf)
  }

md2validate <- function(metadata, varname=NA, descname=NA) {
  expect_equal(nrow(metadata),1)
  # if the metadata is value-level metadata, variable name should be given as varName argument. 
  # otherwise, get variable name from the metadata.
  if(is.na(varname)) {
    varname <- metadata$"ID_Name"
    descname <- varname
  }
  varLength <- metadata$"ID_Length"
  exprdf <- data.frame()
  
  if(!is.na(varLength)) {
    exprdf <- rbind(exprdf, data.frame(
      expr=paste("nchar(as.character(", varname, ")) <= ", varLength, sep=""),
      name=paste("Length of ", descname,sep="")
    ))
  }
  varMandatory <- metadata$"IR_Mandatory"
  expect_false(is.na(varMandatory))
  if(varMandatory == "Yes") {
    exprdf <- rbind(exprdf, data.frame(
      expr=paste("!is.na(", varname, ")", sep=""),
      name=paste(descname, " is mandatory",sep="")
    ))
  }
  
  varDataType <- metadata$"ID_DataType"
  expect_false(is.na(varDataType))
  if(varDataType == "integer") {
    exprdf <- rbind(exprdf, data.frame(
      expr=paste("regexpr(\"^[0-9-]+$\",as.character(", varname,")) == 1", sep=""),
      name=paste(descname, " should be integer",sep="")
    ))
  }
  if(varDataType == "float") {
    exprdf <- rbind(exprdf, data.frame(
      expr=paste("(regexpr(\"^[0-9.+-eE]+$\",as.character(", varname,")) == 1) & !is.na(as.numeric(", varname, "))",sep=""),
      name=paste(descname, " should be float",sep="")
    ))
  }
  if(varDataType == "date") {
    exprdf <- rbind(exprdf, data.frame(
      expr=paste("regexpr(\"^[[:digit:]]{4}(-[[:digit:]][[:digit:]](-[[:digit:]][[:digit:]](T[[:digit:]][[:digit:]]:[[:digit:]][[:digit:]](:[[:digit:]][[:digit:]])?(.[[:digit:]]+)?(([+-][[:digit:]][[:digit:]]:[[:digit:]][[:digit:]])|Z)?)?)?)?$\",as.character(", varname,")) == 1", sep=""),
      name=paste(descname, " should be Date",sep="")
    ))
  }
  varCodeList <- metadata$"ID_CodeListOID"
  if(!is.na(varCodeList)) {
    exprdf <- rbind(exprdf, data.frame(
      expr=paste("as.character(", varname, ") %in% CT[CT$OID == \"", varCodeList, "\", \"CodedValue\"]", sep=""),
      name=paste(descname, " should follow codelist " , varCodeList,sep="")
    ))
  }
  valuelistOID <- metadata$"ID_ValueListOID"
  return(list(rules=exprdf, valuelistOID=valuelistOID))
}

define2validate <- function(domain, file="exampleRules.yaml", definexml="Odm_Define.xml", overwrite=FALSE) {
  varmd <- subset(getVarMD(definexml), IGD_Name == domain)
  if(nrow(varmd) < 1) {
    stop(paste("No definition of domain ", domain,". Please specify correct set of domain and corresponding Define-XML.",sep=""))
  }
  if(file.exists(file) && overwrite == FALSE) {
    stop(paste("File", file, "exists, but overwrite option is not set."))
  }
  cat(file=file, append=FALSE, "")
  out <- function(...) cat(file=file, append=TRUE, paste(...,"\n",sep=""))
  vloids <- NULL
  out("rules:")
  expect_gt(nrow(varmd), 0)
  for(row in 1:nrow(varmd)) {
    r <- md2validate(varmd[row,])
    if(!is.null(r$valuelistOID) && !is.na(r$valuelistOID)) {
      vloids <- append(vloids, r$valuelistOID)
    }
    #browser()
    if(nrow(r$rules)>0){
      for(i in 1:nrow(r$rules)) {
        out('-')
        out("  expr: '",r$rules[i,"expr"], "'")
        out('  name: ',r$rules[i,"name"])
      }
    }
  }
  valmd <- getValMD(definexml)
  docnode <- xmlTreeParse( definexml, useInternalNodes = T )
  whereclauses <- data.frame()
  for(vloid in vloids) {
    whereclauses <- getWhereClause(vloid, varmd, docnode)
    expect_gt(nrow(whereclauses),0)
    for(i in 1:nrow(whereclauses)) {
        wc <- whereclauses[i,]
        itemmd <- subset(valmd, IR_ItemOID == wc$IR_ItemOID)
        expect_equal(nrow(itemmd), 1)
        tname <- subset(varmd, ID_ValueListOID==vloid)$ID_Name
        r <- md2validate(itemmd, tname, paste(itemmd$ID_Name, "(", tname, ")", sep=""))
        if(nrow(r$rules)>0){
          for(i in 1:nrow(r$rules)) {
            out('-')
            out("  expr: '",wc$WhereClause, " | ", r$rules[i,"expr"], "'")
            out('  name: ',r$rules[i,"name"])
          }
        }
      }
    }
    out("---")
}