<?php
	include '../userManagement.php';
	if (!$users->isloggedin())
	{
		header('Location: ../#', true, 302);
		die();
	}
	include 'photosManagement.php';
	
	$album = "";
	if(isset($_GET['album']))
	{
		$album = $_GET['album'];
	}
	// var_dump($album);
?>
<!DOCTYPE html>
<html lang="en" xmlns="http://www.w3.org/1999/xhtml">
	<head>
		<meta charset="utf-8" />
		<meta http-equiv="cache-control" content="no-cache">
		<meta name="viewport" content="width=device-width, initial-scale=1">
		<link href="../bootstrap-3.3.6-dist/css/bootstrap.min.css" rel="stylesheet">
		<link href="../style_bootstrap.css" rel="stylesheet">
		<link href="../fancybox/jquery.fancybox.css" rel="stylesheet" type="text/css" media="screen" />
		<link rel="stylesheet" type="text/css" href="../fancybox/helpers/jquery.fancybox-thumbs.css?v=1.0.7" />
		<title>Photos</title>
		<link rel="shortcut icon" href="../favicon.ico">		
		<script type="text/javascript" src="../highchart/js/jquery.min.js"></script>		
		<!-- <script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.9.1/jquery.min.js"></script>	-->
		<script src="../bootstrap-3.3.6-dist/js/bootstrap.min.js"></script>
        <script type="text/javascript" src="../fancybox/jquery.fancybox.pack.js"></script>
		<!-- Add thumbnail helper (this is optional) -->
		<script type="text/javascript" src="../fancybox/helpers/jquery.fancybox-thumbs.js?v=1.0.7"></script>
		<script type="text/javascript" src="../smartcrop/smartcrop.js"></script>
		<script>
			$(document).ready(function() {
				$('.fancybox').fancybox({
					padding: 0,
					//Enable thumbnails helper and set custom options
					helpers:{
						thumbs : {
							width: 50,
							height: 50
						}
					}
				});
			});
		</script>
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
if ($photosManager->getOptionFromConfig('shows') == 'true'){
	echo '				<li><a href="../series/series.php" id="navig"><span class="glyphicon glyphicon-film"></span> Shows</a></li>';
}
?>
						<li class="active"><a href="../#" id="navig"><span class="glyphicon glyphicon-camera"></span> Photos</a></li>
<?php
if ($photosManager->getOptionFromConfig('home') == 'true'){
	echo '						<li><a href="../home/home.php" id="navig"><span class="glyphicon glyphicon-home"></span> Home</a></li>';
}
?>
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
						<?php
							if (!isset($_GET['album']) OR $album == "")
							{
								echo'<div class="col-xs-12"><h2>Photos</h2></div>';
							}
							else
							{
								echo'<div class="col-xs-12"><h2>'.$album.'</h2></div>';
							}
						?>
					</section>
			</header>
			<section>
				<div class="row">
					<?php
						if (!isset($_GET['album']) OR $album == "")
						{
							$albums = $photosManager->getAlbums();
							// var_dump($albums);
							foreach ($albums as $album)
							{
								echo' 
					<div class="col-md-2 col-sm-3 col-xs-4" id="miniature">
						<div class="thumbnail">
							<a href="?album='.$album['name'].'"><img id="img_gallery" class="img-responsive" src="'.$album['cover'].'"/>
								<div class="caption">
									<h5>'.$album['name'].'</h5>
									<h6>'.$album['date'].'</h6>
								</div>
							</a>
						</div>
					</div>';
							}
						}
						else
						{
							$photos = $photosManager->getPhotos($album);
							// var_dump($photos);
							foreach ($photos as $photo)
							{
								echo' 
					<div class="col-md-1 col-sm-2 col-xs-3" id="miniature">
						<a href="'.$photo.'" rel="gallery" class="fancybox"><img id="img_gallery" class="img-responsive" src="'.$photo.'"/></a>
					</div>
								';
							}
						}
					?>

					<script type="text/javascript" src="photos.js"></script>
				</div>
				<?php
					if (isset($_GET['album']) AND $album != "")
					{
						echo '<div class="row">';
						echo '<a href="photos.php" class="pull-right btn btn-default">Back</a>';
						echo '</div>';
					}
				?>
			</section>
			<footer>
				<div class="row">
					<div class="col-xs-2"><img src="../images/Tomtomfx_bot.png" alt="Powered by Tomtomfx"></div>
				</div>
			</footer>
		</div>
	</body>
</html>
