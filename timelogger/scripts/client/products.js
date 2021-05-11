$(document).ready(function(){
    updateProductTable();
    $(".productInput").on('keyup', function(){
        var productId = $("#newProductId").val();
        
        var productIdCharsRemaining = 20 - productId.length;
        $("#newProductIdCounter").html(productIdCharsRemaining + "/20");
    });
    $(".productInput").trigger("keyup",null);

	$("#newProductId").keypress(function(e) {
		var keycode = (e.keycode ? e.keycode : e.which)
		if (keycode == 13){
			addNewProduct();
		}
	});	

	$("#newProductId").focus();

	$("#searchPhrase").keypress(function(e) {
		var keycode = (e.keycode ? e.keycode : e.which)
		if (keycode == 13){
			searchProducts();
		}
	});
});

function updateProductTable(){
    // get product data, ordered by selected option
    // generate table
    // drop old table and append new one
    
	var searchPhrase = $("#searchPhrase").val();
    
    $.ajax({
        url:"../scripts/server/products.php",
        type:"GET",
        dataType:"text",
        data:{
            "request":"getProductTableData",
            "searchPhrase":searchPhrase
        },
        success:function(result){
            console.log(result);
            resultJson = $.parseJSON(result);
            
            if(resultJson["status"] != "success"){
                console.log("Failed to update table: " + resultJson["result"]);
                $("#tablePlaceholder").html(resultJson["result"]);
            }
            else{
                var tableData = resultJson["result"];
                var tableStructure = {
                    "rows":{
                        "linksToPage":true,
						"link":"job_details_client.php",
						"linkParamLabel":"jobId",
						"linkParamDataName":"currentJobId"
                    },
                    "columns":[
                        {
                            "headingName":"Product ID",
                            "dataName":"productId"
                        },
			{
                            "headingName":"Current Job",
                            "dataName": "currentJobId"
                        },
                        {
                            "headingName":"QR Code",
                            "linkDataName":"pathToQrCode",
                            "linkIsDownload":true,
                            "linkText":"Download QR code"
                        },
                        {
                            "headingName":"Delete Product",
                            "functionToRun":deleteProduct,
                            "functionParamDataName":"productId",
                            "functionParamDataLabel":"productId",
                            "functionButtonText":"Delete Product"
                        }
                    ]
                };
                
                var table = generateTable("productTable", tableData, tableStructure);
                $("#existingProductsContainer").empty().append(table);
            }
        }
    });
}

function addNewProduct(){
    var productId = $("#newProductId").val();
    
    if(productId.length == 0){
        $("#addProductResponseField").html("Product ID must not be blank");
        return;
    }
    
    if(productId.length > 20){
        $("#addProductResponseField").html("Product ID must not be longer than 20 characters");
        return;
    }
	
	regexp = /^[a-z0-9_]+$/i;
	if(!regexp.test(productId)){
		$("#addProductResponseField").html("Product ID must only contain letters (a-z, A-Z), numbers (0-9) and underscores (_)");
		return;
	}
	
	if(productId.charAt(0) == ' '){
		$("#addProductResponseField").html("Product ID cannot start with a space.");
		return;
	}
    
    $.ajax({
        url:"../scripts/server/products.php",
        type:"GET",
        dataType:"text",
        data:{
            "request":"addProduct",
            "productId":productId
        },
        success:function(result){
	    console.log(result);
            resultJson = $.parseJSON(result);
            if(resultJson["status"] != "success")
                $("#addProductResponseField").html(resultJson["result"]);
            else{
                $("#addProductResponseField").html("Generating QR code. Please wait...");


				var a = $('<a/>')
                    .attr('href', resultJson["result"])
                    .attr('download', productId+"_qrcode.png")
                    .html('Click here to download product ID QR code');
                $("#addProductResponseField").empty().append(a);
                
                // at this point, a new user is present in the system, so update the display
                updateProductTable();
				
				//Empty new user input box
				$("#newProductId").val("");
                $("#newProductIdCounter").html("50/50");
            }
        }
    });
}

function deleteProduct(productId){
    // find nearest element with a productId attached to it
    // send a request to delete that user
    // refresh the table
    if(confirm("Are you sure you want to permantly delete product '" + productId + "'?\nThis will NOT affect any jobs that are for this product.")){
		console.log("Deleting product with ID " + productId);
		
		$.ajax({
		    url:"../scripts/server/products.php",
		    type:"GET",
		    dataType:"text",
		    data:{
		        "request":"deleteProduct",
		        "productId":productId
		    },
		    success:function(result){
			console.log(result);
		        updateProductTable();
		    }
		});
	}
}

function searchProducts(){
	$(".searchControl").attr("disabled", true);
	$("#productTable").empty().html("Searching. Please wait....");
	updateProductTable();
	$(".searchControl").attr("disabled", false);
}
