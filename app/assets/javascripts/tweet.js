// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

$(document).on("click", "#add_keyword", function () {
	var party = $("input[name=party]:checked").val()
	$.post("tweet/addKeyword?party="+ party +"&_ts="+(new Date().getTime()), { keyword: $("#new-keyword").val() }, function (response) {
		window.location = "/";
	});
});

$(document).on("click", "#delete_keyword", function () {
	$.ajax({
	    url: "tweet/deleteKeyword?_ts="+(new Date().getTime()),
	    type: 'DELETE',
	    data: { id: $("#keyword-list option:selected").val() },
	    beforeSend: function( xhr ) {
	    	$("#status").removeClass().addClass("label label-default");
	    	$("#status").html("Deleting Keyword");
		},
	    success: function(result) {
	    	$("#status").removeClass().addClass("label label-success");
			$("#status").html("Success");
			window.location = "/";
	    },
	    failure: function(xhr) {
	    	$("#status").removeClass().addClass("label label-danger");
	    	$("#status").html("Failed");
	    }
	});
});

$(document).on("click", "#refresh_tweets", function () {
	var count = $("#get-count").val();
	if(count == '' || count == null) {
		count = 1000; //default count is 1000
	}

	$.ajax({
	    url: "tweet/getTweets?count="+ count +"&_ts="+(new Date().getTime()),
	    type: 'GET',
	    data: { id: $("#keyword-list option:selected").val() },
	    beforeSend: function( xhr ) {
	    	$("#status").removeClass().addClass("label label-default");
	    	$("#status").html("Loading");
		},
	    success: function(result) {
	    	$("#tweets").html("");
			$("#tweets").html(result);
			$("#tweet-count").html($("#tweets-list li").length);

			if($("#tweets-list li").length == 0) {
				$("#status").removeClass().addClass("label label-info");
				$("#status").html("No Data. Check your keywords.");
			} else {
				$("#status").removeClass().addClass("label label-success");
				$("#status").html("Success");
			}	
	    },
	    failure: function(xhr) {
	    	$("#status").removeClass().addClass("label label-danger");
	    	$("#status").html("Failed");
	    }
	});
});

$(document).on("click", "#get10", function () {

	$.ajax({
	    url: "tweet/get10Tweets?_ts="+(new Date().getTime()),
	    type: 'GET',
	    beforeSend: function( xhr ) {
	    	$("#status").removeClass().addClass("label label-default");
	    	$("#status").html("Loading 100");
		},
	    success: function(result) {
	    	$("#tweets").html("");
			
			$("#tweets").append("<ul id='tweets-list' class='list-group'>");
			for (var i = 0; i < result.length; i++) {
				$("#tweets").append("<li class='list-group-item'>"+ result[i]["text"] +"</li>");
			}
			$("#tweets").append("</ul>");

			$("#tweet-count").html(result.length);
			$("#status").removeClass().addClass("label label-success");
			$("#status").html("Success");
		
	    },
	    failure: function(xhr) {
	    	$("#status").removeClass().addClass("label label-danger");
	    	$("#status").html("Failed");
	    }
	});
});

$(document).on("click", "#reset_db", function () {

	$.ajax({
	    url: "tweet/resetDB?_ts="+(new Date().getTime()),
	    type: 'DELETE',
	    beforeSend: function( xhr ) {
	    	$("#status").removeClass().addClass("label label-default");
	    	$("#status").html("Resetting Database");
		},
	    success: function(result) {
			$("#status").removeClass().addClass("label label-success");
			$("#status").html("Success");
			window.location = "/";
	    },
	    failure: function(xhr) {
	    	$("#status").removeClass().addClass("label label-danger");
	    	$("#status").html("Failed");
	    }
	});
}); 

$(document).on("click", "#delete_tweets", function () {

	$.ajax({
	    url: "tweet/deleteAllTweets?_ts="+(new Date().getTime()),
	    type: 'DELETE',
	    beforeSend: function( xhr ) {
	    	$("#status").removeClass().addClass("label label-default");
	    	$("#status").html("Deleting all Tweets");
		},
	    success: function(result) {
			$("#status").removeClass().addClass("label label-success");
			$("#status").html("Success");
			window.location = "/";
	    },
	    failure: function(xhr) {
	    	$("#status").removeClass().addClass("label label-danger");
	    	$("#status").html("Failed");
	    }
	});
});

$(document).on("click", "#analyze", function () {

	$.ajax({
	    url: "tweet/getSentiments?_ts="+(new Date().getTime()),
	    type: 'GET',
	    beforeSend: function( xhr ) {
	    	$("#status").removeClass().addClass("label label-default");
	    	$("#status").html("Loading Charts");
		},
	    success: function(data) {

	    	var $deferred1 = new $.Deferred();
	    	var $deferred2 = new $.Deferred();

	    	$.when( getKeywords($deferred1), getDimensions($deferred2) ).done(function( unique_keywords, unique_categories ) {
	    		console.log(unique_keywords);
	    		console.log(unique_categories);
				var series_data = [];
				for (var i = 0; i < unique_keywords.length; i++) {
					series_data.push({
						"name": unique_keywords[i],
			        	"data": [],
			        	"pointPlacement": 'on'
			        });
				}

				for (var i = 0; i < data.length; i++) {
					for (var j = 0; j < series_data.length; j++) {
						if(data[i]["keyword"] == series_data[j]["name"]) {
							series_data[j]["data"].push(data[i]["tweet_count"]);
						} 
					}
				}

				console.log(series_data);

				$('#chart1-container').highcharts({
			        chart: {
			            polar: true,
			            type: 'line'
			        },
			        title: {
			            text: 'Sentiment Analysis',
			            x: -80
			        },
			        pane: {
			            size: '80%'
			        },
			        xAxis: {
			            categories: unique_categories,
			            tickmarkPlacement: 'on',
			            lineWidth: 0
			        },
			        yAxis: {
			            gridLineInterpolation: 'polygon',
			            lineWidth: 0,
			            min: 0
			        },
			        tooltip: {
			            shared: true,
			            pointFormat: '<span style="color:{series.color}">{series.name}: <b>{point.y:,.0f} tweets</b><br/>'
			        },
			        legend: {
			            align: 'right',
			            verticalAlign: 'top',
			            y: 70,
			            layout: 'vertical'
			        },
			        series: series_data
			    });

	    	});

			$("#status").removeClass().addClass("label label-success");
			$("#status").html("Success");
	    },
	    failure: function(xhr) {
	    	$("#status").removeClass().addClass("label label-danger");
	    	$("#status").html("Failed");
	    }
	});

	var getKeywords = function ($deferred1) {
		var party = $("input[name=party]:checked").val();
		$.ajax({
		    url: "tweet/getKeywords?party="+party+"&_ts="+(new Date().getTime()),
		    type: 'GET',
		    success: function(xhr) {
		    	var keywords = [];
		    	var data;
		    	if(typeof xhr == "object") {
		    		data = [].concat(xhr);
		    	} else {
		    		data = xhr;
		    	}
		    	for (var i = 0; i < data.length; i++) {
		    		keywords.push(data[i]["name"]);
		    	}

				$deferred1.resolve(keywords);
		    },
		    failure: function(xhr) {
		    	$deferred1.reject(null);
		    }
		});

		return $deferred1.promise();
	}

	var getDimensions =	function ($deferred2) {
		$.ajax({
		    url: "tweet/getDimensions?_ts="+(new Date().getTime()),
		    type: 'GET',
		    success: function(xhr) {
		    	var dimensions = [];
		    	var data;
		    	if(typeof xhr == "object") {
		    		data = [].concat(xhr);
		    	} else {
		    		data = xhr;
		    	}
		    	for (var i = 0; i < data.length; i++) {
		    		dimensions.push(data[i]["dimension"]);
		    	}

				$deferred2.resolve(dimensions);
		    },
		    failure: function(xhr) {
		    	$deferred2.reject(null);
		    }
		});

		return $deferred2.promise();
	}

});

$(document).on("click", "#democratic_party", function() {
	clearKeywords()
	getMainKeywords();
});

$(document).on("click", "#republican_party", function() {
	clearKeywords();
	getMainKeywords();
});

var clearKeywords = function () {
	$("#keyword-list").html("");
}

var getMainKeywords = function() {
	var party = $("input[name=party]:checked").val();
		$.ajax({
		    url: "tweet/getKeywords?party="+party+"&_ts="+(new Date().getTime()),
		    type: 'GET',
		    success: function(response) {
		    	var data;
		    	if(typeof response == "object") {
		    		data = [].concat(response);
		    	} else {
		    		data = response;
		    	}

		    	for (var i = 0; i < data.length; i++) {
		    		$("#keyword-list")
		    		.append("<option value="+ data[i]["id"] +" class='list-group-item'>"+ data[i]["name"]+"</option>");						
		    	}
		    	$("#status").removeClass().addClass("label label-success");
				$("#status").html("Success");
		    },
		    failure: function(error) {
		    	$("#status").removeClass().addClass("label label-success");
				$("#status").html("No Keywords");
		    }
		});	
}

$(document).on("click", "#train", function() {

	$.ajax({
		url: "tweet/train_classifier?_ts="+(new Date().getTime()),
		type: 'GET',
		beforeSend: function( xhr ) {
	    	$("#status").removeClass().addClass("label label-default");
	    	$("#status").html("Training Classifier...");
		},
	    success: function(xhr) {
		   	$("#status").removeClass().addClass("label label-success");
			$("#status").html("Success");
		},
	    failure: function(xhr) {
	    	$("#status").removeClass().addClass("label label-danger");
	    	$("#status").html("Failed");
	    }
	});
});

$(document).on("click", "#test", function() {
	var key = $("#test-key").val();
	if(key == '' || key == null) {
		alert("Please enter test keyword");
		return;
	}
	var count = $("#test-count").val();
	if(count == '' || count == null) {
		count = 10;
	}

	$.ajax({
		url: "tweet/test_classifier?_ts="+(new Date().getTime()),
		type: 'POST',
		data: { key: key, count: count },
		beforeSend: function( xhr ) {
	    	$("#status").removeClass().addClass("label label-default");
	    	$("#status").html("Testing Classifier...");
		},
	    success: function(xhr) {
		   	$("#status").removeClass().addClass("label label-success");
			$("#status").html("Success");
		},
	    failure: function(xhr) {
	    	$("#status").removeClass().addClass("label label-danger");
	    	$("#status").html("Failed");
	    }
	});
});

$(document).on("click", "#flip", function() {
	$("#chart").toggle();
	$("#tabular-data").toggle();
});

var total_data = 0;
var loadTableData = function () {

	$.ajax({
		url: "tweet/getDemocratsList?_ts="+(new Date().getTime()),
		type: 'GET',
		beforeSend: function( xhr ) {
	    	$("#status").removeClass().addClass("label label-default");
	    	$("#status").html("Loading Democrats Data");
		},
	    success: function(xhr) {

	    	$("#democrat_count").html(xhr.length);

	    	total_data += xhr.length;

	    	$("#total_data").html(total_data);

	    	for (var i = 0; i < xhr.length; i++) {
	    		$("#democrats_data").append("<tr><td>"+ xhr[i]["screen_name"] +"</td></tr>");
	    	}
	    	
		   	$("#status").removeClass().addClass("label label-success");
			$("#status").html("Success");
		},
	    failure: function(xhr) {
	    	$("#status").removeClass().addClass("label label-danger");
	    	$("#status").html("Failed");
	    }
	});

	$.ajax({
		url: "tweet/getRepublicanList?_ts="+(new Date().getTime()),
		type: 'GET',
		beforeSend: function( xhr ) {
	    	$("#status").removeClass().addClass("label label-default");
	    	$("#status").html("Loading Republicans Data");
		},
	    success: function(xhr) {

	    	$("#republican_count").html(xhr.length);

	    	total_data += xhr.length;

	    	$("#total_data").html(total_data);

	    	for (var i = 0; i < xhr.length; i++) {
	    		$("#republicans_data").append("<tr><td>"+ xhr[i]["screen_name"] +"</td></tr>");
	    	}

		   	$("#status").removeClass().addClass("label label-success");
			$("#status").html("Success");
		},
	    failure: function(xhr) {
	    	$("#status").removeClass().addClass("label label-danger");
	    	$("#status").html("Failed");
	    }
	});
}

$(document).on("click", "#getTableData", function () {
	loadTableData();
});
