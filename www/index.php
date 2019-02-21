<?php
    include 'userManagement.php';
	
	// Uncomment to create table
	$users->createTables();
	// Uncomment to create default user
	//$users->newUser("Tom", true);
	
	$user = "";
	$pass = "";
	if (!$users->isloggedin())
	{
		if(isset($_POST['user']))
		{
			$user = $_POST['user'];
		}
		if(isset($_POST['pass'])){$pass = $_POST['pass'];}
		
		if ($user != "" AND $pass != "")
		{
			$users->login($user, $pass);
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
		<script src="//code.jquery.com/jquery.min.js"></script>
		<script src="bootstrap-3.3.6-dist/js/bootstrap.min.js"></script>
		<link href="bootstrap-3.3.6-dist/css/bootstrap.min.css" rel="stylesheet">
		<link href="style_bootstrap.css" rel="stylesheet">
<?php
	if ($users->isLoggedIn()){echo '<title>Welcome</title>';}
	else {echo '<title>Login</title>';}
?>
    </head>
 
    <body>
     	<div class="container">
<?php
	if ($users->isLoggedIn())
	{
		echo'
			<nav class="navbar navbar-default">
				<div class="navbar-header">
					<button type="button" class="navbar-toggle" 
						data-toggle="collapse" data-target="#menuCollapse">
						<span class="sr-only">Toggle navigation</span>
						<span class="icon-bar"></span>
						<span class="icon-bar"></span>
						<span class="icon-bar"></span>
					</button>
					<a class="navbar-brand" href="./#">Home</a>
				</div>
				<div class="collapse navbar-collapse" id="menuCollapse">
					<ul class="nav navbar-nav">
						<li><a href="./series/series.php" id="navig"><span class="glyphicon glyphicon-film"></span> Series</a></li>
						<li><a href="./photos/photos.php" id="navig"><span class="glyphicon glyphicon-camera"></span> Photos</a></li>
						<li><a href="./home/home.php" id="navig"><span class="glyphicon glyphicon-home"></span> Home</a></li>
					</ul>
					<div class="nav navbar-nav navbar-right">
						<li class="dropdown-toggle" data-toggle="dropdown" id="navLogin">
							<a href="#" id="navig"><span class="glyphicon glyphicon-user"></span> '.$_SESSION['username'].'<span class="caret"></span></a>
						</li>
						<ul class="dropdown-menu">
							<li><a href="logout.php"><span class="glyphicon glyphicon-log-out"></span> Log out</a></li>
						</ul>
					</div>
				</div>
			</nav>
			<header class="page-header" id="title">
					<section class="row">
						<div class="col-xs-12"><h2>Welcome</h2></div>
					</section>
			</header>';
	}
	else
	{
		echo'
			<nav class="navbar navbar-default">
				<div class="navbar-header">
					<button type="button" class="navbar-toggle" 
						data-toggle="collapse" data-target="#menuCollapse">
						<span class="sr-only">Toggle navigation</span>
						<span class="icon-bar"></span>
						<span class="icon-bar"></span>
						<span class="icon-bar"></span>
					</button>
					<a class="navbar-brand" href="./#">Home</a>
				</div>
				<div class="collapse navbar-collapse" id="menuCollapse">
					<ul class="nav navbar-nav">
						<li class="active"><a href="./#" id="navig">Login</a></li>
					</ul>
				</div>
			</nav>
			<header class="page-header" id="title">
					<section class="row">
						<div class="col-xs-12"><h2>Log in</h2></div>
					</section>
			</header>';
	}
	if (!$users->isLoggedIn())
	{
		echo '
			<section class="row">';
		if (!$users->isLoggedIn() AND $user != "" AND $pass != "")
		{
			echo'
				<div class="row">;
					<div class="col-xs-12 alert alert-danger">
						<strong>Wrong username or password</strong>
					</div>
				</div>';
		}
		echo'
				<form class="form-horizontal col-xs-12" method="POST" action="#">
					<div class="row">';
		if ($user == "" AND isset($_POST['user']))
		{
			echo "
						<div class=\"form-group has-error\">
							<label for=\"texte\" class=\"col-xs-offset-1 col-xs-2 control-label\" for=\"idError\">Username: </label>
							<div class=\"col-xs-7\">
								<input name=\"user\" type=\"text\" class=\"form-control\" id=\"idError\" value=\"".$user."\">
								<span class=\"help-block\">You must enter a username</span>
							</div>";
		}
		else
		{
			echo "
						<div class=\"form-group\">
							<label for=\"texte\" class=\"col-xs-offset-1 col-xs-2 control-label\" style=color:white>Username: </label>
							<div class=\"col-xs-7\">
								<input name=\"user\" type=\"text\" class=\"form-control\" value=\"".$user."\">
							</div>";
		}
		echo '
						</div>
					</div>
					<div class="row">';
		if ($pass == "" AND isset($_POST['pass']))
		{
			echo'
						<div class="form-group has-error">
							<label for="texte" class="col-xs-offset-1 col-xs-2 control-label" for="idError">Password: </label>
							<div class="col-xs-7">
								<input name="pass" type="password" class="form-control" id="idError">
								<span class="help-block">You must enter a password</span>
							</div>';
		}
		else
		{
			echo'
						<div class="form-group">
							<label for="texte" class="col-xs-offset-1 col-xs-2 control-label" style=color:white>Password: </label>
							<div class="col-xs-7">
								<input name="pass" type="password" class="form-control">
							</div>';
		}
		echo'				</div>
					</div>
					<div class="form-group">
						<button class="pull-right btn btn-default" type="submit" value="Login">Log in</button>
					</div>
				</form>
			</section>';
	}
	else
	{
		echo '
			<section class="row">
				<!-- Applications -->
				<!-- Series -->
				<div class="col-sm-4 col-xs-6">
					<a href="./series/series.php"><img src="./images/seriesTV_512.png" class="img img-thumbnail img-responsive" id="presImg"/></a>
				</div> 
				<!-- Photos -->
				<div class="col-sm-4 col-xs-6"> 
					<a href="./photos/photos.php"><img src="./images/photo3_512.png" class="img img-thumbnail img-responsive" id="presImg"/></a>
				</div>
				<div class="col-sm-4 col-xs-6"> 
					<a href="./home/home.php"><img src="./images/home_512.png" class="img img-thumbnail img-responsive" id="presImg"/></a>
				</div>
			</section>';
	}
?>
			<footer>
				<div class="row">
					<img class="col-xs-2 img-responsive" src="images/Tomtomfx_bot.png" alt="Powered by Tomtomfx">
				</div>
			</footer>
		</div>
    </body>
</html>