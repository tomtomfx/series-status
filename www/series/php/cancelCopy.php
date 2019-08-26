<?php

include '../seriesManagement.php';

$tabletManager = new tabletManagement();
$tabletManager->dbinit("../series.db");
$episode = $_POST['id'];
$tabletManager->copyRequested($episode, "", "false");

$tabletManager->dbclose();

?>