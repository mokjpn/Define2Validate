# Define2Validate
Validate CDISC Dataset-XML with corresponding Define-XML metadata, using R and R4DSXML.
Currently only a few rules are implemented, but this supports variable-level metadata, value-level metadata, and controlled terminology defined in your Define-XML.

## Install

1. Install the required package.
[testthat](https://cran.r-project.org/web/packages/testthat/index.html), [validate](https://cran.r-project.org/web/packages/validate/index.html) from CRAN, [R4DSXML](https://github.com/DataDrivenInc/R4DSXML) from GitHub.
    ```{r}
    install.packages(c("testthat","validate","devtools"))
    library(devtools)
    install_github("DataDrivenInc/R4DSXML/R4DSXML")
    ```
2. Load the script.
    ```{r}
    source("https://raw.githubusercontent.com/mokjpn/Define2Validate/master/define2validate.R")
    ```

## Usage

Assume you have your Define-XML file(`Odm_Define.xml`) for your LB domain dataset(`Odm_LB.xml`).

1. Load the required package.
    ```{r}
    library(R4DSXML)
    library(testthat)
    library(validate)
    ```
2. Specify domain of your Dataset-XML
    ```{r}
    Domain="LB"
    ```
3. Call `define2validate()` to make validation rule file for [validate](https://cran.r-project.org/web/packages/validate/index.html) package. Validation rules will be stored in `exampleRules.yaml` file.
    ```{r}
    define2validate(Domain, file="exampleRules.yaml", definexml="Odm_Define.xml")
    ```
4. Create `validator` object.
    ```{r}
    v <- validator(.file="exampleRules.yaml") 
    ```
5. Read your dataset.
    ```{r}
    x <- read.dataset.xml(paste("Odm_", Domain, ".xml", sep=""), "Odm_Define.xml") 
    ```
6. Read Controlled Terminology.
    ```{r}
    CT <- getCT("Odm_Define.xml")
    ```
Note: variable name for controlled terminology is fixed to "CT".
1. Define `%notin%` operator if you use it in your Define-XML's RangeCheck element.
    ```{r}
    "%notin%" <- function(x, table) !match(x, table, nomatch = 0) > 0
    ```
7. Do validation and get the summarized result.
    ```{r}
    cf <- confront(x,v)
    summary(cf)
    ```

## Limitation

1. Currently, inside definition of "Where Clauses" in Define-XML, referred variables must be from the same domain of value lists that uses the where clauses.

    For example, value-level metadata for VS domain variable sometimes refers to variables of DM domain. It will give a error on define2validate.

    This limitation is proposed as [Issue #1](https://github.com/mokjpn/Define2Validate/issues/1).

2. External definition of controlled terminology is not supported yet.

    Only controlled terminologies defined inside Define-XML are supported now.

## Example output


|rule                                        | items| passes| fails| nNA|error |warning |expression                                                                                                                                                      |
|:-------------------------------------------|-----:|------:|-----:|---:|:-----|:-------|:---------------------------------------------------------------------------------------------------------------------------------------------------------------|
|Length of DOMAIN                            |     6|      6|     0|   0|FALSE |FALSE   |nchar(as.character(DOMAIN)) <= 2                                                                                                                                |
|DOMAIN is mandatory                         |     6|      6|     0|   0|FALSE |FALSE   |!is.na(DOMAIN)                                                                                                                                                  |
|DOMAIN should follow codelist CL.DOMAIN     |     6|      6|     0|   0|FALSE |FALSE   |as.character(DOMAIN) %in% CT[CT[, "OID"] == "CL.DOMAIN", "CodedValue"]                                                                                          |
|Length of LBSEQ                             |     6|      6|     0|   0|FALSE |FALSE   |nchar(as.character(LBSEQ)) <= 2                                                                                                                                 |
|LBSEQ is mandatory                          |     6|      6|     0|   0|FALSE |FALSE   |!is.na(LBSEQ)                                                                                                                                                   |
|LBSEQ should be integer                     |     6|      6|     0|   0|FALSE |FALSE   |regexpr("^[0-9-]+$", as.character(LBSEQ)) == 1                                                                                                                  |
|Length of LBREFID                           |     6|      6|     0|   0|FALSE |FALSE   |nchar(as.character(LBREFID)) <= 7                                                                                                                               |
|Length of LBTESTCD                          |     6|      6|     0|   0|FALSE |FALSE   |nchar(as.character(LBTESTCD)) <= 7                                                                                                                              |
|LBTESTCD is mandatory                       |     6|      6|     0|   0|FALSE |FALSE   |!is.na(LBTESTCD)                                                                                                                                                |
|LBTESTCD should follow codelist CL.LBTESTCD |     6|      6|     0|   0|FALSE |FALSE   |as.character(LBTESTCD) %in% CT[CT[, "OID"] == "CL.LBTESTCD", "CodedValue"]                                                                                      |
|Length of LBTEST                            |     6|      6|     0|   0|FALSE |FALSE   |nchar(as.character(LBTEST)) <= 22                                                                                                                               |
|LBTEST is mandatory                         |     6|      6|     0|   0|FALSE |FALSE   |!is.na(LBTEST)                                                                                                                                                  |
|LBTEST should follow codelist CL.LBTEST     |     6|      6|     0|   0|FALSE |FALSE   |as.character(LBTEST) %in% CT[CT[, "OID"] == "CL.LBTEST", "CodedValue"]                                                                                          |
|Length of LBCAT                             |     6|      6|     0|   0|FALSE |FALSE   |nchar(as.character(LBCAT)) <= 10                                                                                                                                |
|Length of LBORRES                           |     6|      5|     1|   0|FALSE |FALSE   |nchar(as.character(LBORRES)) <= 8                                                                                                                               |
|Length of LBORRESU                          |     6|      6|     0|   0|FALSE |FALSE   |nchar(as.character(LBORRESU)) <= 7                                                                                                                              |
|LBORRESU should follow codelist CL.LBRESU   |     6|      6|     0|   0|FALSE |FALSE   |as.character(LBORRESU) %in% CT[CT[, "OID"] == "CL.LBRESU", "CodedValue"]                                                                                        |
|Length of LBORNRLO                          |     6|      6|     0|   0|FALSE |FALSE   |nchar(as.character(LBORNRLO)) <= 8                                                                                                                              |
|Length of LBORNRHI                          |     6|      6|     0|   0|FALSE |FALSE   |nchar(as.character(LBORNRHI)) <= 8                                                                                                                              |
|Length of LBSTRESC                          |     6|      6|     0|   0|FALSE |FALSE   |nchar(as.character(LBSTRESC)) <= 8                                                                                                                              |
|Length of LBSTRESN                          |     6|      6|     0|   0|FALSE |FALSE   |nchar(as.character(LBSTRESN)) <= 5                                                                                                                              |
|LBSTRESN should be float                    |     6|      6|     0|   0|FALSE |FALSE   |(regexpr("^[0-9.+-eE]+$", as.character(LBSTRESN)) == 1) & !is.na(as.numeric(LBSTRESN))                                                                          |
|Length of LBSTRESU                          |     6|      6|     0|   0|FALSE |FALSE   |nchar(as.character(LBSTRESU)) <= 7                                                                                                                              |
|Length of LBSTNRLO                          |     6|      6|     0|   0|FALSE |FALSE   |nchar(as.character(LBSTNRLO)) <= 4                                                                                                                              |
|LBSTNRLO should be float                    |     6|      6|     0|   0|FALSE |FALSE   |(regexpr("^[0-9.+-eE]+$", as.character(LBSTNRLO)) == 1) & !is.na(as.numeric(LBSTNRLO))                                                                          |
|Length of LBSTNRHI                          |     6|      6|     0|   0|FALSE |FALSE   |nchar(as.character(LBSTNRHI)) <= 4                                                                                                                              |
|LBSTNRHI should be float                    |     6|      6|     0|   0|FALSE |FALSE   |(regexpr("^[0-9.+-eE]+$", as.character(LBSTNRHI)) == 1) & !is.na(as.numeric(LBSTNRHI))                                                                          |
|Length of LBSTNRC                           |     0|      0|     0|   0|TRUE  |FALSE   |nchar(as.character(LBSTNRC)) <= 19                                                                                                                              |
|Length of LBNRIND                           |     6|      6|     0|   0|FALSE |FALSE   |nchar(as.character(LBNRIND)) <= 20                                                                                                                              |
|LBNRIND should follow codelist CL.NRIND     |     6|      0|     6|   0|FALSE |FALSE   |as.character(LBNRIND) %in% CT[CT[, "OID"] == "CL.NRIND", "CodedValue"]                                                                                          |
|Length of LBSPEC                            |     6|      6|     0|   0|FALSE |FALSE   |nchar(as.character(LBSPEC)) <= 5                                                                                                                                |
|LBSPEC should follow codelist CL.SPECTYPE   |     6|      0|     6|   0|FALSE |FALSE   |as.character(LBSPEC) %in% CT[CT[, "OID"] == "CL.SPECTYPE", "CodedValue"]                                                                                        |
|Length of LBMETHOD                          |     0|      0|     0|   0|TRUE  |FALSE   |nchar(as.character(LBMETHOD)) <= 8                                                                                                                              |
|LBMETHOD should follow codelist CL.METHOD   |     0|      0|     0|   0|TRUE  |FALSE   |as.character(LBMETHOD) %in% CT[CT[, "OID"] == "CL.METHOD", "CodedValue"]                                                                                        |
|Length of LBBLFL                            |     6|      3|     0|   3|FALSE |FALSE   |nchar(as.character(LBBLFL)) <= 1                                                                                                                                |
|LBBLFL should follow codelist CL.NY         |     6|      0|     6|   0|FALSE |FALSE   |as.character(LBBLFL) %in% CT[CT[, "OID"] == "CL.NY", "CodedValue"]                                                                                              |
|Length of LBFAST                            |     6|      6|     0|   0|FALSE |FALSE   |nchar(as.character(LBFAST)) <= 1                                                                                                                                |
|LBFAST should follow codelist CL.NY         |     6|      0|     6|   0|FALSE |FALSE   |as.character(LBFAST) %in% CT[CT[, "OID"] == "CL.NY", "CodedValue"]                                                                                              |
|Length of VISITNUM                          |     6|      6|     0|   0|FALSE |FALSE   |nchar(as.character(VISITNUM)) <= 2                                                                                                                              |
|VISITNUM should be integer                  |     6|      6|     0|   0|FALSE |FALSE   |regexpr("^[0-9-]+$", as.character(VISITNUM)) == 1                                                                                                               |
|Length of VISIT                             |     6|      6|     0|   0|FALSE |FALSE   |nchar(as.character(VISIT)) <= 7                                                                                                                                 |
|Length of VISITDY                           |     6|      6|     0|   0|FALSE |FALSE   |nchar(as.character(VISITDY)) <= 3                                                                                                                               |
|VISITDY should be integer                   |     6|      6|     0|   0|FALSE |FALSE   |regexpr("^[0-9-]+$", as.character(VISITDY)) == 1                                                                                                                |
|Length of LBDY                              |     6|      6|     0|   0|FALSE |FALSE   |nchar(as.character(LBDY)) <= 3                                                                                                                                  |
|LBDY should be integer                      |     6|      6|     0|   0|FALSE |FALSE   |regexpr("^[0-9-]+$", as.character(LBDY)) == 1                                                                                                                   |
|Length of BILI(LBORRES)                     |     6|      5|     1|   0|FALSE |FALSE   |(!(LBTESTCD == "BILI" & LBCAT == "CHEMISTRY" & LBSPEC == "BLOOD")) &#124; nchar(as.character(LBORRES)) <= 3                                                     |
|BILI(LBORRES) should be float               |     6|      5|     1|   0|FALSE |TRUE    |(!(LBTESTCD == "BILI" & LBCAT == "CHEMISTRY" & LBSPEC == "BLOOD")) &#124; (regexpr("^[0-9.+-eE]+$", as.character(LBORRES)) == 1) & !is.na(as.numeric(LBORRES))  |
|Length of BUN(LBORRES)                      |     6|      6|     0|   0|FALSE |FALSE   |(!(LBTESTCD == "BUN" & LBCAT == "CHEMISTRY" & LBSPEC == "BLOOD")) &#124; nchar(as.character(LBORRES)) <= 4                                                      |
|BUN(LBORRES) should be float                |     6|      6|     0|   0|FALSE |TRUE    |(!(LBTESTCD == "BUN" & LBCAT == "CHEMISTRY" & LBSPEC == "BLOOD")) &#124; (regexpr("^[0-9.+-eE]+$", as.character(LBORRES)) == 1) & !is.na(as.numeric(LBORRES))   |
|Length of GLUC(LBORRES)                     |     6|      6|     0|   0|FALSE |FALSE   |(!(LBTESTCD == "GLUC" & LBCAT == "CHEMISTRY" & LBSPEC == "BLOOD")) &#124; nchar(as.character(LBORRES)) <= 3                                                     |
|GLUC(LBORRES) should be float               |     6|      6|     0|   0|FALSE |TRUE    |(!(LBTESTCD == "GLUC" & LBCAT == "CHEMISTRY" & LBSPEC == "BLOOD")) &#124; (regexpr("^[0-9.+-eE]+$", as.character(LBORRES)) == 1) & !is.na(as.numeric(LBORRES))  |
|Length of GLUC(LBORRES)                     |     0|      0|     0|   0|TRUE  |FALSE   |(!(LBTESTCD == "GLUC" & LBCAT == "URINALYSIS" & LBSPEC == "URINE" & LBMETHOD == "DIPSTICK")) &#124; nchar(as.character(LBORRES)) <= 8                           |
|Length of GLUC(LBORRES)                     |     0|      0|     0|   0|TRUE  |FALSE   |(!(LBTESTCD == "GLUC" & LBCAT == "URINALYSIS" & LBSPEC == "URINE" & LBMETHOD == "QUANT")) &#124; nchar(as.character(LBORRES)) <= 8                              |
|Length of HCT(LBORRES)                      |     6|      6|     0|   0|FALSE |FALSE   |(!(LBTESTCD == "HCT" & LBCAT == "HEMATOLOGY" & LBSPEC == "BLOOD")) &#124; nchar(as.character(LBORRES)) <= 4                                                     |
|HCT(LBORRES) should be float                |     6|      6|     0|   0|FALSE |TRUE    |(!(LBTESTCD == "HCT" & LBCAT == "HEMATOLOGY" & LBSPEC == "BLOOD")) &#124; (regexpr("^[0-9.+-eE]+$", as.character(LBORRES)) == 1) & !is.na(as.numeric(LBORRES))  |
|Length of HGB(LBORRES)                      |     6|      6|     0|   0|FALSE |FALSE   |(!(LBTESTCD == "HGB" & LBCAT == "HEMATOLOGY" & LBSPEC == "BLOOD")) &#124; nchar(as.character(LBORRES)) <= 4                                                     |
|HGB(LBORRES) should be float                |     6|      6|     0|   0|FALSE |TRUE    |(!(LBTESTCD == "HGB" & LBCAT == "HEMATOLOGY" & LBSPEC == "BLOOD")) &#124; (regexpr("^[0-9.+-eE]+$", as.character(LBORRES)) == 1) & !is.na(as.numeric(LBORRES))  |
|Length of LYM(LBORRES)                      |     6|      6|     0|   0|FALSE |FALSE   |(!(LBTESTCD == "LYM" & LBCAT == "HEMATOLOGY" & LBSPEC == "BLOOD")) &#124; nchar(as.character(LBORRES)) <= 4                                                     |
|LYM(LBORRES) should be float                |     6|      6|     0|   0|FALSE |TRUE    |(!(LBTESTCD == "LYM" & LBCAT == "HEMATOLOGY" & LBSPEC == "BLOOD")) &#124; (regexpr("^[0-9.+-eE]+$", as.character(LBORRES)) == 1) & !is.na(as.numeric(LBORRES))  |
|Length of OCCBLD(LBORRES)                   |     6|      6|     0|   0|FALSE |FALSE   |(!(LBTESTCD == "OCCBLD" & LBCAT == "URINALYSIS" & LBSPEC == "URINE")) &#124; nchar(as.character(LBORRES)) <= 8                                                  |
|Length of PH(LBORRES)                       |     6|      6|     0|   0|FALSE |FALSE   |(!(LBTESTCD == "PH" & LBCAT == "URINALYSIS" & LBSPEC == "URINE")) &#124; nchar(as.character(LBORRES)) <= 3                                                      |
|PH(LBORRES) should be float                 |     6|      6|     0|   0|FALSE |TRUE    |(!(LBTESTCD == "PH" & LBCAT == "URINALYSIS" & LBSPEC == "URINE")) &#124; (regexpr("^[0-9.+-eE]+$", as.character(LBORRES)) == 1) & !is.na(as.numeric(LBORRES))   |
|Length of VITB12(LBORRES)                   |     6|      6|     0|   0|FALSE |FALSE   |(!(LBTESTCD == "VITB12" & LBCAT == "CHEMISTRY" & LBSPEC == "SERUM")) &#124; nchar(as.character(LBORRES)) <= 3                                                   |
|VITB12(LBORRES) should be integer           |     6|      6|     0|   0|FALSE |FALSE   |(!(LBTESTCD == "VITB12" & LBCAT == "CHEMISTRY" & LBSPEC == "SERUM")) &#124; regexpr("^[0-9-]+$", as.character(LBORRES)) == 1                                    |
|Length of VITB9(LBORRES)                    |     6|      6|     0|   0|FALSE |FALSE   |(!(LBTESTCD == "VITB9" & LBCAT == "CHEMISTRY" & LBSPEC == "BLOOD")) &#124; nchar(as.character(LBORRES)) <= 5                                                    |
|VITB9(LBORRES) should be float              |     6|      6|     0|   0|FALSE |TRUE    |(!(LBTESTCD == "VITB9" & LBCAT == "CHEMISTRY" & LBSPEC == "BLOOD")) &#124; (regexpr("^[0-9.+-eE]+$", as.character(LBORRES)) == 1) & !is.na(as.numeric(LBORRES)) |

