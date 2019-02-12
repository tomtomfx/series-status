<?php
	include '../userManagement.php';
	if (!$users->isloggedin())
	{
		header('Location: ../#', true, 302);
		die();
	}
	$image = "";
	include 'tabletManagement.php';
	
	// Add tablet from informations
	if (isset($_POST['tabletId']) AND isset($_POST['action']))
	{
		if ($_POST['action'] == "add"){
			$tabletManager->addTablet($_POST['tabletId'], $_POST['tabletIp'], $_POST['ftpUser'], $_POST['ftpPassword']);
		}
		elseif ($_POST['action'] == "remove"){
			$tabletManager->removeTablet($_POST['tabletId']);
		}
		elseif ($_POST['action'] == "copy"){
			$tabletManager->copyRequested($_POST['episode'], $_POST['tabletId'], "true");
		}
	}

	if (isset($_GET['id']) AND isset($_GET['action']))
	{
		if ($_GET['action'] == "cancel"){
			$tabletManager->copyRequested(urldecode($_GET['id']), "", "false");
			header('Location: http://' . $_SERVER['HTTP_HOST'] . $_SERVER['PHP_SELF']);
		}
	}
?>

<!DOCTYPE html>
<html>
    <head>
        <meta charset="utf-8" />
		<meta http-equiv="cache-control" content="no-cache">
		<meta http-equiv="X-UA-Compatible" content="IE=edge">
		<meta name="viewport" content="width=device-width, initial-scale=1">
		<link href="../bootstrap-3.3.6-dist/css/bootstrap.min.css" rel="stylesheet">
		<script type="text/javascript" src="../bootstrap-3.3.6-dist/js/jquery.min.js"></script>
		<script type="text/javascript" src="../bootstrap-3.3.6-dist/js/bootstrap.min.js"></script>
<?php	
		if (isset($_GET['id']) AND isset($_GET['action']))
		{
			if ($_GET['action'] == "copy")
			{
				echo'
					<script type="text/javascript">
						$(window).load(function(){
							$("#copyTablet").modal("show");
						});
					</script>
				';
			}
		}
?>
		<link href="../style_bootstrap.css" rel="stylesheet">
		<link rel="shortcut icon" href="favicon.ico">
		<title>Tablet management</title>
<?php
$image = getRandomBackground("../images/backgrounds");
$img = imagecreatefromjpeg("../images/backgrounds/".urldecode($image));
$size = getimagesize("../images/backgrounds/".urldecode($image));
$rgb = imagecolorat($img, 50, $size[1]-1);
$r = ($rgb >> 16) & 0xFF;
$g = ($rgb >> 8) & 0xFF;
$b = $rgb & 0xFF;

echo'
		<style>
			body {background-image: url("../images/backgrounds/'.$image.'");background-repeat:no-repeat;background-size:contain;background-color:rgb('.$r.', '.$g.', '.$b.');}
		</style>
';
?>
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
					<a class="navbar-brand" href="../#">Tomtomfx</a>
				</div>
				<div class="collapse navbar-collapse" id="menuCollapse">
					<ul class="nav navbar-nav">
						<li class="active dropdown-toggle" data-toggle="dropdown" id="navLogin">
							<a href="./series.php#" id="navig"><span class="glyphicon glyphicon-film"></span> Series<span class="caret"></span></a>
						</li>
						<ul class="dropdown-menu">
							<li><a href="./series.php" data-toggle="modal"><span class="glyphicon glyphicon-film"></span> Series</a></li>
							<li><a href="./tablet.php"><span class="glyphicon glyphicon-phone"></span> Tablet</a></li>
							<li><a href="./statistics.php"><span class="glyphicon glyphicon-stats"></span> Statistics</a></li>
						</ul>
						<li><a href="../photos/photos.php" id="navig"><span class="glyphicon glyphicon-camera"></span> Photos</a></li>
						<li><a href="../home/home.php" id="navig"><span class="glyphicon glyphicon-home"></span> Home</a></li>
					</ul>
					<div class="nav navbar-nav navbar-right">
						<li class="dropdown-toggle" data-toggle="dropdown" id="navLogin">
							<a href="#" id="navig"><span class="glyphicon glyphicon-user"></span> <?php echo $_SESSION['username']?><span class="caret"></span></a>
						</li>
						<ul class="dropdown-menu">
							<li><a href="#addTablet" data-toggle="modal"><span class="glyphicon glyphicon-plus"></span> Add a tablet</a></li>
							<li><a href="#removeTablet" data-toggle="modal"><span class="glyphicon glyphicon-minus"></span> Remove a tablet</a></li>
							<li><a href="../logout.php"><span class="glyphicon glyphicon-log-out"></span> Log out</a></li>
						</ul>
					</div>
				</div>
			</nav>

			<!-- Header -->
			<header class="page-header" id="title">
					<section class="row">
						<div class="col-xs-12"><h1>Tablet management</h1></div>
					</section>
			</header>
			
			<!-- Series / Episodes -->
			<section class="row" id="episodes">
				<div class="col-xs-8">
					<div class="col-xs-offset-1 col-xs-11">
						<div class="panel-group">
<?php
	printEpisodes("On tablet", $tabletManager);
	printEpisodes("Copy requested", $tabletManager);
	printEpisodes("Available", $tabletManager);
?>
						</div>
					</div>
				</div>
				<div class="col-xs-4">
					<div class="col-xs-12">
						<div class="panel-group">
<?php
	printTablets($tabletManager);
?>
						</div>
					</div>
				</div>
			</section>

			<!-- Modal Add tablet-->
			<div class="modal fade" id="addTablet" tabindex="-1" role="dialog" aria-labelledby="addTabletLabel">
				<div class="modal-dialog" role="document">
					<div class="modal-content">
						<div class="modal-header">
							<button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
							<h3 class="modal-title" id="addSerieLabel">Add a tablet</h3>
						</div>
						<form class="form-horizontal" method="POST" action="./tablet.php#">
							<div class="modal-body">
<?php
	formText("Tablet id:", "tabletId", "success", "", "true");
	formText("Tablet IP address:", "tabletIp", "success", "", "true");
	formText("FTP user:", "ftpUser", "success", "", "true");
	formPassword("FTP password", "ftpPassword", "success", "");
?>
								<input type="hidden" name="action" value="add"/>
							</div>
							<div class="modal-footer">
								<button type="submit" class="pull-right btn btn-default">Add</button>
								<button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
							</div>
						</form>
					</div>
				</div>
			</div>

			<!-- Modal remove tablet-->
			<div class="modal fade" id="removeTablet" tabindex="-1" role="dialog" aria-labelledby="removeTabletLabel">
				<div class="modal-dialog" role="document">
					<div class="modal-content">
						<div class="modal-header">
							<button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
							<h3 class="modal-title" id="removeTabletLabel">Remove a tablet</h3>
						</div>
						<form class="form-horizontal" method="POST" action="./tablet.php#">
							<div class="modal-body">
<?php
	formCombo("Tablet", $tabletManager);
?>
								<input type="hidden" name="action" value="remove"/>
							</div>
							<div class="modal-footer">
								<button type="submit" class="pull-right btn btn-default">Remove</button>
								<button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
							</div>
						</form>
					</div>
				</div>
			</div>
			
			<!-- Modal copy requested-->
			<div class="modal fade" id="copyTablet" tabindex="-1" role="dialog" aria-labelledby="copyTabletLabel">
				<div class="modal-dialog" role="document">
					<div class="modal-content">
						<div class="modal-header">
							<button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
							<h3 class="modal-title" id="copyTabletLabel">Copy episode to tablet</h3>
						</div>
						<form class="form-horizontal" method="POST" action="./tablet.php#">
							<div class="modal-body">
<?php
	formText("Episode", "episode", "success", urldecode($_GET['id']), "false");
	formCombo("Tablet:", $tabletManager);
?>
								<input type="hidden" name="action" value="copy"/>
							</div>
							<div class="modal-footer">
								<button type="submit" class="pull-right btn btn-default">Copy</button>
								<button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
							</div>
						</form>
					</div>
				</div>
			</div>
			
			<!-- Footer -->
			<footer>
				<div class="row">
					<img class="col-xs-2" src="../images/Tomtomfx_bot.png" alt="Powered by Tomtomfx">
				</div>
			</footer>
		</div>	
    </body>
<?php
	$tabletManager->dbclose();
?>
</html>