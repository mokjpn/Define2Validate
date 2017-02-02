# Define2ValidateDemo

A [Shiny](https://shiny.rstudio.com)-based sample application of [Define2Validate](https://github.com/mokjpn/Define2Validate)


## Usage

You need a [Dataset-XML](https://www.cdisc.org/standards/foundational/dataset-xml) file and a [Define-XML](https://www.cdisc.org/standards/foundational/define-xml) that defines metadata for the dataset.

Since each dataset-xml file does not have information of which [SDTM](https://www.cdisc.org/standards/foundational/sdtm) domain the data belongs, users have to specify the domain of specified dataset-xml.

On the application, specify your Define-XML and corresponding Dataset-XML, then set the domain of the Dataset-XML, and press "Validate" button. This app will validate whether each record of the dataset is valid against the metadata defined in Define-XML. 

The result of validation will be displayed in the right pane, "Table" tab. For each rules, proportion of passed records will be displayed in "Figure" tab. If there are some records which fails to tests, failed rows are extracted in "Failed Records" tab.

To just test the functions, a set of example Define-XML and Dataset-XML files can be found in [CDISC's Dataset-XML release package](https://www.cdisc.org/standards/foundational/dataset-xml).

## "Table" tab

- rule

    Description of 'rules'. Each rule is a R expression converted from metadata defined in Define-XML.

- items

    Number of records checked.
    
- passes

    Number of records that passes the rule.

- fails

    Number of records that does not pass the rule.
- nNA

    Number of records that has NA(missing) value for the variable checked.

- error

    A logical (true or false) value. If true, there is a error when evaluating the rule. Typically, if there is no controlled terminology definition in your Define-XML file, it will be an error, because external controlled terminology file is not supported yet.

- warning

    A logical value that indicates whether there is any warning when evaluating the rule.

- expression

    Actual R expression used to validate records.

## If there is any "fails"...

Click the row in "Table" tab where there is one or more "fails". Then records with errors are automatically extracted and displayed in "Failed Records" tab.



  