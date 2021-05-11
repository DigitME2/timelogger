/*
Generic table generator, suitable for all pages in this interface.

The generator requires the following:

1.  The name of the table

2.  A JSON object containing the data to tabulate. This is required to be
    an array of dictionaries, where each element of the array represents one
    row of the table, i.e.:
    
    data = [
        {
            "item1":value1,
            "item2":value2,
            "item3":value3,
        },
        {
            "item1":value4,
            "item2":value5,
            "item3":value6,
        },
        ...
        {
            "item1":valueX,
            "item2":valueY,
            "item3":valueZ,
        }
    ];
    
3.  A data structure that provides format and behaviour parameters for rows
    and columns.
    
    Each row as a whole may have a link associated with it, such
    that clicking or tapping any part of the row takes the user to the
    associated page. A parameter name and value can be provided to be sent
    with the request. Such a link is assumed to be a GET request.
    
    Each column is defined by a mandatory headingName and optional dataName.
    These values are used to generate the table header and pick out the data
    to list from the current row.
    
    Optionally, a link may also be defined. Links may be defined directly, or
    by specifying the name of the field in the data containing the URL.
	If a link is set to "" then a blank cell will be output.
    Additional parameters may be used specify the behaviour when the cell is 
    clicked. A parameter label dataName may be specified, to be sent to the 
    server. If download is defined as true, the generated function will produce
    a download link to the defined file, listed in the data array as 'link'.
    The text of the link may be defined by 'linkText'.
    
    A pointer to a function may be defined, to be attached to the the onClick
    event for a call. A data parameter may be specified to attach to the cell
    with JQuery's .data() function. The name of this data in the DataToTabulate
    is defined by 'functionParamDataName'. The actual event to run the function
    will be the onClick event of a button that is generated in the cell.
	
	A pointer to a function may be provided to specify the class of the table
	row. This is intended to allow rows to be highlighted. This function must
	accept a single parameter, typically a row of table data.
    
    The TableStructure variable used to define the table looks something like
    this:
    
    TableStructure = {
        "rows":{
            "linksToPage":<true|false|undefined>
            "link":<URL|undefined>
            "linkParamLabel":<string|undefined>
            "linkParamDataName":<string|undefined>
			"classDeciderFunction":<function reference|undefined>
        },
        "columns":{
            [
                "headingName":<string>,
                "dataName":<string|undefined>,
                "link":<URL|undefined>,
                "linkDataName":<string|undefined>
                "linkText":<string|undefined>
                "linkParamLabel":<string|undefined>
                "linkParamDataName":<string|undefined>
                "linkIsDownload":<true|false|undefined>
                "functionToRun":<pointer|undefined>
                "functionParamDataName":<string|undefined>
                "functionButtonText":<string|undefined>
            ],
            ...
            [
                <as above>
            ]
        }
    };
*/

function generateTable(TableId, DataToTabulate, TableStructure){
    var table = $('<table/>').attr('id',TableId);
    var tableBody = $('<tbody/>');
    
    var rowDefinitions = TableStructure["rows"];
    var columnDefinitions = TableStructure["columns"];
        
    
    var header = generateHeader(columnDefinitions)
    table.append(header);
    
    for(var i = 0; i < DataToTabulate.length; i++){
        var rowData = DataToTabulate[i];
        
        var row = generateRow(rowData, columnDefinitions, i);
        
        if("linksToPage" in rowDefinitions && rowDefinitions["linksToPage"]){
            var url = rowDefinitions["link"];
            if("linkParamLabel" in rowDefinitions){
				if(rowData[rowDefinitions["linkParamDataName"]] != "" && rowData[rowDefinitions["linkParamDataName"]] != null)
                	url = url + "?" + rowDefinitions["linkParamLabel"] + "=" + rowData[rowDefinitions["linkParamDataName"]];
				else
					url = "";
            }

			if(url != "")
			{
		        row.data("linkUrl", url);
		        row.on("click",function(){
		            //window.location = $(this).data("linkUrl");
					var win = window.open($(this).data("linkUrl"),"_blank");
		        });
			}
        }
		
		if("classDeciderFunction" in rowDefinitions){
			var rowClass = rowDefinitions.classDeciderFunction(rowData);
			row.addClass(rowClass);
		}
        
        tableBody.append(row);
    }
    table.append(tableBody);
    
    return table;
}

function generateHeader(ColumnDefinitions){
    var tableHeader = $('<thead/>');
    var tableHeaderRow = $('<tr/>');
    
    for(var i = 0; i < ColumnDefinitions.length; i++){
        var columnName = ColumnDefinitions[i].headingName;
        var headerElement = $('<td/>').html(columnName);
        tableHeaderRow.append(headerElement);
    }
    
    tableHeader.append(tableHeaderRow);
    
    return tableHeader;
}

function generateRow(DataRow, RowStructure, rowNum){
    var tableRow = $('<tr/>');

	for(var i = 0; i < RowStructure.length; i++){
        var cellDefinition = RowStructure[i];
        
        // select element type based on parameters
        if("functionToRun" in cellDefinition)
		{
			buttonId = cellDefinition["dataName"] + "_btn_" + rowNum.toString();
			buttonClass = cellDefinition["dataName"] + "_table_buttons"
            var tableElement = generateFunctionCell(DataRow, cellDefinition, buttonId, buttonClass);
		}        
		else if("linkIsDownload" in cellDefinition && cellDefinition["linkIsDownload"])
            var tableElement = generateDownloadCell(DataRow, cellDefinition);
        else if("link" in cellDefinition || "linkDataName" in cellDefinition)
            var tableElement = generateLinkCell(DataRow, cellDefinition);
        else
            var tableElement = generatePlainCell(DataRow, cellDefinition);
        
        tableRow.append(tableElement);
    }
    return tableRow;
}
        
function generatePlainCell(DataRow, CellDefinition){
    var tableCell = $('<td/>');
    var data = DataRow[CellDefinition["dataName"]];
    tableCell.html(data);
    return tableCell;
}
        
function generateLinkCell(DataRow, CellDefinition){
    // generates a cell that links to a page
    var tableCell = $('<td/>');
    var anchor = $('<a/>');
    
    if("link" in CellDefinition)
        var url = CellDefinition["link"];
    else if("linkDataName" in CellDefinition)
        var url = DataRow[CellDefinition["linkDataName"]];
    else
        console.log("URL undefined. No link or linkDataName listed");

	if(url != "")
	{    
		if('linkParamLabel' in CellDefinition){
		    url = url + "?" + CellDefinition['linkParamLabel'] + "=" + DataRow[CellDefinition['linkParamDataName']]
		}
		
		anchor.attr("href",url).html(CellDefinition["linkText"]);
		tableCell.append(anchor);
	}
	else
	{
		tableCell = generatePlainCell(DataRow, {"dataName":""})
	}

	tableCell.on("click", function(event){
		event.cancelBubble=true;if(event.stopPropagation) event.stopPropagation();
	});
    
    return tableCell;
}
        
function generateDownloadCell(DataRow, CellDefinition){
    var tableCell = generateLinkCell(DataRow, CellDefinition);
    
    tableCell.children("a").attr("download", "");
    
    return tableCell;
}
        
function generateFunctionCell(DataRow, CellDefinition, id="button", buttonClass=""){
    var tableCell = $('<td/>');

    var button = $('<input/>')
    .attr('id', id)
    .attr('type','button')
    .attr("value",CellDefinition["functionButtonText"]);

	if (buttonClass != "")
		button.attr('class', buttonClass)
    
    if('functionParamDataName' in CellDefinition){
        param = DataRow[CellDefinition["functionParamDataName"]];
    
        button.on("click", null, {"param":param}, function(event){
           CellDefinition["functionToRun"](event.data.param);
        });
    }
    else{
        button.on("click", function(event){
           CellDefinition["functionToRun"]();
        });
    }
    
    tableCell.append(button);

	tableCell.on("click", function(event){
		event.cancelBubble=true;if(event.stopPropagation) event.stopPropagation();
	});
    
    return tableCell;
}
