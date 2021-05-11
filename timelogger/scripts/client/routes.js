function loadInitialRoutesData(){
	$.ajax({
		url:"../scripts/server/routes.php",
		type:"GET",
		dataTtype:"text",
		data:{
			"request":"getInitialData"
		},
		success:function(result){
			console.log(result);
			var resultJson = $.parseJSON(result);
			
			if(resultJson.status != "success"){
				$("#spanFeedback").empty().html(resultJson.result);
			}
			else
			{
				var stationNames = resultJson.result.stationNames;
				$("#selectStationNames").empty();
				for(var i = 0; i < stationNames.length; i++){
					var newOption = $("<option>")
						.text(stationNames[i])
						.attr("value", stationNames[i]);
					$("#selectStationNames").append(newOption);
				}
				
				var routeNames = resultJson.result.routeNames;
				$("#selectExistingRoute").empty();
				var placeHolder = $("<option>")
						.text("Select a route...")
						.attr("value", "");
				$("#selectExistingRoute").append(placeHolder);
				for(var i = 0; i < routeNames.length; i++){
					var newOption = $("<option>")
						.text(routeNames[i])
						.attr("value", routeNames[i]);
					$("#selectExistingRoute").append(newOption);
				}
			}
		}
	});
}

function loadRoute(){
	var routeName = $("#selectExistingRoute").val();

	if(routeName != "noSelection"){	
		$.ajax({
		url:"../scripts/server/routes.php",
		type:"GET",
		dataTtype:"text",
		data:{
			"request":"getRoute",
			"routeName":routeName
		},
		success:function(result){
			console.log(result);
			var resultJson = $.parseJSON(result);
			
			if(resultJson.status != "success"){
				$("#spanFeedback").empty().html(resultJson.result);
			}
			else
			{
				$("#textboxRouteName").val(routeName);
				
				var routeParts = resultJson.result.split(",");
				
				$("#textboxRouteDesc").val("");
				for(var i = 0; i < routeParts.length - 1; i++){
					$("#textboxRouteDesc").val(
						$("#textboxRouteDesc").val() + routeParts[i] + "\n"
					);
				}
				// add the last line with no trailing newline
				$("#textboxRouteDesc").val(
						$("#textboxRouteDesc").val() + routeParts[routeParts.length-1]
				);
			}
		}
	});
	}
}

function appendStationName(){
	if($("#textboxRouteDesc").val().length > 0)
		$("#textboxRouteDesc").val($("#textboxRouteDesc").val() + "\n" + $("#selectStationNames").val());
	else
		$("#textboxRouteDesc").val($("#selectStationNames").val());
}

function removeLastStationName(){
	var routeParts = $("#textboxRouteDesc").val().split("\n");
				
	$("#textboxRouteDesc").val("");
	
	if(routeParts.length > 1){
		for(var i = 0; i < routeParts.length - 2; i++){
			$("#textboxRouteDesc").val(
				$("#textboxRouteDesc").val() + routeParts[i] + "\n"
			);
		}
		// add the last line with no trailing newline
		$("#textboxRouteDesc").val(
				$("#textboxRouteDesc").val() + routeParts[routeParts.length-2]
		);
	}
}

function saveRoute(){
	var routeDescription = $("#textboxRouteDesc").val().replace(/\n/g,",");
	var routeName = $("#textboxRouteName").val();
	
	if(routeName.length == 0 || routeDescription.length == 0){
		$("#spanFeedback").html("Please specify route name and description");
		setTimeout(function(){$("#spanFeedback").empty();},10000);
		return;
	}

	regexp = /^[a-z0-9_ ]+$/i;
	if(! regexp.test(routeName)){
		console.log("Route Name entered contains invalid chars. Stopping");
		$("#spanFeedback").empty().html("Route Name must only contain letters (a-z, A-Z), numbers (0-9) and underscores (_)");
		setTimeout(function(){$("#spanFeedback").empty();},10000);
		return;
	}

	if(routeName.length > 50){
		$("#spanFeedback").html("Please enter a route name of less than 50 characters");
		setTimeout(function(){$("#spanFeedback").empty();},10000);
		return;
	}
	
	$.ajax({
		url:"../scripts/server/routes.php",
		type:"GET",
		dataTtype:"text",
		data:{
			"request":"saveRoute",
			"routeName":routeName,
			"routeDescription":routeDescription
		},
		success:function(result){
			console.log(result);
			var resultJson = $.parseJSON(result);
			
			if(resultJson.status != "success"){
				$("#spanFeedback").empty().html(resultJson.result);
				console.log(resultJson.result);
			}else{
				$("#spanFeedback").empty().html("Route saved");
				console.log("Route saved");
			}
			setTimeout(function(){$("#spanFeedback").empty();},10000);
			loadInitialRoutesData();
		}
	});
}


function deleteRoute(){
	var routeName = $("#textboxRouteName").val();
	
	if(routeName.length > 0){
		if(confirm("Delete route " + routeName + "?")){
			$.ajax({
				url:"../scripts/server/routes.php",
				type:"GET",
				dataTtype:"text",
				data:{
					"request":"deleteRoute",
					"routeName":routeName
				},
				success:function(result){
					console.log(result);
					var resultJson = $.parseJSON(result);

					if(resultJson.status == "success"){
						$("#spanFeedback").empty().html("Route deleted");
						$("#textboxRouteName").val("");
						$("#textboxRouteDesc").val("");
					}else
						$("#spanFeedback").empty().html(resultJson.result);
					
					loadInitialRoutesData();
				}
			});
		}
	}
}

