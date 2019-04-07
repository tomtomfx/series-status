<?php
	include '../userManagement.php';
	if (!$users->isloggedin())
	{
		header('Location: ../#', true, 302);
		die();
	}
	include './homeManagement.php';
?>
<!DOCTYPE html>
<html lang="en" xmlns="http://www.w3.org/1999/xhtml">
	<head>
		<meta charset="utf-8" />
		<meta http-equiv="cache-control" content="no-cache">
		<meta name="viewport" content="width=device-width, initial-scale=1">
		<link href="../bootstrap-3.3.6-dist/css/bootstrap.min.css" rel="stylesheet">
		<link href="../style_bootstrap.css" rel="stylesheet">
		<title>Home</title>
		<link rel="shortcut icon" href="favicon.ico">		
		<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.9.1/jquery.min.js"></script>		
		<script src="../bootstrap-3.3.6-dist/js/bootstrap.min.js"></script>
	</head>

	<body>
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
					<a class="navbar-brand" href="../#">Home</a>
				</div>
				<div class="collapse navbar-collapse" id="menuCollapse">
					<ul class="nav navbar-nav">
<?php
if ($homeManager->getOptionFromConfig('shows') == 'true'){
	echo '						<li><a href="../series/series.php" id="navig"><span class="glyphicon glyphicon-film"></span> Shows</a></li>';
}?>
<?php
if ($homeManager->getOptionFromConfig('photos') == 'true'){
	echo '						<li><a href="../photos/photos.php" id="navig"><span class="glyphicon glyphicon-camera"></span> Photos</a></li>';
}?>
						<li class="active"><a href="./home.php" id="navig"><span class="glyphicon glyphicon-home"></span> Home</a></li>
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
						<div class="col-xs-12"><h2>Home</h2></div>
					</section>
			</header>
			<section class="row">
				<div class="col-xs-12 col-sm-6" id="home_box">
					<h2 id="home_title">Inside</h2>				
					<div class="col-xs-6" id="home_box">
						<div class="col-xs-12" id="home_databox">
							<div class="row" id="home_boxtitle">
								<div class="col-xs-12">Temperatures</div>
							</div>
							<div class="row" id="home_data">
								<div class="col-xs-4" id="home_data_big">22,6°</div>
								<div class="col-xs-5" id="home_data">
									<div class="row"><div class="col-xs-12" id="home_data_small">Max 25°</div></div>
									<div class="row"><div class="col-xs-12" id="home_data_small">Min 15°</div></div>
								</div>
								<div class="col-xs-3" id="home_data"><span class="glyphicon glyphicon-arrow-right" id="home_data_big"></span></div>
							</div>
						</div>
					</div>
					<div class="col-xs-6" id="home_box">
						<div class="col-xs-12" id="home_databox">
							<div class="row" id="home_boxtitle">
								<div class="col-xs-4">Humidity</div>
								<div class="col-xs-4" id="home_boxtitle_with_border">Noise</div>
								<div class="col-xs-4">CO2</div>
							</div>
							<div class="row" id="home_data">
								<div class="col-xs-4" id="home_data_big">75%</div>
								<div class="col-xs-4" id="home_data_big_with_border">35<small> dB</small></div>
								<div class="col-xs-4" id="home_data_big">567<small> ppm</small></div>
							</div>
						</div>
					</div>
				</div>
				<div class="col-xs-12 col-sm-6" id="home_box">
					<h2 id="home_title">Outside</h2>				
					<div class="col-xs-6" id="home_box">
						<div class="col-xs-12" id="home_databox">
							<div class="row" id="home_boxtitle">
								<div class="col-xs-12">Temperatures</div>
							</div>
							<div class="row" id="home_data">
								<div class="col-xs-4" id="home_data_big">18,6°</div>
								<div class="col-xs-5" id="home_data">
									<div class="row"><div class="col-xs-12" id="home_data_small">Max 20°</div></div>
									<div class="row"><div class="col-xs-12" id="home_data_small">Min 12°</div></div>
								</div>
								<div class="col-xs-3" id="home_data"><span class="glyphicon glyphicon-arrow-down" id="home_data_big"></span></div>
							</div>
						</div>
					</div>
					<div class="col-xs-6" id="home_box">
						<div class="col-xs-12" id="home_databox">
							<div class="row" id="home_boxtitle">
								<div class="col-xs-4">Humidity</div>
								<div class="col-xs-4" id="home_boxtitle_with_border">Rain</div>
								<div class="col-xs-4">Day rain</div>
							</div>
							<div class="row" id="home_data">
								<div class="col-xs-4" id="home_data_big">75%</div>
								<div class="col-xs-4" id="home_data_big_with_border">0.3<small> mm/h</small></div>
								<div class="col-xs-4" id="home_data_big">5.6<small> mm</small></div>
							</div>
						</div>
					</div>
				</div>
			</section>
			<section class="row" id="home_data_section">
				<div class="col-xs-3" id="home_box">
					<h2 id="home_title">Station & modules</h2>
					<div class="col-xs-12" id="home_databox">
						<div class="row" id="home_boxtitle">
							<div class="col-xs-12">Station</div>
						</div>
					</div>
				</div>
				<div class="col-xs-9" id="home_box">
					<h2 id="home_title">Meteo statistics</h2>
					<div class="col-xs-12" id="home_databox">
						<div class="row" id="home_boxtitle">
							<div class="col-xs-12">Temperatures</div>
						</div>
					</div>
				</div>
			</section>
			<footer>
				<div class="row">
					<div class="col-xs-2"><img src="../images/Tomtomfx_bot.png" alt="Powered by Tomtomfx"></div>
				</div>
			</footer>
		</div>
	</body>
</html>
