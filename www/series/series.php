	<?php
	include '../userManagement.php';
	if (!$users->isloggedin())
	{
		header('Location: ../#', true, 302);
		die();
	}
	
	include 'seriesManagement.php';

	$seriesManager = new seriesManagement();
	$seriesManager->configInit("../secure/configWeb");
	$seriesManager->dbinit("./series.db");

	$status = "";
	$searchShow = "";
	$showsFound = null;
	$showsList = null;
	$type = "";
	$image = "";
	if (isset($_GET['status']))
	{
		$status = $_GET['status'];
	}
	if (isset($_GET['type']))
	{
		$type = $_GET['type'];
	}
	if (isset($_POST['serieName']))
	{
		$searchShow = $_POST['serieName'];
		$showsFound = getShowList ($searchShow, $seriesManager);
	}
	if (isset($_FILES['subFile']))
	{
		storeSubFile($seriesManager, $_FILES['subFile']);
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
		<script type="text/javascript" src="./js/series.js"></script>
<?php
		if (isset($_GET['status']))
		{
		echo'
		<script type="text/javascript">
			$(window).load(function(){
				$("#serieStatus").modal("show");
			});
		</script>';
		}
		if (isset($_POST['serieName']))
		{
		echo'
		<script type="text/javascript">
			$(window).load(function(){
				$("#searchShow").modal("show");
			});
		</script>';
		}
?>
		<link href="../style_bootstrap.css" rel="stylesheet">
		<link rel="shortcut icon" href="favicon.ico">
		<title>Shows status</title>
<?php
$image = getRandomBackground("../images/backgrounds");
$img = imagecreatefromjpeg("../images/backgrounds/".urldecode($image));
$size = getimagesize("../images/backgrounds/".urldecode($image));
$rgb = imagecolorat($img, 0, $size[1]-1);
$r = ($rgb >> 16) & 0xFF;
$g = ($rgb >> 8) & 0xFF;
$b = $rgb & 0xFF;

echo'
		<style>
			body {background-image: url("../images/backgrounds/'.$image.'");background-repeat:no-repeat;background-size:cover;background-color:rgb('.$r.', '.$g.', '.$b.');}
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
					<a class="navbar-brand" href="../#">Home</a>
				</div>
				<div class="collapse navbar-collapse" id="menuCollapse">
					<ul class="nav navbar-nav">
						<li class="active dropdown-toggle" data-toggle="dropdown" id="navLogin">
							<a href="./series.php#" id="navig"><span class="glyphicon glyphicon-film"></span> Shows<span class="caret"></span></a>
						</li>
						<ul class="dropdown-menu">
							<li><a href="./series.php" data-toggle="modal"><span class="glyphicon glyphicon-film"></span> Shows</a></li>
<?php
if ($seriesManager->getOptionFromConfig('tablet') == 'true'){
	echo 				   '<li><a href="./tablet.php"><span class="glyphicon glyphicon-phone"></span> Tablet</a></li>';
}
?>
						</ul>
<?php
if ($seriesManager->getOptionFromConfig('photos') == 'true'){
	echo					'<li><a href="../photos/photos.php" id="navig"><span class="glyphicon glyphicon-camera"></span> Photos</a></li>';
}
?>
<?php
if ($seriesManager->getOptionFromConfig('home') == 'true'){
	echo					'<li><a href="../home/home.php" id="navig"><span class="glyphicon glyphicon-home"></span> Home</a></li>';
}
?>
					</ul>
					<div class="nav navbar-nav navbar-right">
						<li class="dropdown-toggle" data-toggle="dropdown" id="navLogin">
							<a href="#" id="navig"><span class="glyphicon glyphicon-user"></span> <?php echo $_SESSION['username']?><span class="caret"></span></a>
						</li>
						<ul class="dropdown-menu">
							<li><a href="#addSerie" data-toggle="modal"><span class="glyphicon glyphicon-plus"></span> Add a show</a></li>
							<li><a href="#" onclick="createArchiveShowList();return false;" data-toggle="modal"><span class="glyphicon glyphicon-minus"></span> Archive a show</a></li>
							<li><a href="#uploadSubtitlesFile" data-toggle="modal"><span class="glyphicon glyphicon-upload"></span> Upload subtitles</a></li>
							<li><a href="../logout.php"><span class="glyphicon glyphicon-log-out"></span> Log out</a></li>
						</ul>
					</div>
				</div>
			</nav>

			<!-- Header -->
			<header class="page-header" id="title">
					
			</header>
			
			<!-- Series / Episodes -->
			<section class="row" id="episodes">
				<div class="col-xs-12">
					<div class="panel-group">
<?php
	echo(printEpisodesToWatch($seriesManager));
?>
					</div>
				</div>
			</section>

			<!-- Modal Add serie-->
			<div class="modal fade" id="addSerie" tabindex="-1" role="dialog" aria-labelledby="addSerieLabel">
				<div class="modal-dialog" role="document">
					<div class="modal-content">
						<div class="modal-header">
							<button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
							<h3 class="modal-title" id="addSerieLabel">Add a show</h3>
						</div>
						<form class="form-horizontal" action="#" onsubmit="getShowList();return false;">
							<div class="modal-body">
								<div class="form-group">
									<label for="serie_name" class="col-xs-3 control-label">Show name:</label>
									<div class="col-xs-9">
										<input name="serieName" type="text" class="form-control" id="serie_name">
									</div>
								</div>
							</div>
							<div class="modal-footer">
								<button type="submit" class="pull-right btn btn-default">Search</button>
								<button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
							</div>
						</form>
					</div>
				</div>
			</div>

			<!-- Modal add 2nd step -->
			<div class="modal fade" id="searchShow" tabindex="-1" role="dialog" aria-labelledby="searchShowLabel">
				<div class="modal-dialog" role="document">
					<div class="modal-content">
						<div class="modal-header">
							<button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
							<h3 class="modal-title" id="addSerieLabel">Choose a show to add</h3>
						</div>
						<form class="form-horizontal" method="POST" action="../cgi-bin/add.cgi">
							<div class="modal-body">
<?php
	echo(formComboToAdd("Show:", $showsFound));
?>
							</div>
							<div class="modal-footer">
								<button type="submit" class="pull-right btn btn-default">Add</button>
								<button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
							</div>
						</form>
					</div>
				</div>
			</div>

			<!-- Modal Archive serie-->
			<div class="modal fade" id="archiveSerie" tabindex="-1" role="dialog" aria-labelledby="archiveSerieLabel">
				<div class="modal-dialog" role="document">
					<div class="modal-content">
						<div class="modal-header">
							<button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
							<h3 class="modal-title" id="addSerieLabel">Archive a show</h3>
						</div>
						<form class="form-horizontal" method="POST" action="../cgi-bin/archive.cgi">
							<div class="modal-body">
<?php
	echo(formComboToArchive("Show:", $showsList));
?>
							</div>
							<div class="modal-footer">
								<button type="submit" class="pull-right btn btn-default">Archive</button>
								<button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
							</div>
						</form>
					</div>
				</div>
			</div>

			<!-- Modal upload subtitles file -->
			<div class="modal fade" id="uploadSubtitlesFile" tabindex="-1" role="dialog" aria-labelledby="uploadSubtitlesFileLabel">
				<div class="modal-dialog" role="document">
					<div class="modal-content">
						<div class="modal-header">
							<button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
							<h3 class="modal-title" >Upload subtitles file</h3>
						</div>
						<form class="form-horizontal" method="POST" action="#" enctype="multipart/form-data">
							<div class="modal-body">
								<h4>Episodes with missing subtitles:</h4>
								<ul id="fileList">
<?php
	$files = getFilesMissingSubtitles($seriesManager);
	foreach ($files as $file) 
	{
		echo '<li>'.$file.'</li>';
	}
?>  							
								</ul>
								<div class="form-group">
									<input type="file" name="subFile" class="form-control" id="customFileSub">
  								</div>
								<!-- <input name="Subtitles file" type="file" class="form-control" name="subFile"> -->
							</div>
							<div class="modal-footer">
								<button type="submit" class="pull-right btn btn-default">Upload</button>
								<button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
							</div>
						</form>
					</div>
				</div>
			</div>

			<!-- Modal status -->
			<div class="modal fade" id="serieStatus" tabindex="-1" role="dialog" aria-labelledby="serieStatusLabel">
				<div class="modal-dialog" role="document">
					<div class="modal-content">
						<div class="modal-header">
							<button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
<?php							
					if ($type == "add")
					{
						echo '<h3 class="modal-title" id="addSerieLabel">Add a show</h3>';
					}else{
						echo '<h3 class="modal-title" id="addSerieLabel">Archive a show</h3>';
					}
?>
						</div>
						<div class="modal-body row">
<?php							
					if ($type == "add")
					{
						if ($status == "success")
						{
							echo '<img src="../images/success-icon.png" class="img-responsive col-xs-2" alt="Show added with success" id="serieStatusImg">';
							echo '<div class="col-xs-9"><h3>Show added with success</h3></div>';
						}
						else if ($status == "failed")
						{
							echo '<img src="../images/failed-icon.png" class="img-responsive col-xs-2" alt="Add show failed" id="serieStatusImg">';
							echo '<div class="col-xs-9"><h3>Failed to add show</h3></div>';
						}		
					}
					else
					{
						if ($status == "success")
						{
							echo '<img src="../images/success-icon.png" class="img-responsive col-xs-2" alt="Show archived with success" id="serieStatusImg">';
							echo '<div class="col-xs-9"><h3>Show archived with success</h3></div>';
						}
						else if ($status == "failed")
						{
							echo '<img src="../images/failed-icon.png" class="img-responsive col-xs-2" alt="Archive show failed" id="serieStatusImg">';
							echo '<div class="col-xs-9"><h3>Failed to archive show</h3></div>';
						}
					}
?>
						</div>
						<div class="modal-footer">
							<button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
						</div>
					</div>
				</div>
			</div>
			
			<!-- Footer -->
			<footer>
				<div class="row">
					<!-- <img class="col-xs-2" src="../images/Tomtomfx_bot.png" alt="Powered by Tomtomfx"> -->
				</div>
			</footer>
		</div>	
    </body>
<?php
	$seriesManager->dbclose();
?>
</html>
