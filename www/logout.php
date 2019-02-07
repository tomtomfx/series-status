<?php
	include 'userManagement.php';
	if ($users->isloggedin())
	{
		$users->logout();
	}	
	header('Location: ./#', true, 302);
	die();
?>
