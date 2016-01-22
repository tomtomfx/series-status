<?php
	include '../userManagement.php';
	if (!$users->isloggedin())
	{
		header('Location: ../#', true, 302);
		die();
	}
?>
<!DOCTYPE html>
<html lang="en" xmlns="http://www.w3.org/1999/xhtml">
	<head>
		<meta charset="utf-8" />
		<meta http-equiv="cache-control" content="no-cache">
		<meta name="viewport" content="width=device-width, initial-scale=1">
		<link href="../bootstrap-3.3.6-dist/css/bootstrap.min.css" rel="stylesheet">
		<link href="../style_bootstrap.css" rel="stylesheet">
		<title>Statistics</title>
		<link rel="shortcut icon" href="favicon.ico">		
		<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.9.1/jquery.min.js"></script>		
		<script src="../bootstrap-3.3.6-dist/js/bootstrap.min.js"></script>
		<script type="text/javascript" src="../highchart/js/highcharts.js"></script>
		<script type="text/javascript" src="../highchart/js/modules/data.js"></script>
		<script type="text/javascript" src="../highchart/js/themes/tomtomfx.js"></script>
	</head>

	<body>
		<script type="text/javascript">
		$(function() {
			$(document).ready(function() {
				$.get('../highchart/episodesUnseen.csv', function(csv) {
		//			console.log( "Data Loaded: " + csv );
					var options = {
						chart: {
							renderTo: 'graph',
							type: 'line',
							zoomType: 'x'
						},
						title: {
							text: "Number of unseen episodes"
						},
						credits: {
							href: 'http://tomtomfx.dyndns.org/series',
							text: 'Powered by Tomtomfx'
						},
						xAxis: {
							title: {
								text: "Date"
							}
						},
						yAxis: {
							title: {
								text: "Number of episodes"
							}
						},
						data: {
							csv: csv
						}
					};
					console.log(options);
					var chart = new Highcharts.Chart(options);
				}, "text");
			});
		});		
		</script>
		<script type="text/javascript">
		$(function() {
			$(document).ready(function() {
				$.get('../highchart/episodes.csv', function(csv) {
		//			console.log( "Data Loaded: " + csv );
					var options = {
						chart: {
							renderTo: 'graph1',
							type: 'column',
							zoomType: 'x'
						},
						title: {
							text: "Episodes downloaded and seen"
						},
						credits: {
							href: 'http://tomtomfx.dyndns.org/series',
							text: 'Powered by Tomtomfx'
						},
						xAxis: {
							title: {
								text: "Date"
							}
						},
						yAxis: {
							title: {
								text: "Number of episodes"
							}
						},
						data: {
							csv: csv
						}
					};
					console.log(options);
					var chart = new Highcharts.Chart(options);
				}, "text");
			});
		});		
		</script>
		<script type="text/javascript">
		$(function() {
			$(document).ready(function() {
				$.get('../highchart/episodesMonthly.csv', function(csv) {
		//			console.log( "Data Loaded: " + csv );
					var options = {
						chart: {
							renderTo: 'graph2',
							type: 'column',
						},
						title: {
							text: "Episodes downloaded and seen per month"
						},
						credits: {
							href: 'http://tomtomfx.dyndns.org/series',
							text: 'Powered by Tomtomfx'
						},
						xAxis: {
							title: {
								text: "Date"
							}
						},
						yAxis: {
							title: {
								text: "Number of episodes"
							}
						},
						data: {
							csv: csv
						}
					};
					console.log(options);
					var chart = new Highcharts.Chart(options);
				}, "text");
			});
		});		
		</script>
		<script type="text/javascript">
		$(document).ready(function() {
			$.get('../highchart/episodesSeenMonthly.csv', function(csv) {
	//			console.log( "Data Loaded: " + csv );
				var options = {
					chart: {
						renderTo: 'graph3',
						type: 'column'
					},
					title: {
						text: "Number of episodes seen in the last month"
					},
					credits: {
						href: 'http://tomtomfx.dyndns.org/series',
						text: 'Powered by Tomtomfx'
					},
					xAxis: {
						title: {
							text: "Serie"
						}
					},
					yAxis: {
						title: {
							text: "Number of episodes"
						}
					},
					data: {
						csv: csv
					}
				};
				console.log(options);
				var chart = new Highcharts.Chart(options);
			}, "text");
		});
		</script>
		<script type="text/javascript">
		$(document).ready(function() {
			$.get('../highchart/episodesDelay.csv', function(csv) {
	//			console.log( "Data Loaded: " + csv );
				var options = {
					chart: {
						renderTo: 'graph4',
						type: 'column'
					},
					title: {
						text: "Mean watch delay per serie"
					},
					credits: {
						href: 'http://tomtomfx.dyndns.org/series',
						text: 'Powered by Tomtomfx'
					},
					xAxis: {
						title: {
							text: "Serie"
						}
					},
					yAxis: {
						title: {
							text: "Delay"
						}
					},
					data: {
						csv: csv
					}
				};
				console.log(options);
				var chart = new Highcharts.Chart(options);
			}, "text");
		});
		</script>

		<div class="container">
			<nav class="navbar navbar-default">
				<div class="navbar-header">
					<button type="button" class="navbar-toggle" 
						data-toggle="collapse" data-target="#menuCollapse">
						<span class="sr-only">Toggle navigation</span>
						<span class="icon-bar"></span>
						<span class="icon-bar"></span>
						<span class="icon-bar"></span>
					</button>
					<a class="navbar-brand" href="../#">Tomtomfx</a>
				</div>
				<div class="collapse navbar-collapse" id="menuCollapse">
					<ul class="nav navbar-nav">
						<li><a href="./series.php" id="navig"><span class="glyphicon glyphicon-film"></span> Series</a></li>
						<li class="active"><a href="./statistics.php" id="navig"><span class="glyphicon glyphicon-stats"></span> Statistics</a></li>
						<li><a href="../#" id="navig"><span class="glyphicon glyphicon-camera"></span> Photos</a></li>
					</ul>
					<div class="nav navbar-nav navbar-right">
						<li class="dropdown-toggle" data-toggle="dropdown" id="navLogin">
							<a href="#" id="navig"><span class="glyphicon glyphicon-user"></span> <?php echo $_SESSION['username']?><span class="caret"></span></a>
						</li>
						<ul class="dropdown-menu">
							<li><a href="../logout.php"><span class="glyphicon glyphicon-log-out"></span> Log out</a></li>
						</ul>
					</div>
				</div>
			</nav>
			<header class="page-header" id="title">
					<section class="row">
						<div class="col-xs-12"><h2>Series status<small> | Statistics</small></h2></div>
					</section>
			</header>
			<section class="row">
				<div class="graph col-xs-12" id="graph"></div>
				<div class="graph col-xs-12" id="graph1"></div>
				<div class="graph col-xs-12" id="graph2"></div>
				<div class="graph col-xs-12" id="graph3"></div>
				<div class="graph col-xs-12" id="graph4"></div>
			</section>
			<footer>
				<div class="row">
					<div class="col-xs-2"><img src="../images/Tomtomfx_bot.png" alt="Powered by Tomtomfx"></div>
				</div>
			</footer>
		</div>
	</body>
</html>